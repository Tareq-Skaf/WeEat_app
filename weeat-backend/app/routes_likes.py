from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, EmailStr
from bson import ObjectId

from .db import users_col, restaurants_col

router = APIRouter(tags=["likes"])


# ==================== LIKED ====================

class LikeToggleRequest(BaseModel):
    email: EmailStr
    restaurant_id: str


@router.post("/liked/toggle")
async def toggle_liked(payload: LikeToggleRequest):
    email = payload.email.lower().strip()
    rid = payload.restaurant_id

    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # ensure restaurant exists
    try:
        r_obj = ObjectId(rid)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid restaurant_id")

    restaurant = await restaurants_col.find_one({"_id": r_obj})
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")

    liked_ids = user.get("liked_restaurant_ids", [])
    in_liked = rid in liked_ids

    if in_liked:
        liked_ids.remove(rid)
    else:
        liked_ids.append(rid)

    await users_col.update_one(
        {"_id": user["_id"]},
        {"$set": {"liked_restaurant_ids": liked_ids}}
    )

    return {"ok": True, "in_liked": (not in_liked)}


@router.get("/liked")
async def get_liked(email: str = Query(...)):
    email = email.lower().strip()
    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    ids = user.get("liked_restaurant_ids", [])
    obj_ids = []
    for rid in ids:
        try:
            obj_ids.append(ObjectId(rid))
        except Exception:
            continue

    restaurants = []
    cursor = restaurants_col.find({"_id": {"$in": obj_ids}})
    async for r in cursor:
        r["id"] = str(r["_id"])
        r.pop("_id", None)
        restaurants.append(r)

    return restaurants


# ==================== DISLIKED ====================

class DislikeToggleRequest(BaseModel):
    email: EmailStr
    restaurant_id: str


@router.post("/disliked/toggle")
async def toggle_disliked(payload: DislikeToggleRequest):
    email = payload.email.lower().strip()
    rid = payload.restaurant_id

    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # ensure restaurant exists
    try:
        r_obj = ObjectId(rid)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid restaurant_id")

    restaurant = await restaurants_col.find_one({"_id": r_obj})
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")

    disliked_ids = user.get("disliked_restaurant_ids", [])
    in_disliked = rid in disliked_ids

    if in_disliked:
        disliked_ids.remove(rid)
    else:
        disliked_ids.append(rid)

    await users_col.update_one(
        {"_id": user["_id"]},
        {"$set": {"disliked_restaurant_ids": disliked_ids}}
    )

    return {"ok": True, "in_disliked": (not in_disliked)}


@router.get("/disliked")
async def get_disliked(email: str = Query(...)):
    email = email.lower().strip()
    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    ids = user.get("disliked_restaurant_ids", [])
    obj_ids = []
    for rid in ids:
        try:
            obj_ids.append(ObjectId(rid))
        except Exception:
            continue

    restaurants = []
    cursor = restaurants_col.find({"_id": {"$in": obj_ids}})
    async for r in cursor:
        r["id"] = str(r["_id"])
        r.pop("_id", None)
        restaurants.append(r)

    return restaurants
