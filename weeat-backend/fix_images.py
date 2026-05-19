import asyncio
from motor.motor_asyncio import AsyncIOMotorClient

async def fix_images():
    client = AsyncIOMotorClient('mongodb+srv://weeat_userr:123455@cluster01.rsszzqs.mongodb.net/?appName=Cluster01')
    db = client['weeat']
    
    # Use only Unsplash images (they work everywhere)
    restaurant_images = {
        "KFC": "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=500",
        "McDonald's": "https://images.unsplash.com/photo-1619881790790-3a4e41d41e52?w=500",
        "Burger King": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500",
        "Subway": "https://images.unsplash.com/photo-1553909489-cd47e0907980?w=500",
        "Papa John's": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500",
        "The Cheesecake Factory": "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500",
        "TGI Friday's": "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500",
        "Chili's": "https://images.unsplash.com/photo-1544025162-d76694265947?w=500",
        "Al Mallah": "https://images.unsplash.com/photo-1541518763669-27fef04b14ea?w=500",
        "Zaroob": "https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=500",
        "Operation: Falafel": "https://images.unsplash.com/photo-1593001874117-c99c800e3eb7?w=500",
        "P.F. Chang's": "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
        "Yo! Sushi": "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=500",
        "Wagamama": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500",
        "Nando's": "https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=500",
        "Starbucks": "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500",
        "Tim Hortons": "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=500",
        "Pizza Hut": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500",
        "Domino's Pizza": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=500",
        "Baskin-Robbins": "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=500",
        "Pierchic": "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=500",
        "Zuma": "https://images.unsplash.com/photo-1579027989536-b7b1f875659b?w=500",
        "Ravi Restaurant": "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=500",
        "Karachi Darbar": "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=500",
    }
    
    # Update each restaurant
    for name, url in restaurant_images.items():
        result = await db.restaurants.update_one(
            {"name": name},
            {"$set": {"imageUrl": url}}
        )
        if result.modified_count > 0:
            print(f"Updated: {name}")
    
    print(f"\nDone! Updated {len(restaurant_images)} restaurants")

asyncio.run(fix_images())