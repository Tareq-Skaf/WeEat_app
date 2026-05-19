"""
Seed script to populate the database with demo data.
Run: python seed_db.py
"""
import asyncio
import os
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
import bcrypt


async def seed():
    # Connect
    MONGO_URL = "mongodb+srv://weeat_userr:123455@cluster01.rsszzqs.mongodb.net/?appName=Cluster01"
    DB_NAME = "weeat"
    
    client = AsyncIOMotorClient(MONGO_URL)
    db = client[DB_NAME]
    
    users_col = db["users"]
    restaurants_col = db["restaurants"]
    posts_col = db["posts"]
    plans_col = db["plans"]
    comments_col = db["comments"]
    friends_col = db["friends"]
    
    print("Creating indexes...")
    
    # Users indexes
    await users_col.create_index("email", unique=True)
    await users_col.create_index("username", unique=True, sparse=True)
    await users_col.create_index(
        [("identity_key", 1), ("tag", 1)],
        unique=True,
        name="identity_key_1_tag_1",
        partialFilterExpression={
            "identity_key": {"$type": "string"},
            "tag": {"$type": "string"},
        },
    )
    
    print("[+] Indexes created")
    
    # Seed restaurants
    count = await restaurants_col.count_documents({})
    if count == 0:
        demo_restaurants = [
            {
                "name": "Mama's Pizza",
                "cuisine": "Italian",
                "address": "Downtown Street 12",
                "phone": "+971500000001",
                "lat": 25.4052,
                "lng": 55.5136,
                "imageUrl": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500",
                "rating": 4.6,
                "opening_hours": "10:00 AM - 11:00 PM",
                "price_range": "$$",
                "createdAt": datetime.utcnow().isoformat(),
            },
            {
                "name": "Sushi House",
                "cuisine": "Japanese",
                "address": "City Walk 3",
                "phone": "+971500000002",
                "lat": 25.2048,
                "lng": 55.2708,
                "imageUrl": "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=500",
                "rating": 4.7,
                "opening_hours": "11:00 AM - 10:00 PM",
                "price_range": "$$$",
                "createdAt": datetime.utcnow().isoformat(),
            },
            {
                "name": "Burger Lab",
                "cuisine": "American",
                "address": "Mall Road 9",
                "phone": "+971500000003",
                "lat": 25.276987,
                "lng": 55.296249,
                "imageUrl": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500",
                "rating": 4.4,
                "opening_hours": "9:00 AM - 12:00 AM",
                "price_range": "$$",
                "createdAt": datetime.utcnow().isoformat(),
            },
        ]
        await restaurants_col.insert_many(demo_restaurants)
        print("[+] Seeded {} restaurants".format(len(demo_restaurants)))
    else:
        print(f"[+] Restaurants already exist ({count})")
    
    # Seed a test user
    email = "tarek@test.com"
    existing_user = await users_col.find_one({"email": email})
    if not existing_user:
        password_hash = bcrypt.hashpw("password123".encode(), bcrypt.gensalt()).decode()
        
        user_doc = {
            "first_name": "Tarek",
            "last_name": "Skaf",
            "display_name": "Tarek Skaf",
            "email": email,
            "username": "tarek",
            "identity_key": "tarek",
            "tag": "0001",
            "handle": "tarek#0001",
            "password_hash": password_hash,
            "wishlist_restaurant_ids": [],
            "liked_restaurant_ids": [],
            "disliked_restaurant_ids": [],
            "is_admin": True,
            "created_at": datetime.utcnow(),
        }
        await users_col.insert_one(user_doc)
        print("[+] Seeded test user: tarek@test.com / password123 (ADMIN)")
    else:
        await users_col.update_one({"email": email}, {"$set": {"is_admin": True}})
        print("[+] Test user already exists (set as ADMIN)")
    
    # List what's in the DB now
    print("\n# Database Status:")
    print(f"  Users: {await users_col.count_documents({})}")
    print(f"  Restaurants: {await restaurants_col.count_documents({})}")
    print(f"  Posts: {await posts_col.count_documents({})}")
    print(f"  Plans: {await plans_col.count_documents({})}")
    print(f"  Comments: {await comments_col.count_documents({})}")
    print(f"  Friends: {await friends_col.count_documents({})}")
    
    print("\nDone! Your new cluster is ready.")
    print("You can now use:")
    print("  - Email: tarek@test.com")
    print("  - Password: password123")


if __name__ == "__main__":
    asyncio.run(seed())