import os
import json
import http.client
import math
from fastapi import APIRouter, HTTPException, Query
from typing import Optional

router = APIRouter(tags=["google_maps"])

RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "")
if not RAPIDAPI_KEY:
    print("WARNING: RAPIDAPI_KEY not set. Google Maps endpoints will fail.")


def _rapidapi_request(method: str, path: str, payload: dict = None) -> dict:
    """Make a request to RapidAPI Google Maps"""
    conn = http.client.HTTPSConnection("google-map-places-new-v2.p.rapidapi.com")

    headers = {
        'x-rapidapi-key': RAPIDAPI_KEY,
        'x-rapidapi-host': "google-map-places-new-v2.p.rapidapi.com",
        'Content-Type': "application/json",
        'X-Goog-FieldMask': "*"
    }

    if payload:
        conn.request(method, path, json.dumps(payload), headers)
    else:
        conn.request(method, path, headers=headers)

    res = conn.getresponse()
    data = json.loads(res.read().decode("utf-8"))
    conn.close()

    return {"status": res.status, "data": data}


def _extract_thumbnail(data: dict) -> str:
    """Extract the first photo URI from place details data."""
    photos = data.get("photos", [])
    if photos and len(photos) > 0:
        first = photos[0]
        # Google Places v2 uses photo resource names like "places/PLACE_ID/photos/PHOTO_REF"
        name = first.get("name", "")
        if name:
            return f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference={name}&key={RAPIDAPI_KEY}"
        # Fallback if googleMapsUri is present in attribution
        attributions = first.get("authorAttributions", [])
        if attributions:
            uri = attributions[0].get("uri", "")
            if uri:
                return uri
    return ""


def _extract_cuisine_from_types(types: list) -> str:
    """Infer a cuisine/category label from Google place types."""
    type_map = {
        "italian_restaurant": "Italian",
        "japanese_restaurant": "Japanese",
        "sushi_restaurant": "Japanese",
        "chinese_restaurant": "Chinese",
        "indian_restaurant": "Indian",
        "mexican_restaurant": "Mexican",
        "american_restaurant": "American",
        "hamburger_restaurant": "American",
        "fast_food_restaurant": "Fast Food",
        "pizza_restaurant": "Pizza",
        "seafood_restaurant": "Seafood",
        "thai_restaurant": "Thai",
        "french_restaurant": "French",
        "mediterranean_restaurant": "Mediterranean",
        "greek_restaurant": "Greek",
        "korean_restaurant": "Korean",
        "vietnamese_restaurant": "Vietnamese",
        "middle_eastern_restaurant": "Middle Eastern",
        "lebanese_restaurant": "Lebanese",
        "turkish_restaurant": "Turkish",
        "brazilian_restaurant": "Brazilian",
        "cafe": "Cafe",
        "coffee_shop": "Cafe",
        "bakery": "Bakery",
        "bar": "Bar",
        "night_club": "Bar",
        "ice_cream_shop": "Dessert",
        "dessert_shop": "Dessert",
    }
    for t in types:
        lower = t.lower()
        if lower in type_map:
            return type_map[lower]
    return "Restaurant"


@router.get("/google/search")
async def search_places(
    q: str = Query(..., description="Search query"),
    lat: float = Query(default=25.2048),
    lng: float = Query(default=55.2708),
    radius: int = Query(default=10000, description="Radius in meters"),
):
    """Search for places using Google Maps via RapidAPI"""
    if not RAPIDAPI_KEY:
        raise HTTPException(status_code=500, detail="RAPIDAPI_KEY not configured")

    try:
        payload = {
            "input": q,
            "locationBias": {
                "circle": {
                    "center": {"latitude": lat, "longitude": lng},
                    "radius": radius
                }
            },
            "includedPrimaryTypes": ["restaurant", "food", "cafe", "bakery"],
            "languageCode": "en",
            "regionCode": "AE",
            "includeQueryPredictions": True,
        }

        result = _rapidapi_request("POST", "/v1/places:autocomplete", payload)

        if result["status"] != 200:
            raise HTTPException(status_code=result["status"], detail="API request failed")

        suggestions = result["data"].get("suggestions", [])

        places = []
        for s in suggestions:
            place = s.get("placePrediction", {})
            if place:
                types = place.get("types", [])
                places.append({
                    "place_id": place.get("placeId", ""),
                    "name": place.get("text", {}).get("text", ""),
                    "types": types,
                    "cuisine": _extract_cuisine_from_types(types),
                })

        return {"ok": True, "total": len(places), "places": places}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/google/place-details")
async def get_place_details(
    place_id: str = Query(..., description="Google Place ID"),
):
    """Get detailed information about a place"""
    if not RAPIDAPI_KEY:
        raise HTTPException(status_code=500, detail="RAPIDAPI_KEY not configured")

    try:
        result = _rapidapi_request("GET", f"/v1/places/{place_id}", None)

        if result["status"] != 200:
            raise HTTPException(status_code=result["status"], detail="API request failed")

        data = result["data"]

        location = data.get("location", {})
        rating = data.get("rating", 0)
        reviews = data.get("userRatingCount", 0)
        types = data.get("types", [])
        thumbnail = _extract_thumbnail(data)

        return {
            "ok": True,
            "place": {
                "place_id": data.get("id", ""),
                "name": data.get("displayName", {}).get("text", ""),
                "address": data.get("formattedAddress", ""),
                "phone": data.get("internationalPhoneNumber", ""),
                "website": data.get("websiteUri", ""),
                "rating": rating,
                "reviews": reviews,
                "lat": location.get("latitude", 0),
                "lng": location.get("longitude", 0),
                "types": types,
                "cuisine": _extract_cuisine_from_types(types),
                "price_level": data.get("priceLevel", ""),
                "opening_hours": data.get("currentOpeningHours", {}),
                "google_maps_uri": data.get("googleMapsUri", ""),
                "thumbnail": thumbnail,
                "photos": [
                    {"name": p.get("name", ""), "width": p.get("widthPx", 0), "height": p.get("heightPx", 0)}
                    for p in data.get("photos", [])[:5]
                ],
            }
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/google/nearby-restaurants")
async def get_nearby_restaurants(
    lat: float = Query(...),
    lng: float = Query(...),
    radius: int = Query(default=5000),
):
    """Get nearby restaurants using Google Maps"""
    if not RAPIDAPI_KEY:
        raise HTTPException(status_code=500, detail="RAPIDAPI_KEY not configured")

    try:
        payload = {
            "input": "restaurant",
            "locationBias": {
                "circle": {
                    "center": {"latitude": lat, "longitude": lng},
                    "radius": radius
                }
            },
            "includedPrimaryTypes": ["restaurant", "food", "cafe"],
            "languageCode": "en",
            "includeQueryPredictions": True,
        }

        result = _rapidapi_request("POST", "/v1/places:autocomplete", payload)

        if result["status"] != 200:
            raise HTTPException(status_code=result["status"], detail="API request failed")

        suggestions = result["data"].get("suggestions", [])

        restaurants = []
        for s in suggestions:
            place = s.get("placePrediction", {})
            if place:
                types = place.get("types", [])
                restaurants.append({
                    "place_id": place.get("placeId", ""),
                    "name": place.get("text", {}).get("text", ""),
                    "types": types,
                    "cuisine": _extract_cuisine_from_types(types),
                })

        return {"ok": True, "total": len(restaurants), "restaurants": restaurants}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
