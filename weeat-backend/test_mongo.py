import asyncio
from app.db import users

async def main():
    res = await users.insert_one({"hello": "world"})
    print("Inserted:", res.inserted_id)

asyncio.run(main())
