from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from bson import ObjectId
from datetime import datetime

from .db import users_col, restaurants_col, plans_col

router = APIRouter(prefix="/plans", tags=["plans"])


# ==================== MODELS ====================

class PlanCreateRequest(BaseModel):
    email: EmailStr
    title: str
    restaurant_id: Optional[str] = None
    restaurant_name: Optional[str] = ""
    date: str  # format: "YYYY-MM-DD"
    time: str  # format: "HH:MM"
    notes: Optional[str] = ""


class PlanUpdateRequest(BaseModel):
    plan_id: str
    title: Optional[str] = None
    restaurant_id: Optional[str] = None
    restaurant_name: Optional[str] = None
    date: Optional[str] = None
    time: Optional[str] = None
    notes: Optional[str] = None


# ==================== ROUTES ====================

@router.post("")
async def create_plan(payload: PlanCreateRequest):
    email = payload.email.lower().strip()
    
    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Verify restaurant if provided
    restaurant_data = None
    if payload.restaurant_id:
        try:
            r_obj = ObjectId(payload.restaurant_id)
            restaurant = await restaurants_col.find_one({"_id": r_obj})
            if restaurant:
                restaurant_data = {
                    "id": str(restaurant["_id"]),
                    "name": restaurant.get("name", ""),
                    "address": restaurant.get("address", ""),
                }
        except Exception:
            pass

    # Create plan
    plan = {
        "user_email": email,
        "title": payload.title,
        "restaurant_id": payload.restaurant_id or "",
        "restaurant_name": payload.restaurant_name or "",
        "restaurant_address": restaurant_data.get("address", "") if restaurant_data else "",
        "date": payload.date,
        "time": payload.time,
        "notes": payload.notes or "",
        "created_at": datetime.utcnow().isoformat(),
    }

    result = await plans_col.insert_one(plan)
    plan["id"] = str(result.inserted_id)
    plan.pop("_id", None)
    plan.pop("user_email", None)

    return {"ok": True, "plan": plan}


@router.get("")
async def get_plans(email: str = Query(...)):
    email = email.lower().strip()
    
    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    plans = []
    cursor = plans_col.find({"user_email": email}).sort("date", 1)
    async for p in cursor:
        p["id"] = str(p["_id"])
        p.pop("_id", None)
        p.pop("user_email", None)
        plans.append(p)

    return plans


@router.get("/{plan_id}")
async def get_plan(plan_id: str):
    try:
        p_obj = ObjectId(plan_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid plan_id")

    plan = await plans_col.find_one({"_id": p_obj})
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    plan["id"] = str(plan["_id"])
    plan.pop("_id", None)
    plan.pop("user_email", None)

    return plan


@router.put("/{plan_id}")
async def update_plan(plan_id: str, payload: PlanUpdateRequest):
    try:
        p_obj = ObjectId(plan_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid plan_id")

    plan = await plans_col.find_one({"_id": p_obj})
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    # Build update dict
    update_data = {}
    if payload.title is not None:
        update_data["title"] = payload.title
    if payload.restaurant_id is not None:
        update_data["restaurant_id"] = payload.restaurant_id
    if payload.restaurant_name is not None:
        update_data["restaurant_name"] = payload.restaurant_name
    if payload.date is not None:
        update_data["date"] = payload.date
    if payload.time is not None:
        update_data["time"] = payload.time
    if payload.notes is not None:
        update_data["notes"] = payload.notes

    if update_data:
        await plans_col.update_one(
            {"_id": p_obj},
            {"$set": update_data}
        )

    # Return updated plan
    updated = await plans_col.find_one({"_id": p_obj})
    updated["id"] = str(updated["_id"])
    updated.pop("_id", None)
    updated.pop("user_email", None)

    return {"ok": True, "plan": updated}


@router.delete("/{plan_id}")
async def delete_plan(plan_id: str):
    try:
        p_obj = ObjectId(plan_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid plan_id")

    plan = await plans_col.find_one({"_id": p_obj})
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    await plans_col.delete_one({"_id": p_obj})

    return {"ok": True, "deleted": True}
