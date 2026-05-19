import os
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient

load_dotenv()  # <-- must be before getenv

MONGO_URL = os.getenv("MONGO_URL") or os.getenv("MONGODB_URI") or "mongodb://localhost:27017"
DB_NAME = os.getenv("DB_NAME", "weeat")

print("DB_NAME:", DB_NAME)

client = AsyncIOMotorClient(MONGO_URL)
db = client[DB_NAME]

users_col = db["users"]
restaurants_col = db["restaurants"]
posts_col = db["posts"]
plans_col = db["plans"]
comments_col = db["comments"]
friends_col = db["friends"]
menus_col = db["menus"]