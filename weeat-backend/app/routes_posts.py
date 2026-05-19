from fastapi import APIRouter, HTTPException, Query
from bson import ObjectId
from datetime import datetime
from typing import Optional

from .db import posts_col, users_col, restaurants_col

router = APIRouter(prefix="/posts", tags=["posts"])


def serialize_post(doc: dict) -> dict:
    return {
        "id": str(doc["_id"]),
        "user_email": doc.get("user_email", ""),
        "user_name": doc.get("user_name", ""),
        "user_handle": doc.get("user_handle", ""),
        "restaurant_name": doc.get("restaurant_name", ""),
        "restaurant_id": doc.get("restaurant_id", ""),
        "fsq_id": doc.get("fsq_id", ""),
        "description": doc.get("description", ""),
        "rating": doc.get("rating", 0),
        "price_range": doc.get("price_range", ""),
        "image_url": doc.get("image_url", ""),
        "likes": doc.get("likes", []),
        "likes_count": len(doc.get("likes", [])),
        "is_review": doc.get("is_review", False),
        "created_at": doc.get("created_at", ""),
    }


@router.get("")
async def list_posts(limit: int = 20, skip: int = 0, include_reviews: bool = False):
    # Home feed: exclude restaurant-only reviews by default
    query = {}
    if not include_reviews:
        query["$or"] = [{"is_review": {"$ne": True}}, {"is_review": {"$exists": False}}]

    cursor = posts_col.find(query).sort("created_at", -1).skip(skip).limit(limit)
    docs = await cursor.to_list(length=limit)

    enriched = []
    for doc in docs:
        post = serialize_post(doc)
        # Get user info if not already stored
        if not post.get("user_name"):
            user = await users_col.find_one({"email": doc.get("user_email")}, {"first_name": 1, "last_name": 1, "username": 1, "tag": 1})
            if user:
                post["user_name"] = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
                post["user_handle"] = f"{user.get('username', user.get('first_name', 'User'))}#{user.get('tag', '0000')}"
        enriched.append(post)

    return enriched


@router.get("/user/{email}")
async def get_user_posts(email: str, limit: int = 20):
    email = email.lower().strip()
    cursor = posts_col.find({"user_email": email}).sort("created_at", -1).limit(limit)
    docs = await cursor.to_list(length=limit)
    return [serialize_post(d) for d in docs]


@router.post("")
async def create_post(payload: dict):
    """
    Create a new post or restaurant review.
    Expected payload:
    {
        "user_email": "user@example.com",
        "restaurant_name": "Restaurant Name",
        "restaurant_id": "optional_id",
        "fsq_id": "optional_foursquare_id",
        "description": "My experience...",
        "rating": 5,
        "price_range": "Reasonable",
        "image_base64": "base64_string" (optional),
        "is_review": false
    }
    """
    user_email = payload.get("user_email", "").lower().strip()
    restaurant_name = payload.get("restaurant_name", "")
    description = payload.get("description", "")
    rating = payload.get("rating", 0)
    price_range = payload.get("price_range", "")
    is_review = payload.get("is_review", False)
    fsq_id = payload.get("fsq_id", "")

    if not user_email:
        raise HTTPException(status_code=400, detail="user_email is required")
    if not restaurant_name:
        raise HTTPException(status_code=400, detail="restaurant_name is required")
    if rating == 0:
        raise HTTPException(status_code=400, detail="rating is required")

    # Verify user exists
    user = await users_col.find_one({"email": user_email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Handle image (optional)
    image_url = ""
    if payload.get("image_base64"):
        image_url = f"data:image/jpeg;base64,{payload.get('image_base64')}"

    user_name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
    user_handle = f"{user.get('username', user.get('first_name', 'User'))}#{user.get('tag', '0000')}"

    restaurant_id = payload.get("restaurant_id", "")
    if restaurant_id and ObjectId.is_valid(restaurant_id):
        pipeline = [
            {"$match": {"restaurant_id": restaurant_id}},
            {"$group": {"_id": None, "avg_rating": {"$avg": "$rating"}, "count": {"$sum": 1}}}
        ]
        result = await posts_col.aggregate(pipeline).to_list(1)
        if result:
            new_rating = round(result[0]["avg_rating"], 1)
            await restaurants_col.update_one(
                {"_id": ObjectId(restaurant_id)},
                {"$set": {"rating": new_rating}}
            )

    doc = {
        "user_email": user_email,
        "user_name": user_name,
        "user_handle": user_handle,
        "restaurant_name": restaurant_name,
        "restaurant_id": restaurant_id,
        "fsq_id": fsq_id,
        "description": description,
        "rating": rating,
        "price_range": price_range,
        "image_url": image_url,
        "is_review": is_review,
        "likes": [],
        "created_at": datetime.utcnow().isoformat(),
    }

    result = await posts_col.insert_one(doc)
    doc["_id"] = result.inserted_id

    return serialize_post(doc)


@router.get("/reviews")
async def get_reviews_by_restaurant(
    restaurant_name: Optional[str] = Query(default=None),
    fsq_id: Optional[str] = Query(default=None),
    limit: int = 50,
):
    """Get reviews for a specific restaurant by name or fsq_id."""
    query = {"is_review": True}

    if fsq_id and fsq_id.strip():
        query["fsq_id"] = fsq_id.strip()
    elif restaurant_name and restaurant_name.strip():
        escaped = restaurant_name.strip().replace("(", "\\(").replace(")", "\\)")
        query["restaurant_name"] = {"$regex": escaped, "$options": "i"}
    else:
        raise HTTPException(status_code=400, detail="restaurant_name or fsq_id is required")

    cursor = posts_col.find(query).sort("created_at", -1).limit(limit)
    docs = await cursor.to_list(length=limit)
    return [serialize_post(d) for d in docs]


@router.post("/{post_id}/like")
async def like_post(post_id: str, email: str):
    """Like or unlike a post"""
    if not ObjectId.is_valid(post_id):
        raise HTTPException(status_code=400, detail="Invalid post_id")
    
    email = email.lower().strip()
    
    post = await posts_col.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    likes = post.get("likes", [])
    
    if email in likes:
        likes.remove(email)
        action = "unliked"
    else:
        likes.append(email)
        action = "liked"
    
    await posts_col.update_one(
        {"_id": ObjectId(post_id)},
        {"$set": {"likes": likes}}
    )
    
    return {"ok": True, "action": action, "likes_count": len(likes)}


@router.delete("/{post_id}")
async def delete_post(post_id: str, email: str):
    """Delete a post (only by the author)"""
    if not ObjectId.is_valid(post_id):
        raise HTTPException(status_code=400, detail="Invalid post_id")
    
    email = email.lower().strip()
    
    post = await posts_col.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    if post.get("user_email", "").lower().strip() != email:
        raise HTTPException(status_code=403, detail="Not authorized to delete this post")
    
    await posts_col.delete_one({"_id": ObjectId(post_id)})
    
    return {"ok": True, "message": "Post deleted"}
