from fastapi import APIRouter, HTTPException, Query
from bson import ObjectId

from .db import users_col, restaurants_col
from .models import WishlistToggleRequest

router = APIRouter(prefix="/wishlist", tags=["wishlist"])


@router.post("/toggle")
async def toggle_wishlist(payload: WishlistToggleRequest):
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

    wishlist_ids = user.get("wishlist_restaurant_ids", [])
    in_wishlist = rid in wishlist_ids

    if in_wishlist:
        wishlist_ids.remove(rid)
    else:
        wishlist_ids.append(rid)

    await users_col.update_one(
        {"_id": user["_id"]},
        {"$set": {"wishlist_restaurant_ids": wishlist_ids}}
    )

    return {"ok": True, "in_wishlist": (not in_wishlist)}


@router.get("/")
async def get_wishlist(email: str = Query(...)):
    email = email.lower().strip()
    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    ids = user.get("wishlist_restaurant_ids", [])
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