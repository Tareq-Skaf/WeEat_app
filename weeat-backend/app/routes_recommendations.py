import os
import json
import asyncio
import http.client
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, HTTPException, Query
from bson import ObjectId
from typing import List, Optional

from .db import db, users_col, restaurants_col, posts_col
from .routes_foursquare import _foursquare_request, _parse_restaurant, foursquare_search_multi

router = APIRouter(tags=["recommendations"])

MIMO_API_KEY = os.getenv("MIMO_API_KEY", "")
MIMO_BASE_URL = "api.xiaomimimo.com"

taste_cache_col = db["taste_cache"]


async def _mimo_analyze_taste(restaurant_list: str) -> List[str]:
    """Call MiMo AI to analyze user's taste and return cuisine keywords"""
    if not MIMO_API_KEY:
        return ["restaurant", "cafe", "food"]

    try:
        conn = http.client.HTTPSConnection(MIMO_BASE_URL)
        payload = json.dumps({
            "model": "mimo-v2.5-pro",
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are a restaurant recommendation engine. "
                        "Analyze the user's food preferences and return ONLY a "
                        "JSON array of 3-5 cuisine keywords to search for. "
                        "Example response: [\"Italian\", \"Pizza\", \"Pasta\"] "
                        "Return only the JSON array, nothing else."
                    ),
                },
                {
                    "role": "user",
                    "content": f"The user has liked/wishlisted these restaurants: {restaurant_list} What cuisines should I recommend for them?",
                },
            ],
            "temperature": 0.5,
            "max_tokens": 200,
        })
        headers = {
            "Authorization": f"Bearer {MIMO_API_KEY}",
            "Content-Type": "application/json",
        }
        conn.request("POST", "/v1/chat/completions", body=payload, headers=headers)
        res = conn.getresponse()
        raw = res.read().decode("utf-8")
        data = json.loads(raw)
        conn.close()

        if res.status != 200:
            print(f"[MiMo] Taste analysis error {res.status}: {raw}")
            return ["restaurant", "cafe", "food"]

        content = str(data["choices"][0]["message"]["content"]).strip()
        # Extract JSON array from response
        start = content.find("[")
        end = content.rfind("]")
        if start != -1 and end != -1:
            keywords = json.loads(content[start:end + 1])
            if isinstance(keywords, list) and len(keywords) > 0:
                return [str(k).strip() for k in keywords]

        # Fallback if parsing fails
        return ["restaurant", "cafe", "food"]
    except Exception as e:
        print(f"[MiMo] Taste analysis failed: {e}")
        return ["restaurant", "cafe", "food"]


@router.get("/recommendations")
async def get_recommendations(
    email: str = Query(..., description="User email"),
    limit: int = Query(default=10, description="Number of results"),
):
    """Get AI-personalized restaurant recommendations for a user"""
    try:
        email = email.lower().strip()

        # Check cache first (24h)
        cached = await taste_cache_col.find_one({"email": email})
        if cached:
            cached_at = cached.get("cached_at")
            if cached_at and datetime.now(timezone.utc) - cached_at < timedelta(hours=24):
                keywords = cached.get("keywords", ["restaurant", "cafe", "food"])
                has_history = cached.get("has_history", False)
                return await _search_foursquare_for_keywords(keywords, limit, has_history)

        # Build taste profile from DB
        user = await users_col.find_one({"email": email})
        liked_ids = user.get("liked_restaurant_ids", []) if user else []
        wishlist_ids = user.get("wishlist_restaurant_ids", []) if user else []

        # Get liked restaurant names
        liked_names = []
        if liked_ids:
            obj_ids = []
            for rid in liked_ids:
                try:
                    obj_ids.append(ObjectId(rid))
                except Exception:
                    continue
            async for r in restaurants_col.find({"_id": {"$in": obj_ids}}):
                name = r.get("name", "")
                cuisine = r.get("cuisine", "")
                if name:
                    liked_names.append(f"{name} ({cuisine})" if cuisine else name)

        # Get wishlist restaurant names
        wishlist_names = []
        if wishlist_ids:
            obj_ids = []
            for rid in wishlist_ids:
                try:
                    obj_ids.append(ObjectId(rid))
                except Exception:
                    continue
            async for r in restaurants_col.find({"_id": {"$in": obj_ids}}):
                name = r.get("name", "")
                cuisine = r.get("cuisine", "")
                if name:
                    wishlist_names.append(f"{name} ({cuisine})" if cuisine else name)

        # Get restaurants from user's posts
        post_restaurants = []
        async for p in posts_col.find({"user_email": email}):
            rname = p.get("restaurant_name", "")
            if rname and rname not in post_restaurants:
                post_restaurants.append(rname)

        all_items = liked_names + wishlist_names + post_restaurants
        has_history = len(all_items) > 0

        if not has_history:
            # No history → use defaults + popular search
            keywords = ["restaurant", "cafe", "food"]
            await taste_cache_col.update_one(
                {"email": email},
                {"$set": {
                    "keywords": keywords,
                    "has_history": False,
                    "cached_at": datetime.now(timezone.utc),
                }},
                upsert=True,
            )
            return await _search_foursquare_for_keywords(keywords, limit, False)

        # Call MiMo to analyze taste
        restaurant_list = ", ".join(all_items[:20])
        keywords = await _mimo_analyze_taste(restaurant_list)

        # Cache result
        await taste_cache_col.update_one(
            {"email": email},
            {"$set": {
                "keywords": keywords,
                "has_history": True,
                "cached_at": datetime.now(timezone.utc),
            }},
            upsert=True,
        )

        return await _search_foursquare_for_keywords(keywords, limit, True)

    except Exception as e:
        print(f"[Recommendations] Error: {e}")
        # Fallback to generic popular restaurants
        return await _search_foursquare_for_keywords(["restaurant", "cafe", "food"], limit, False)


async def _search_foursquare_for_keywords(keywords: List[str], limit: int, has_history: bool):
    """Search Foursquare for each keyword and merge results"""
    per_keyword = max(1, limit // max(1, len(keywords)))

    all_results = {}
    for kw in keywords[:5]:
        try:
            results = await foursquare_search_multi(
                query=kw,
                limit=per_keyword + 5,
                locations=["United Arab Emirates", "Dubai UAE", "Abu Dhabi UAE"],
            )
            for r in results:
                fsq_id = r.get("fsq_id", "")
                if fsq_id and fsq_id not in all_results:
                    all_results[fsq_id] = r
        except Exception:
            continue

    restaurants = list(all_results.values())
    # Mark taste-matched restaurants
    keywords_lower = [k.lower() for k in keywords]
    for r in restaurants:
        cat = r.get("category_name", "").lower()
        r["taste_matched"] = any(k in cat for k in keywords_lower)

    # Sort: taste-matched first, then by rating
    restaurants.sort(key=lambda x: (x.get("taste_matched", False), x.get("rating", 0) or 0), reverse=True)

    return {
        "ok": True,
        "has_history": has_history,
        "keywords": keywords,
        "restaurants": restaurants[:limit],
    }


@router.get("/recommendations/taste-keywords")
async def get_taste_keywords(email: str = Query(...)):
    """Return cached taste keywords for a user (used by frontend for tagging)"""
    email = email.lower().strip()
    cached = await taste_cache_col.find_one({"email": email})
    if cached:
        return {
            "ok": True,
            "keywords": cached.get("keywords", []),
            "has_history": cached.get("has_history", False),
        }
    return {"ok": True, "keywords": [], "has_history": False}
