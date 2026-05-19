import os
import json
import math
import urllib.request
import urllib.parse
from fastapi import APIRouter, HTTPException, Query
from typing import Optional

router = APIRouter(tags=["serpapi"])

SERPAPI_KEY = os.getenv("SERPAPI_KEY", "")


def _serpapi_search(params: dict) -> dict:
    """Synchronous SerpApi call"""
    url = "https://serpapi.com/search?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": "WeEat/1.0"})
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.loads(resp.read().decode())


@router.get("/serpapi/restaurants")
async def search_restaurants_serpapi(
    q: str = Query(..., description="Search query"),
    lat: Optional[float] = Query(default=None),
    lng: Optional[float] = Query(default=None),
):
    """Search for real restaurants using SerpApi (Google Maps)"""
    if not SERPAPI_KEY:
        raise HTTPException(status_code=500, detail="SerpApi key not configured")

    try:
        params = {
            "engine": "google_maps",
            "q": q,
            "api_key": SERPAPI_KEY,
        }

        if lat is not None and lng is not None:
            params["ll"] = f"@{lat},{lng},14z"

        data = await _async_serpapi(params)
        results = data.get("local_results", [])

        restaurants = []
        for r in results:
            gps = r.get("gps_coordinates", {})
            restaurants.append({
                "name": r.get("title", ""),
                "address": r.get("address", ""),
                "phone": r.get("phone", ""),
                "rating": r.get("rating", 0),
                "reviews": r.get("reviews", 0),
                "price_range": r.get("price", ""),
                "type": r.get("type", ""),
                "website": r.get("website", ""),
                "thumbnail": r.get("thumbnail", ""),
                "lat": gps.get("latitude", 0),
                "lng": gps.get("longitude", 0),
                "place_id": r.get("place_id", ""),
                "operating_hours": r.get("operating_hours", {}),
                "service_options": r.get("service_options", {}),
            })

        return {"ok": True, "query": q, "total": len(restaurants), "restaurants": restaurants}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/serpapi/restaurant-details")
async def get_restaurant_details(
    place_id: str = Query(..., description="Google Place ID"),
):
    """Get detailed restaurant info from SerpApi"""
    if not SERPAPI_KEY:
        raise HTTPException(status_code=500, detail="SerpApi key not configured")

    try:
        params = {
            "engine": "google_maps_reviews",
            "place_id": place_id,
            "api_key": SERPAPI_KEY,
        }

        data = await _async_serpapi(params)
        info = data.get("place_info", {})
        reviews = data.get("reviews", [])

        return {
            "ok": True,
            "place_id": place_id,
            "info": {
                "title": info.get("title", ""),
                "address": info.get("address", ""),
                "phone": info.get("phone", ""),
                "website": info.get("website", ""),
                "rating": info.get("rating", 0),
                "reviews": info.get("reviews", 0),
                "price": info.get("price", ""),
                "type": info.get("type", ""),
                "hours": info.get("hours", {}),
            },
            "reviews": [
                {
                    "user": r.get("user", ""),
                    "rating": r.get("rating", 0),
                    "snippet": r.get("snippet", ""),
                    "date": r.get("date", ""),
                    "likes": r.get("likes", 0),
                }
                for r in reviews[:10]
            ],
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/serpapi/nearby")
async def search_nearby_serpapi(
    lat: float = Query(...),
    lng: float = Query(...),
    q: str = Query(default="restaurants"),
):
    """Search for nearby restaurants using SerpApi"""
    if not SERPAPI_KEY:
        raise HTTPException(status_code=500, detail="SerpApi key not configured")

    try:
        params = {
            "engine": "google_maps",
            "q": q,
            "ll": f"@{lat},{lng},14z",
            "api_key": SERPAPI_KEY,
        }

        data = await _async_serpapi(params)
        results = data.get("local_results", [])

        restaurants = []
        for r in results:
            gps = r.get("gps_coordinates", {})
            r_lat = gps.get("latitude", 0)
            r_lng = gps.get("longitude", 0)

            R = 6371
            dlat = math.radians(r_lat - lat)
            dlng = math.radians(r_lng - lng)
            a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat)) * math.cos(math.radians(r_lat)) * math.sin(dlng / 2) ** 2
            c = 2 * math.asin(math.sqrt(a))
            distance = R * c

            restaurants.append({
                "name": r.get("title", ""),
                "address": r.get("address", ""),
                "phone": r.get("phone", ""),
                "rating": r.get("rating", 0),
                "reviews": r.get("reviews", 0),
                "price_range": r.get("price", ""),
                "type": r.get("type", ""),
                "thumbnail": r.get("thumbnail", ""),
                "lat": r_lat,
                "lng": r_lng,
                "place_id": r.get("place_id", ""),
                "distance_km": round(distance, 1),
                "operating_hours": r.get("operating_hours", {}),
                "service_options": r.get("service_options", {}),
            })

        restaurants.sort(key=lambda x: x["distance_km"])
        return {"ok": True, "total": len(restaurants), "restaurants": restaurants}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


async def _async_serpapi(params: dict) -> dict:
    """Run SerpApi call in thread pool"""
    import asyncio
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, _serpapi_search, params)