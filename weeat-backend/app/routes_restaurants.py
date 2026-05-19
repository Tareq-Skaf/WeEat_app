from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from bson import ObjectId
from datetime import datetime
import math

from .db import restaurants_col, menus_col

router = APIRouter(prefix="/restaurants", tags=["restaurants"])


def serialize_restaurant(doc: dict) -> dict:
    return {
        "id": str(doc["_id"]),
        "name": doc.get("name"),
        "cuisine": doc.get("cuisine"),
        "address": doc.get("address"),
        "phone": doc.get("phone"),
        "lat": doc.get("lat"),
        "lng": doc.get("lng"),
        "imageUrl": doc.get("imageUrl", ""),
        "rating": doc.get("rating", 4.5),
        "opening_hours": doc.get("opening_hours", ""),
        "price_range": doc.get("price_range", ""),
        "types": doc.get("types", []),
        "createdAt": doc.get("createdAt"),
    }


@router.get("")
async def list_restaurants(limit: int = 20):
    cursor = restaurants_col.find({}).sort("createdAt", -1).limit(limit)
    docs = await cursor.to_list(length=limit)
    return [serialize_restaurant(d) for d in docs]


@router.get("/search")
async def search_restaurants(
    q: Optional[str] = Query(default=None),
    cuisine: Optional[str] = Query(default=None),
    limit: int = 20,
):
    query = {}
    if q:
        query["name"] = {"$regex": q, "$options": "i"}
    if cuisine:
        query["cuisine"] = {"$regex": cuisine, "$options": "i"}

    cursor = restaurants_col.find(query).limit(limit)
    docs = await cursor.to_list(length=limit)
    return [serialize_restaurant(d) for d in docs]


@router.get("/nearby")
async def get_nearby_restaurants(lat: float = Query(...), lng: float = Query(...), radius_km: float = 10, limit: int = 20):
    """Get restaurants near a location using Haversine formula (optimized with query filter)"""
    # Only fetch restaurants that have valid coordinates (much faster than loading all)
    cursor = restaurants_col.find({
        "lat": {"$ne": 0, "$exists": True},
        "lng": {"$ne": 0, "$exists": True},
    }).limit(500)
    candidates = await cursor.to_list(500)

    nearby = []
    for r in candidates:
        r_lat = r.get("lat", 0)
        r_lng = r.get("lng", 0)
        if r_lat == 0 or r_lng == 0:
            continue

        # Haversine formula
        R = 6371  # Earth radius in km
        dlat = math.radians(r_lat - lat)
        dlng = math.radians(r_lng - lng)
        a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat)) * math.cos(math.radians(r_lat)) * math.sin(dlng / 2) ** 2
        c = 2 * math.asin(math.sqrt(a))
        distance = R * c

        if distance <= radius_km:
            r["distance_km"] = round(distance, 1)
            nearby.append(r)

    nearby.sort(key=lambda x: x["distance_km"])

    results = []
    for r in nearby[:limit]:
        results.append({
            "id": str(r["_id"]),
            "name": r.get("name"),
            "cuisine": r.get("cuisine"),
            "address": r.get("address"),
            "phone": r.get("phone"),
            "lat": r.get("lat"),
            "lng": r.get("lng"),
            "imageUrl": r.get("imageUrl", ""),
            "rating": r.get("rating", 0),
            "opening_hours": r.get("opening_hours", ""),
            "price_range": r.get("price_range", ""),
            "types": r.get("types", []),
            "distance_km": r.get("distance_km"),
            "createdAt": r.get("createdAt"),
        })

    return results


@router.get("/{restaurant_id}")
async def get_restaurant(restaurant_id: str):
    if not ObjectId.is_valid(restaurant_id):
        raise HTTPException(status_code=400, detail="Invalid restaurant id")

    doc = await restaurants_col.find_one({"_id": ObjectId(restaurant_id)})
    if not doc:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    return serialize_restaurant(doc)


@router.get("/{restaurant_id}/menu")
async def get_restaurant_menu(restaurant_id: str):
    """Get menu items for a restaurant"""
    if not ObjectId.is_valid(restaurant_id):
        raise HTTPException(status_code=400, detail="Invalid restaurant id")
    
    restaurant = await restaurants_col.find_one({"_id": ObjectId(restaurant_id)})
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
    
    cursor = menus_col.find({"restaurant_id": restaurant_id}).sort("category", 1)
    docs = await cursor.to_list(100)
    
    # Group by category
    categories = {}
    for doc in docs:
        cat = doc.get("category", "Other")
        if cat not in categories:
            categories[cat] = []
        categories[cat].append({
            "id": str(doc["_id"]),
            "name": doc.get("name", ""),
            "description": doc.get("description", ""),
            "price": doc.get("price", 0),
            "category": cat,
            "image": doc.get("image", ""),
        })
    
    return {
        "restaurant_id": restaurant_id,
        "restaurant_name": restaurant.get("name", ""),
        "categories": categories,
        "total_items": len(docs),
    }


@router.post("")
async def create_restaurant(payload: dict):
    if not payload.get("name"):
        raise HTTPException(status_code=400, detail="name is required")

    payload["createdAt"] = datetime.utcnow().isoformat()
    result = await restaurants_col.insert_one(payload)
    doc = await restaurants_col.find_one({"_id": result.inserted_id})
    return serialize_restaurant(doc)


@router.post("/seed")
async def seed_restaurants():
    count = await restaurants_col.count_documents({})
    if count > 0:
        return {"ok": True, "seeded": 0}

    demo = [
        {
            "name": "Mama's Pizza",
            "cuisine": "Italian",
            "address": "Downtown Street 12",
            "phone": "+971500000001",
            "lat": 25.4052,
            "lng": 55.5136,
            "imageUrl": "",
            "rating": 4.6,
            "createdAt": datetime.utcnow().isoformat(),
        },
        {
            "name": "Sushi House",
            "cuisine": "Japanese",
            "address": "City Walk 3",
            "phone": "+971500000002",
            "lat": 25.2048,
            "lng": 55.2708,
            "imageUrl": "",
            "rating": 4.7,
            "createdAt": datetime.utcnow().isoformat(),
        },
        {
            "name": "Burger Lab",
            "cuisine": "American",
            "address": "Mall Road 9",
            "phone": "+971500000003",
            "lat": 25.276987,
            "lng": 55.296249,
            "imageUrl": "",
            "rating": 4.4,
            "createdAt": datetime.utcnow().isoformat(),
        },
    ]
    await restaurants_col.insert_many(demo)
    return {"ok": True, "seeded": len(demo)}


@router.post("/fix-images")
async def fix_restaurant_images():
    """Update restaurants with missing or broken images using SerpApi"""
    import http.client
    import urllib.parse
    import json
    import re
    import os
    SERPAPI_KEY = os.getenv("SERPAPI_KEY", "")
    if not SERPAPI_KEY:
        raise HTTPException(status_code=500, detail="SERPAPI_KEY not configured")

    # Find restaurants with empty OR Google Maps API URLs (which might not work)
    cursor = restaurants_col.find({
        "$or": [
            {"imageUrl": ""},
            {"imageUrl": {"$exists": False}},
            {"imageUrl": {"$regex": "maps.googleapis.com"}},
        ]
    })
    docs = await cursor.to_list(length=100)
    updated = 0

    def clean_name(name: str) -> str:
        """Clean restaurant name for better search results"""
        # Remove common suffixes and special characters
        name = re.sub(r'\s*\(.*?\)\s*', ' ', name)  # Remove parenthetical
        name = re.sub(r'\s*\|.*$', '', name)  # Remove pipe and after
        name = re.sub(r'\s*-\s*$', '', name)  # Remove trailing dash
        name = re.sub(r'\s+#\d+.*$', '', name)  # Remove store numbers
        name = re.sub(r'\s+near\s+.*$', '', name, flags=re.IGNORECASE)  # Remove "near X"
        name = re.sub(r'\s+inside\s+.*$', '', name, flags=re.IGNORECASE)  # Remove "inside X"
        name = re.sub(r'\s+restaurant$', '', name, flags=re.IGNORECASE)  # Remove trailing "restaurant"
        name = re.sub(r'\s+cafe$', '', name, flags=re.IGNORECASE)  # Remove trailing "cafe"
        # Remove location suffixes like "Dhiyafah", "dubai mall", etc.
        name = re.sub(r'\s+(dubai|abu dhabi|sharjah|ajman|umm al quwain|ras al khaimah|fujairah)\s*(mall|center|centre)?$', '', name, flags=re.IGNORECASE)
        return name.strip()

    def get_thumbnail_from_serpapi(name: str, lat: float = None, lng: float = None) -> str:
        """Search for a restaurant using SerpApi and get its thumbnail"""
        # Try multiple name variations
        cleaned = clean_name(name)
        names_to_try = [name, cleaned]
        # Also try first word only if name is long
        words = cleaned.split()
        if len(words) > 1:
            names_to_try.append(words[0])
        # Also try appending "Dubai" if not already present
        if cleaned and "dubai" not in cleaned.lower():
            names_to_try.append(f"{cleaned} Dubai")
        
        for search_name in names_to_try:
            if not search_name or len(search_name) < 2:
                continue
            try:
                params = {
                    "engine": "google_maps",
                    "q": search_name,
                    "api_key": SERPAPI_KEY,
                }
                if lat and lng:
                    params["ll"] = f"@{lat},{lng},14z"

                conn = http.client.HTTPSConnection("serpapi.com")
                query_string = urllib.parse.urlencode(params)
                conn.request("GET", f"/search?{query_string}")
                res = conn.getresponse()
                data = json.loads(res.read().decode("utf-8"))
                conn.close()

                results = data.get("local_results", [])
                for r in results:
                    thumbnail = r.get("thumbnail", "")
                    if thumbnail:
                        return thumbnail
            except Exception:
                continue
        return ""

    for doc in docs:
        name = doc.get("name", "")
        lat = doc.get("lat", 0)
        lng = doc.get("lng", 0)
        if not name:
            continue

        thumbnail = get_thumbnail_from_serpapi(name, lat if lat else None, lng if lng else None)
        if thumbnail:
            await restaurants_col.update_one({"_id": doc["_id"]}, {"$set": {"imageUrl": thumbnail}})
            updated += 1

    return {"ok": True, "checked": len(docs), "updated": updated}