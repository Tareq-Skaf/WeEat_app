from .db import users_col, restaurants_col, db

async def ensure_indexes():
    # Users
    await users_col.create_index("email", unique=True)
    await users_col.create_index("tag", unique=True, sparse=True)
    await users_col.create_index("username_lower", unique=True, sparse=True)

    # Restaurants
    await restaurants_col.create_index("name")
    await restaurants_col.create_index("cuisine")

    # Wishlists (avoid duplicates)
    wishlists_col = db["wishlists"]
    await wishlists_col.create_index([("email", 1), ("restaurant_id", 1)], unique=True)