import os
import json
import http.client
import asyncio
from urllib.parse import quote
from fastapi import APIRouter, HTTPException, Query
from typing import Optional

router = APIRouter(tags=["foursquare"])

FOURSQUARE_API_KEY = os.getenv("FOURSQUARE_API_KEY", "QNQFCKTX0QB1PN55Z3ITOV4RL0M3WQVYP2XW4RRUGFTXATFR")
FOURSQUARE_BASE_URL = "places-api.foursquare.com"


def _foursquare_request(method: str, path: str) -> dict:
    """Make a request to Foursquare Places API"""
    conn = http.client.HTTPSConnection(FOURSQUARE_BASE_URL)

    headers = {
        'Authorization': f'Bearer {FOURSQUARE_API_KEY}',
        'X-Places-Api-Version': '2025-06-17',
        'Accept': 'application/json',
    }

    conn.request(method, path, headers=headers)
    res = conn.getresponse()
    data = json.loads(res.read().decode("utf-8"))
    conn.close()

    if res.status != 200:
        raise HTTPException(status_code=res.status, detail=data.get("message", "Foursquare API error"))

    return data


def _map_budget_to_price_filter(max_budget: Optional[int]) -> Optional[str]:
    """Map AED max budget to Foursquare price filter string"""
    if max_budget is None:
        return None
    if max_budget <= 50:
        return "1"
    if max_budget <= 150:
        return "1,2"
    if max_budget <= 400:
        return "1,2,3"
    return None  # 400+ = no price filter


def _map_mood_to_category(mood: Optional[str]) -> Optional[str]:
    """Map mood/vibe to Foursquare category ID"""
    if mood is None or mood.strip() == "":
        return None
    mapping = {
        "Happy/Celebrating": "13065",
        "Casual": "13064",
        "Fast": "13145",
        "Healthy": "13049",
        "Coffee": "13032",
        "Fine Dining": "13065",
        "Romantic": "13065",
        "Cozy": "13032",
        "Trendy": "13065",
        "Family": None,
        "Italian": "13236",
        "Chinese": "13272",
        "Indian": "13199",
        "Thai": "13302",
        "Japanese": "13263",
        "Mexican": "13307",
        "American": "13383",
        "Mediterranean": "13314",
    }
    return mapping.get(mood)


def _parse_restaurant(r: dict) -> dict:
    """Parse a Foursquare restaurant result into our format"""
    location = r.get("location", {})
    categories = r.get("categories", [])
    social_media = r.get("social_media", {})

    icon_url = ""
    if categories:
        cat = categories[0]
        icon = cat.get("icon", {})
        prefix = icon.get("prefix", "")
        suffix = icon.get("suffix", "")
        if prefix and suffix:
            icon_url = f"{prefix}88{suffix}"

    return {
        "fsq_id": r.get("fsq_place_id", ""),
        "name": r.get("name", ""),
        "address": location.get("formatted_address", ""),
        "lat": r.get("latitude", 0),
        "lng": r.get("longitude", 0),
        "categories": [c.get("name", "") for c in categories],
        "category_name": categories[0].get("name", "") if categories else "",
        "icon_url": icon_url,
        "photo": icon_url,
        "tel": r.get("tel", ""),
        "website": r.get("website", ""),
        "rating": r.get("rating", 0),
        "social_media": {
            "instagram": social_media.get("instagram", ""),
            "twitter": social_media.get("twitter", ""),
        },
        "distance": r.get("distance", 0),
    }


@router.get("/foursquare/search")
async def search_restaurants(
    q: str = Query(..., description="Search query (restaurant name)"),
    near: str = Query(default="United Arab Emirates", description="Location"),
    limit: int = Query(default=50, description="Number of results per location"),
    max_budget: Optional[int] = Query(default=None, description="Max budget in AED"),
    mood: Optional[str] = Query(default=None, description="Mood/vibe filter"),
):
    """Search for restaurants across ALL UAE emirates using Foursquare Places API"""
    if not FOURSQUARE_API_KEY:
        raise HTTPException(status_code=500, detail="FOURSQUARE_API_KEY not configured")

    try:
        locations = [
            "United Arab Emirates",
            "Dubai UAE",
            "Abu Dhabi UAE",
            "Sharjah UAE",
            "Ajman UAE",
            "Ras Al Khaimah UAE",
            "Fujairah UAE",
            "Umm Al Quwain UAE",
        ]

        all_restaurants = {}  # Deduplicate by fsq_id
        price_filter = _map_budget_to_price_filter(max_budget)
        cat_filter = _map_mood_to_category(mood)

        async def search_one(location: str):
            try:
                price_param = f"&price={price_filter}" if price_filter else ""
                cat_param = f"&categories={cat_filter}" if cat_filter else ""
                params = f"?query={quote(q, safe='')}&near={quote(location, safe='')}&limit={limit}{price_param}{cat_param}"
                data = await asyncio.to_thread(_foursquare_request, "GET", f"/places/search{params}")
                return data.get("results", [])
            except Exception as e:
                print(f"[Foursquare] search failed for '{location}': {e}")
                return []

        # Run all searches in parallel
        tasks = [search_one(loc) for loc in locations]
        all_results = await asyncio.gather(*tasks)

        for results in all_results:
            for r in results:
                fsq_id = r.get("fsq_place_id", "")
                if fsq_id and fsq_id not in all_restaurants:
                    all_restaurants[fsq_id] = _parse_restaurant(r)

        restaurants = list(all_restaurants.values())

        return {"ok": True, "query": q, "total": len(restaurants), "restaurants": restaurants}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Helper that accepts price/category strings directly (for recommendations endpoint)
async def foursquare_search_multi(
    query: str,
    price: Optional[str] = None,
    category: Optional[str] = None,
    limit: int = 10,
    locations: list = None,
) -> list:
    """Search Foursquare across UAE emirates, return deduped restaurant list"""
    if locations is None:
        locations = ["United Arab Emirates", "Dubai UAE", "Abu Dhabi UAE"]

    all_restaurants = {}

    async def search_one(location: str):
        try:
            price_param = f"&price={price}" if price else ""
            cat_param = f"&categories={category}" if category else ""
            params = f"?query={quote(query, safe='')}&near={quote(location, safe='')}&limit={limit}{price_param}{cat_param}"
            data = await asyncio.to_thread(_foursquare_request, "GET", f"/places/search{params}")
            return data.get("results", [])
        except Exception:
            return []

    tasks = [search_one(loc) for loc in locations]
    all_results = await asyncio.gather(*tasks)

    for results in all_results:
        for r in results:
            fsq_id = r.get("fsq_place_id", "")
            if fsq_id and fsq_id not in all_restaurants:
                all_restaurants[fsq_id] = _parse_restaurant(r)

    return list(all_restaurants.values())


@router.get("/foursquare/photos")
async def get_restaurant_photos(
    fsq_id: str = Query(..., description="Foursquare Place ID"),
    limit: int = Query(default=5, description="Number of photos"),
):
    """Get photos for a restaurant from Foursquare"""
    if not FOURSQUARE_API_KEY:
        raise HTTPException(status_code=500, detail="FOURSQUARE_API_KEY not configured")

    try:
        data = _foursquare_request("GET", f"/places/{fsq_id}/photos?limit={limit}")

        photos = []
        for p in data:
            prefix = p.get("prefix", "")
            suffix = p.get("suffix", "")
            if prefix and suffix:
                photos.append({
                    "url": f"{prefix}300x200{suffix}",
                    "width": p.get("width", 0),
                    "height": p.get("height", 0),
                })

        return {"ok": True, "fsq_id": fsq_id, "photos": photos}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/foursquare/details")
async def get_restaurant_details(
    fsq_id: str = Query(..., description="Foursquare Place ID"),
):
    """Get detailed information about a restaurant from Foursquare"""
    if not FOURSQUARE_API_KEY:
        raise HTTPException(status_code=500, detail="FOURSQUARE_API_KEY not configured")

    try:
        data = _foursquare_request("GET", f"/places/{fsq_id}")

        location = data.get("location", {})
        categories = data.get("categories", [])
        social_media = data.get("social_media", {})

        icon_url = ""
        if categories:
            cat = categories[0]
            icon = cat.get("icon", {})
            prefix = icon.get("prefix", "")
            suffix = icon.get("suffix", "")
            if prefix and suffix:
                icon_url = f"{prefix}88{suffix}"

        return {
            "ok": True,
            "restaurant": {
                "fsq_id": data.get("fsq_place_id", ""),
                "name": data.get("name", ""),
                "address": location.get("formatted_address", ""),
                "lat": data.get("latitude", 0),
                "lng": data.get("longitude", 0),
                "categories": [c.get("name", "") for c in categories],
                "category_name": categories[0].get("name", "") if categories else "",
                "icon_url": icon_url,
                "tel": data.get("tel", ""),
                "website": data.get("website", ""),
                "social_media": {
                    "instagram": social_media.get("instagram", ""),
                    "twitter": social_media.get("twitter", ""),
                },
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
