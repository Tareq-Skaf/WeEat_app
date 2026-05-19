import asyncio
from motor.motor_asyncio import AsyncIOMotorClient

async def update():
    client = AsyncIOMotorClient('mongodb+srv://weeat_userr:123455@cluster01.rsszzqs.mongodb.net/?appName=Cluster01')
    db = client['weeat']
    
    images = {
        "Mama's Pizza": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500",
        "Sushi House": "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=500",
        "Burger Lab": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500",
    }
    
    hours = {
        "Mama's Pizza": "10:00 AM - 11:00 PM",
        "Sushi House": "11:00 AM - 10:00 PM",
        "Burger Lab": "9:00 AM - 12:00 AM",
    }
    
    prices = {
        "Mama's Pizza": "$$",
        "Sushi House": "$$$",
        "Burger Lab": "$$",
    }
    
    for name, url in images.items():
        await db.restaurants.update_one(
            {"name": name},
            {"$set": {"imageUrl": url, "opening_hours": hours[name], "price_range": prices[name]}}
        )
        print(f"Updated {name}")
    
    await db.users.update_one({"email": "tarek@test.com"}, {"$set": {"is_admin": True}})
    print("Made tarek@test.com admin")
    
    # Verify
    user = await db.users.find_one({"email": "tarek@test.com"})
    print(f"tarek is_admin: {user.get('is_admin', False)}")
    
    for r in await db.restaurants.find({}).to_list(10):
        print(f"  {r['name']}: {r.get('imageUrl', 'NO IMAGE')[:50]}...")

asyncio.run(update())