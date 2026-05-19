import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime

async def add_missing():
    client = AsyncIOMotorClient('mongodb+srv://weeat_userr:123455@cluster01.rsszzqs.mongodb.net/?appName=Cluster01')
    db = client['weeat']
    
    # Add KFC if missing
    kfc = await db.restaurants.find_one({"name": "KFC"})
    if not kfc:
        doc = {
            "name": "KFC",
            "cuisine": "Fast Food",
            "address": "Dubai Mall, Financial Center Road, Downtown Dubai",
            "phone": "+971 4 339 9888",
            "lat": 25.1972,
            "lng": 55.2744,
            "imageUrl": "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=500",
            "rating": 4.3,
            "reviews": 2500,
            "opening_hours": "10:00 AM - 12:00 AM",
            "price_range": "$$",
            "website": "https://www.kfc.me",
            "google_maps_uri": "",
            "place_id": "",
            "createdAt": datetime.utcnow().isoformat(),
        }
        await db.restaurants.insert_one(doc)
        print("Added KFC")
    
    # Show final count
    count = await db.restaurants.count_documents({})
    print(f"Total restaurants: {count}")

asyncio.run(add_missing())