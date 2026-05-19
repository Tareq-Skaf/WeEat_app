from fastapi import APIRouter, HTTPException, Query, UploadFile, File
from bson import ObjectId
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel
import base64

from .db import db, users_col, restaurants_col, menus_col

router = APIRouter(tags=["admin"])

banned_users_col = db["banned_users"]
admin_logs_col = db["admin_logs"]


class BanUserRequest(BaseModel):
    admin_email: str
    target_email: str
    reason: str = ""


class AddRestaurantRequest(BaseModel):
    admin_email: str
    name: str
    cuisine: str
    address: str
    phone: str = ""
    lat: float = 0.0
    lng: float = 0.0
    image_url: str = ""
    rating: float = 0.0
    opening_hours: str = ""
    price_range: str = ""


class UpdateRestaurantRequest(BaseModel):
    admin_email: str
    name: Optional[str] = None
    cuisine: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    image_url: Optional[str] = None
    rating: Optional[float] = None
    opening_hours: Optional[str] = None
    price_range: Optional[str] = None


async def is_admin(email: str) -> bool:
    user = await users_col.find_one({"email": email.lower().strip()})
    if not user:
        return False
    return user.get("is_admin", False)


async def log_admin_action(admin_email: str, action: str, target: str, details: str = ""):
    await admin_logs_col.insert_one({
        "admin_email": admin_email,
        "action": action,
        "target": target,
        "details": details,
        "timestamp": datetime.utcnow().isoformat(),
    })


async def is_banned(email: str) -> bool:
    banned = await banned_users_col.find_one({"email": email.lower().strip(), "is_active": True})
    return banned is not None


@router.get("/admin/check")
async def check_admin(email: str = Query(...)):
    email = email.lower().strip()
    admin = await is_admin(email)
    return {"is_admin": admin}


@router.get("/admin/users")
async def list_users(admin_email: str = Query(...), limit: int = 50):
    if not await is_admin(admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    cursor = users_col.find({}, {"password_hash": 0}).limit(limit)
    docs = await cursor.to_list(limit)

    results = []
    for user in docs:
        banned = await banned_users_col.find_one({"email": user["email"], "is_active": True})
        results.append({
            "email": user["email"],
            "first_name": user.get("first_name", ""),
            "last_name": user.get("last_name", ""),
            "display_name": user.get("display_name", ""),
            "username": user.get("username"),
            "handle": user.get("handle", ""),
            "is_admin": user.get("is_admin", False),
            "is_banned": banned is not None,
            "created_at": user.get("created_at", ""),
        })

    return results


@router.post("/admin/ban")
async def ban_user(payload: BanUserRequest):
    if not await is_admin(payload.admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    target = payload.target_email.lower().strip()
    target_user = await users_col.find_one({"email": target})
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")

    if target_user.get("is_admin", False):
        raise HTTPException(status_code=400, detail="Cannot ban an admin")

    existing = await banned_users_col.find_one({"email": target, "is_active": True})
    if existing:
        raise HTTPException(status_code=400, detail="User is already banned")

    await banned_users_col.insert_one({
        "email": target,
        "banned_by": payload.admin_email,
        "reason": payload.reason,
        "is_active": True,
        "banned_at": datetime.utcnow().isoformat(),
    })

    await log_admin_action(payload.admin_email, "ban", target, payload.reason)

    return {"ok": True, "message": f"User {target} has been banned"}


@router.post("/admin/unban")
async def unban_user(payload: BanUserRequest):
    if not await is_admin(payload.admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    target = payload.target_email.lower().strip()

    existing = await banned_users_col.find_one({"email": target, "is_active": True})
    if not existing:
        raise HTTPException(status_code=400, detail="User is not banned")

    await banned_users_col.update_one(
        {"_id": existing["_id"]},
        {"$set": {"is_active": False, "unbanned_at": datetime.utcnow().isoformat()}}
    )

    await log_admin_action(payload.admin_email, "unban", target)

    return {"ok": True, "message": f"User {target} has been unbanned"}


@router.get("/admin/banned")
async def list_banned_users(admin_email: str = Query(...)):
    if not await is_admin(admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    cursor = banned_users_col.find({"is_active": True})
    docs = await cursor.to_list(100)

    results = []
    for doc in docs:
        user = await users_col.find_one({"email": doc["email"]}, {"password_hash": 0})
        user_name = ""
        if user:
            user_name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()

        results.append({
            "email": doc["email"],
            "user_name": user_name,
            "banned_by": doc.get("banned_by", ""),
            "reason": doc.get("reason", ""),
            "banned_at": doc.get("banned_at", ""),
        })

    return results


@router.post("/admin/restaurants")
async def add_restaurant(payload: AddRestaurantRequest):
    if not await is_admin(payload.admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    if not payload.name.strip():
        raise HTTPException(status_code=400, detail="Restaurant name is required")

    doc = {
        "name": payload.name.strip(),
        "cuisine": payload.cuisine.strip(),
        "address": payload.address.strip(),
        "phone": payload.phone.strip(),
        "lat": payload.lat,
        "lng": payload.lng,
        "imageUrl": payload.image_url.strip(),
        "rating": payload.rating,
        "opening_hours": payload.opening_hours.strip(),
        "price_range": payload.price_range.strip(),
        "createdAt": datetime.utcnow().isoformat(),
        "added_by": payload.admin_email,
    }

    result = await restaurants_col.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)

    await log_admin_action(payload.admin_email, "add_restaurant", str(result.inserted_id), payload.name)

    return {"ok": True, "restaurant": doc}


@router.put("/admin/restaurants/{restaurant_id}")
async def update_restaurant(restaurant_id: str, payload: UpdateRestaurantRequest):
    if not await is_admin(payload.admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    if not ObjectId.is_valid(restaurant_id):
        raise HTTPException(status_code=400, detail="Invalid restaurant id")

    restaurant = await restaurants_col.find_one({"_id": ObjectId(restaurant_id)})
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")

    update_data = {}
    if payload.name is not None:
        update_data["name"] = payload.name.strip()
    if payload.cuisine is not None:
        update_data["cuisine"] = payload.cuisine.strip()
    if payload.address is not None:
        update_data["address"] = payload.address.strip()
    if payload.phone is not None:
        update_data["phone"] = payload.phone.strip()
    if payload.lat is not None:
        update_data["lat"] = payload.lat
    if payload.lng is not None:
        update_data["lng"] = payload.lng
    if payload.image_url is not None:
        update_data["imageUrl"] = payload.image_url.strip()
    if payload.rating is not None:
        update_data["rating"] = payload.rating
    if payload.opening_hours is not None:
        update_data["opening_hours"] = payload.opening_hours.strip()
    if payload.price_range is not None:
        update_data["price_range"] = payload.price_range.strip()

    if update_data:
        await restaurants_col.update_one(
            {"_id": ObjectId(restaurant_id)},
            {"$set": update_data}
        )

    await log_admin_action(payload.admin_email, "update_restaurant", restaurant_id)

    return {"ok": True}


@router.delete("/admin/restaurants/{restaurant_id}")
async def delete_restaurant(restaurant_id: str, admin_email: str = Query(...)):
    if not await is_admin(admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    if not ObjectId.is_valid(restaurant_id):
        raise HTTPException(status_code=400, detail="Invalid restaurant id")

    restaurant = await restaurants_col.find_one({"_id": ObjectId(restaurant_id)})
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")

    await restaurants_col.delete_one({"_id": ObjectId(restaurant_id)})

    await log_admin_action(admin_email, "delete_restaurant", restaurant_id, restaurant.get("name", ""))

    return {"ok": True}


@router.post("/admin/restaurants/{restaurant_id}/image")
async def upload_restaurant_image(restaurant_id: str, admin_email: str, file: UploadFile = File(...)):
    if not await is_admin(admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    if not ObjectId.is_valid(restaurant_id):
        raise HTTPException(status_code=400, detail="Invalid restaurant id")

    restaurant = await restaurants_col.find_one({"_id": ObjectId(restaurant_id)})
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")

    content = await file.read()
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large (max 5MB)")

    mime_type = file.content_type or "image/jpeg"
    b64_data = base64.b64encode(content).decode()
    data_url = f"data:{mime_type};base64,{b64_data}"

    await restaurants_col.update_one(
        {"_id": ObjectId(restaurant_id)},
        {"$set": {"imageUrl": data_url}}
    )

    return {"ok": True, "image_url": data_url}


@router.get("/admin/logs")
async def get_admin_logs(admin_email: str = Query(...), limit: int = 50):
    if not await is_admin(admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    cursor = admin_logs_col.find({}).sort("timestamp", -1).limit(limit)
    docs = await cursor.to_list(limit)

    return [{
        "id": str(doc["_id"]),
        "admin_email": doc.get("admin_email", ""),
        "action": doc.get("action", ""),
        "target": doc.get("target", ""),
        "details": doc.get("details", ""),
        "timestamp": doc.get("timestamp", ""),
    } for doc in docs]


@router.post("/admin/make-admin")
async def make_admin(payload: dict):
    admin_email = payload.get("admin_email", "").lower().strip()
    target_email = payload.get("target_email", "").lower().strip()

    if not await is_admin(admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    target = await users_col.find_one({"email": target_email})
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    await users_col.update_one(
        {"email": target_email},
        {"$set": {"is_admin": True}}
    )

    await log_admin_action(admin_email, "make_admin", target_email)

    return {"ok": True, "message": f"{target_email} is now an admin"}


# ===================== ADMIN MENU MANAGEMENT =====================

@router.get("/admin/menus")
async def list_all_chain_menus(admin_email: str = Query(...), limit: int = 50):
    if not await is_admin(admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    cursor = menus_col.find({}).limit(limit)
    docs = await cursor.to_list(limit)
    return [{
        "chain_name": d.get("chain_name", ""),
        "chain_name_lower": d.get("chain_name_lower", ""),
        "updated_at": d.get("updated_at", ""),
        "total_items": sum(len(cat.get("items", [])) for cat in d.get("categories", [])),
    } for d in docs]


@router.get("/admin/menus/{chain_name}")
async def get_chain_menu_admin(chain_name: str, admin_email: str = Query(...)):
    if not await is_admin(admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    doc = await menus_col.find_one({"chain_name_lower": chain_name.strip().lower()})
    if not doc:
        raise HTTPException(status_code=404, detail="Menu not found")
    return {
        "chain_name": doc.get("chain_name", ""),
        "categories": doc.get("categories", []),
        "updated_at": doc.get("updated_at", ""),
    }


@router.post("/admin/menus")
async def upsert_chain_menu_admin(payload: dict):
    admin_email = payload.get("admin_email", "").lower().strip()
    if not await is_admin(admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    chain_name = payload.get("chain_name", "").strip()
    categories = payload.get("categories", [])
    if not chain_name:
        raise HTTPException(status_code=400, detail="chain_name is required")
    if not isinstance(categories, list):
        raise HTTPException(status_code=400, detail="categories must be a list")

    doc = {
        "chain_name": chain_name,
        "chain_name_lower": chain_name.lower(),
        "categories": categories,
        "updated_at": datetime.utcnow().isoformat(),
    }
    await menus_col.update_one(
        {"chain_name_lower": chain_name.lower()},
        {"$set": doc},
        upsert=True,
    )

    await log_admin_action(admin_email, "upsert_menu", chain_name)
    return {"ok": True, "chain_name": chain_name, "upserted": True}


@router.delete("/admin/menus/{chain_name}")
async def delete_chain_menu_admin(chain_name: str, admin_email: str = Query(...)):
    if not await is_admin(admin_email):
        raise HTTPException(status_code=403, detail="Admin access required")

    result = await menus_col.delete_one({"chain_name_lower": chain_name.strip().lower()})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Menu not found")

    await log_admin_action(admin_email, "delete_menu", chain_name)
    return {"ok": True, "deleted": True}