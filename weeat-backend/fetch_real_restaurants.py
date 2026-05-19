import asyncio
import http.client
import json
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime

import os
RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "")

def search_restaurants(query: str, lat: float = 25.2048, lng: float = 55.2708):
    """Search for restaurants using Google Maps autocomplete"""
    conn = http.client.HTTPSConnection("google-map-places-new-v2.p.rapidapi.com")
    
    payload = json.dumps({
        "input": query,
        "locationBias": {
            "circle": {
                "center": {"latitude": lat, "longitude": lng},
                "radius": 10000
            }
        },
        "includedPrimaryTypes": ["restaurant", "food", "cafe"],
        "languageCode": "en",
        "regionCode": "AE",
        "includeQueryPredictions": True,
    })
    
    headers = {
        'x-rapidapi-key': RAPIDAPI_KEY,
        'x-rapidapi-host': "google-map-places-new-v2.p.rapidapi.com",
        'Content-Type': "application/json",
        'X-Goog-FieldMask': "*"
    }
    
    conn.request("POST", "/v1/places:autocomplete", payload, headers)
    res = conn.getresponse()
    data = json.loads(res.read().decode("utf-8"))
    conn.close()
    
    return data.get("suggestions", [])


def get_place_details(place_id: str):
    """Get detailed info about a place"""
    conn = http.client.HTTPSConnection("google-map-places-new-v2.p.rapidapi.com")
    
    headers = {
        'x-rapidapi-key': RAPIDAPI_KEY,
        'x-rapidapi-host': "google-map-places-new-v2.p.rapidapi.com",
        'X-Goog-FieldMask': "*"
    }
    
    conn.request("GET", f"/v1/places/{place_id}", headers=headers)
    res = conn.getresponse()
    data = json.loads(res.read().decode("utf-8"))
    conn.close()
    
    return data


async def main():
    client = AsyncIOMotorClient('mongodb+srv://weeat_userr:123455@cluster01.rsszzqs.mongodb.net/?appName=Cluster01')
    db = client['weeat']
    
    # Clear existing
    await db.restaurants.delete_many({})
    print("Cleared existing restaurants")
    
    # Search queries
    queries = [
        "KFC restaurant Dubai",
        "McDonald's restaurant Dubai",
        "Burger King restaurant Dubai",
        "Subway restaurant Dubai",
        "Starbucks cafe Dubai",
        "Pizza Hut Dubai",
        "Domino's Pizza Dubai",
        "Nando's Dubai",
        "Papa John's Dubai",
        "Cheesecake Factory Dubai",
        "TGI Friday's Dubai",
        "Chili's Dubai",
        "Wagamama Dubai",
        "Sushi restaurant Dubai",
        "P.F. Chang's Dubai",
        "Baskin-Robbins Dubai",
        "Tim Hortons Dubai",
        "Al Mallah restaurant Dubai",
        "Zaroob restaurant Dubai",
        "Falafel restaurant Dubai",
    ]
    
    added = 0
    for query in queries:
        try:
            print(f"\nSearching: {query}")
            suggestions = search_restaurants(query)
            
            if not suggestions:
                print(f"  No results")
                continue
            
            # Find first suggestion with place_id
            place_id = None
            name = None
            
            for s in suggestions:
                pred = s.get("placePrediction", {})
                pid = pred.get("placeId", "")
                pname = pred.get("text", {}).get("text", "")
                if pid:
                    place_id = pid
                    name = pname
                    break
            
            if not place_id:
                print(f"  No place_id found")
                continue
            
            print(f"  Found: {name}")
            
            # Get details
            details = get_place_details(place_id)
            
            location = details.get("location", {})
            lat = location.get("latitude", 0)
            lng = location.get("longitude", 0)
            rating = details.get("rating", 0)
            reviews = details.get("userRatingCount", 0)
            address = details.get("formattedAddress", "")
            phone = details.get("internationalPhoneNumber", "")
            website = details.get("websiteUri", "")
            gmaps = details.get("googleMapsUri", "")
            types = details.get("types", [])
            
            # Price level
            price_level = details.get("priceLevel", "")
            price_map = {
                "PRICE_LEVEL_INEXPENSIVE": "$",
                "PRICE_LEVEL_MODERATE": "$$",
                "PRICE_LEVEL_EXPENSIVE": "$$$",
                "PRICE_LEVEL_VERY_EXPENSIVE": "$$$$",
            }
            price_range = price_map.get(price_level, "$$")
            
            # Opening hours
            hours = details.get("currentOpeningHours", {})
            opening_hours = ""
            if hours:
                descriptions = hours.get("descriptions", [])
                if descriptions:
                    opening_hours = descriptions[0]
            
            # Extract thumbnail from photos
            thumbnail = ""
            photos = details.get("photos", [])
            if photos and len(photos) > 0:
                photo_name = photos[0].get("name", "")
                if photo_name:
                    thumbnail = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference={photo_name}&key={RAPIDAPI_KEY}"

            # Store
            doc = {
                "name": name.split(" - ")[0].strip() if " - " in name else name,
                "cuisine": types[0].replace("_", " ").title() if types else "Restaurant",
                "address": address,
                "phone": phone,
                "lat": lat,
                "lng": lng,
                "imageUrl": thumbnail,
                "rating": rating,
                "reviews": reviews,
                "opening_hours": opening_hours,
                "price_range": price_range,
                "website": website,
                "google_maps_uri": gmaps,
                "place_id": place_id,
                "createdAt": datetime.utcnow().isoformat(),
            }
            
            await db.restaurants.insert_one(doc)
            added += 1
            
            print(f"    Rating: {rating} ({reviews} reviews)")
            print(f"    Address: {address[:60]}")
            print(f"    Price: {price_range}")
            
        except Exception as e:
            print(f"  Error: {e}")
    
    print(f"\n=== Done! Added {added} real restaurants ===")

asyncio.run(main())