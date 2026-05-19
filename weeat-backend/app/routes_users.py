from fastapi import APIRouter, HTTPException, Query
from bson import ObjectId
from typing import Optional

from .db import users_col, plans_col, friends_col

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me")
async def get_me(email: str = Query(...)):
    email = email.lower().strip()
    user = await users_col.find_one({"email": email}, {"password_hash": 0})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "ok": True,
        "user_id": str(user["_id"]),
        "email": user["email"],
        "first_name": user.get("first_name", ""),
        "last_name": user.get("last_name", ""),
        "display_name": user.get("display_name", user.get("first_name", "")),
        "username": user.get("username"),
        "tag": user.get("tag"),
        "handle": user.get("handle"),
        "wishlist_count": len(user.get("wishlist_restaurant_ids", [])),
    }


@router.get("/verify-email")
async def verify_email(email: str = Query(...)):
    """
    Check if an email exists in the database.
    Returns 200 if exists, 404 if not.
    """
    email = email.lower().strip()
    user = await users_col.find_one({"email": email}, {"_id": 1})
    if not user:
        raise HTTPException(status_code=404, detail="Email not found")
    
    return {"ok": True, "exists": True, "email": email}


@router.get("/stats")
async def get_user_stats(email: str = Query(...)):
    """Get user stats: wishlist, liked, disliked, plans counts, and followers/following."""
    email = email.lower().strip()
    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    wishlist_count = len(user.get("wishlist_restaurant_ids", []))
    liked_count = len(user.get("liked_restaurant_ids", []))
    disliked_count = len(user.get("disliked_restaurant_ids", []))
    
    # Count plans
    plans_count = await plans_col.count_documents({"user_email": email})
    
    # Count followers (people who follow this user)
    followers_count = await friends_col.count_documents({
        "to_email": email,
        "status": "accepted"
    })
    
    # Count following (people this user follows)
    following_count = await friends_col.count_documents({
        "from_email": email,
        "status": "accepted"
    })

    return {
        "ok": True,
        "wishlist_count": wishlist_count,
        "liked_count": liked_count,
        "disliked_count": disliked_count,
        "plans_count": plans_count,
        "followers_count": followers_count,
        "following_count": following_count,
    }


@router.get("/search")
async def search_users(q: Optional[str] = Query(default=None), limit: int = 20):
    if not q or not q.strip():
        return []

    query_str = q.strip().lower()
    query = {
        "$or": [
            {"first_name": {"$regex": query_str, "$options": "i"}},
            {"last_name": {"$regex": query_str, "$options": "i"}},
            {"username": {"$regex": query_str, "$options": "i"}},
            {"handle": {"$regex": query_str, "$options": "i"}},
            {"email": {"$regex": query_str, "$options": "i"}},
        ]
    }

    cursor = users_col.find(query, {"password_hash": 0}).limit(limit)
    docs = await cursor.to_list(length=limit)

    results = []
    for user in docs:
        name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
        handle = f"{user.get('username', user.get('first_name', 'User'))}#{user.get('tag', '0000')}"
        results.append({
            "email": user.get("email", ""),
            "name": name,
            "handle": handle,
            "username": user.get("username"),
        })

    return results