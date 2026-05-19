from fastapi import APIRouter, HTTPException, Query, UploadFile, File
from bson import ObjectId
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel
import base64

from .db import db, users_col, restaurants_col, posts_col, friends_col

router = APIRouter(tags=["features"])

notifications_col = db["notifications"]
recent_searches_col = db["recent_searches"]
reports_col = db["reports"]
blocked_col = db["blocked_users"]
bookmarks_col = db["bookmarks"]
wishlist_notes_col = db["wishlist_notes"]
plan_invites_col = db["plan_invites"]


class ProfileUpdateRequest(BaseModel):
    email: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None


class PostUpdateRequest(BaseModel):
    description: Optional[str] = None
    rating: Optional[int] = None
    price_range: Optional[str] = None


class ReportRequest(BaseModel):
    reporter_email: str
    reported_type: str
    reported_id: str
    reason: str


class BookmarkRequest(BaseModel):
    email: str
    post_id: str


class WishlistNoteRequest(BaseModel):
    email: str
    restaurant_id: str
    note: str


class PlanInviteRequest(BaseModel):
    plan_id: str
    inviter_email: str
    invitee_email: str


class SearchRequest(BaseModel):
    email: str
    query: str
    search_type: str = "restaurant"


# ===================== PROFILE =====================

@router.put("/users/profile")
async def update_profile(payload: ProfileUpdateRequest):
    email = payload.email.lower().strip()
    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    update_data = {}
    if payload.first_name is not None:
        update_data["first_name"] = payload.first_name.strip()
    if payload.last_name is not None:
        update_data["last_name"] = payload.last_name.strip()
    if payload.bio is not None:
        update_data["bio"] = payload.bio.strip()
    if payload.avatar_url is not None:
        update_data["avatar_url"] = payload.avatar_url.strip()

    if update_data:
        if "first_name" in update_data or "last_name" in update_data:
            first = update_data.get("first_name", user.get("first_name", ""))
            last = update_data.get("last_name", user.get("last_name", ""))
            update_data["display_name"] = f"{first} {last}".strip()

        await users_col.update_one({"_id": user["_id"]}, {"$set": update_data})

    updated = await users_col.find_one({"_id": user["_id"]}, {"password_hash": 0})
    return {
        "ok": True,
        "user": {
            "email": updated["email"],
            "first_name": updated.get("first_name", ""),
            "last_name": updated.get("last_name", ""),
            "display_name": updated.get("display_name", ""),
            "username": updated.get("username"),
            "tag": updated.get("tag"),
            "handle": updated.get("handle"),
            "bio": updated.get("bio", ""),
            "avatar_url": updated.get("avatar_url", ""),
        }
    }


@router.post("/users/avatar")
async def upload_avatar(email: str, file: UploadFile = File(...)):
    email = email.lower().strip()
    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    content = await file.read()
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large (max 5MB)")

    mime_type = file.content_type or "image/jpeg"
    b64_data = base64.b64encode(content).decode()
    data_url = f"data:{mime_type};base64,{b64_data}"

    await users_col.update_one(
        {"_id": user["_id"]},
        {"$set": {"avatar_url": data_url}}
    )

    return {"ok": True, "avatar_url": data_url}


@router.get("/users/{user_email}/profile")
async def get_user_profile(user_email: str):
    user = await users_col.find_one({"email": user_email.lower().strip()}, {"password_hash": 0})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    posts_count = await posts_col.count_documents({"user_email": user_email.lower().strip()})

    return {
        "ok": True,
        "user": {
            "email": user["email"],
            "first_name": user.get("first_name", ""),
            "last_name": user.get("last_name", ""),
            "display_name": user.get("display_name", ""),
            "username": user.get("username"),
            "tag": user.get("tag"),
            "handle": user.get("handle"),
            "bio": user.get("bio", ""),
            "avatar_url": user.get("avatar_url", ""),
            "posts_count": posts_count,
            "created_at": user.get("created_at", ""),
        }
    }


# ===================== POSTS EDIT/DELETE =====================

@router.put("/posts/{post_id}")
async def edit_post(post_id: str, payload: PostUpdateRequest, email: str = Query(...)):
    email = email.lower().strip()
    if not ObjectId.is_valid(post_id):
        raise HTTPException(status_code=400, detail="Invalid post id")

    post = await posts_col.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.get("user_email") != email:
        raise HTTPException(status_code=403, detail="Can only edit your own posts")

    update_data = {}
    if payload.description is not None:
        update_data["description"] = payload.description.strip()
    if payload.rating is not None:
        update_data["rating"] = max(1, min(5, payload.rating))
    if payload.price_range is not None:
        update_data["price_range"] = payload.price_range.strip()

    if update_data:
        update_data["edited_at"] = datetime.utcnow().isoformat()
        await posts_col.update_one({"_id": ObjectId(post_id)}, {"$set": update_data})

    return {"ok": True}


@router.delete("/posts/{post_id}")
async def delete_post(post_id: str, email: str = Query(...)):
    email = email.lower().strip()
    if not ObjectId.is_valid(post_id):
        raise HTTPException(status_code=400, detail="Invalid post id")

    post = await posts_col.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.get("user_email") != email:
        raise HTTPException(status_code=403, detail="Can only delete your own posts")

    await posts_col.delete_one({"_id": ObjectId(post_id)})
    return {"ok": True}


# ===================== AVERAGE RATING =====================

@router.get("/restaurants/{restaurant_id}/rating")
async def get_restaurant_rating(restaurant_id: str):
    if not ObjectId.is_valid(restaurant_id):
        raise HTTPException(status_code=400, detail="Invalid restaurant id")

    pipeline = [
        {"$match": {"restaurant_id": restaurant_id}},
        {"$group": {"_id": None, "avg_rating": {"$avg": "$rating"}, "count": {"$sum": 1}}}
    ]

    result = await posts_col.aggregate(pipeline).to_list(1)

    if result:
        return {
            "ok": True,
            "average_rating": round(result[0]["avg_rating"], 1),
            "review_count": result[0]["count"]
        }
    return {"ok": True, "average_rating": 0, "review_count": 0}


# ===================== BOOKMARKS =====================

@router.post("/bookmarks/toggle")
async def toggle_bookmark(payload: BookmarkRequest):
    email = payload.email.lower().strip()
    post_id = payload.post_id

    existing = await bookmarks_col.find_one({"email": email, "post_id": post_id})
    if existing:
        await bookmarks_col.delete_one({"_id": existing["_id"]})
        return {"ok": True, "bookmarked": False}
    else:
        await bookmarks_col.insert_one({
            "email": email,
            "post_id": post_id,
            "created_at": datetime.utcnow().isoformat(),
        })
        return {"ok": True, "bookmarked": True}


@router.get("/bookmarks")
async def get_bookmarks(email: str = Query(...)):
    email = email.lower().strip()
    cursor = bookmarks_col.find({"email": email}).sort("created_at", -1)
    docs = await cursor.to_list(length=100)

    bookmarks = []
    for doc in docs:
        post = await posts_col.find_one({"_id": ObjectId(doc["post_id"])})
        if post:
            post["id"] = str(post["_id"])
            post.pop("_id", None)
            post["bookmarked_at"] = doc["created_at"]
            bookmarks.append(post)

    return bookmarks


# ===================== RECENT SEARCHES =====================

@router.post("/searches")
async def save_search(payload: SearchRequest):
    email = payload.email.lower().strip()

    existing = await recent_searches_col.find_one({
        "email": email,
        "query": payload.query.strip().lower(),
        "search_type": payload.search_type,
    })

    if existing:
        await recent_searches_col.update_one(
            {"_id": existing["_id"]},
            {"$set": {"searched_at": datetime.utcnow().isoformat()}}
        )
    else:
        await recent_searches_col.insert_one({
            "email": email,
            "query": payload.query.strip().lower(),
            "search_type": payload.search_type,
            "searched_at": datetime.utcnow().isoformat(),
        })

    return {"ok": True}


@router.get("/searches")
async def get_recent_searches(email: str = Query(...), search_type: str = Query(default="restaurant")):
    email = email.lower().strip()
    cursor = recent_searches_col.find({
        "email": email,
        "search_type": search_type,
    }).sort("searched_at", -1).limit(10)

    docs = await cursor.to_list(10)
    return [{"query": d["query"], "search_type": d["search_type"], "searched_at": d["searched_at"]} for d in docs]


@router.delete("/searches")
async def clear_recent_searches(email: str = Query(...)):
    email = email.lower().strip()
    await recent_searches_col.delete_many({"email": email})
    return {"ok": True}


# ===================== NOTIFICATIONS =====================

@router.get("/notifications")
async def get_notifications(email: str = Query(...), limit: int = 20):
    email = email.lower().strip()
    cursor = notifications_col.find({"email": email}).sort("created_at", -1).limit(limit)
    docs = await cursor.to_list(limit)

    results = []
    for doc in docs:
        results.append({
            "id": str(doc["_id"]),
            "type": doc.get("type", ""),
            "title": doc.get("title", ""),
            "message": doc.get("message", ""),
            "data": doc.get("data", {}),
            "is_read": doc.get("is_read", False),
            "created_at": doc.get("created_at", ""),
        })

    return results


@router.get("/notifications/unread-count")
async def get_unread_count(email: str = Query(...)):
    email = email.lower().strip()
    count = await notifications_col.count_documents({"email": email, "is_read": False})
    return {"count": count}


@router.put("/notifications/{notification_id}/read")
async def mark_notification_read(notification_id: str):
    if not ObjectId.is_valid(notification_id):
        raise HTTPException(status_code=400, detail="Invalid notification id")

    await notifications_col.update_one(
        {"_id": ObjectId(notification_id)},
        {"$set": {"is_read": True}}
    )
    return {"ok": True}


@router.put("/notifications/read-all")
async def mark_all_notifications_read(email: str = Query(...)):
    email = email.lower().strip()
    await notifications_col.update_many(
        {"email": email, "is_read": False},
        {"$set": {"is_read": True}}
    )
    return {"ok": True}


async def create_notification(email: str, notif_type: str, title: str, message: str, data: dict = None):
    await notifications_col.insert_one({
        "email": email.lower().strip(),
        "type": notif_type,
        "title": title,
        "message": message,
        "data": data or {},
        "is_read": False,
        "created_at": datetime.utcnow().isoformat(),
    })


# ===================== REPORT =====================

@router.post("/reports")
async def report_content(payload: ReportRequest):
    reporter = payload.reporter_email.lower().strip()

    existing = await reports_col.find_one({
        "reporter_email": reporter,
        "reported_type": payload.reported_type,
        "reported_id": payload.reported_id,
    })

    if existing:
        raise HTTPException(status_code=400, detail="Already reported")

    await reports_col.insert_one({
        "reporter_email": reporter,
        "reported_type": payload.reported_type,
        "reported_id": payload.reported_id,
        "reason": payload.reason.strip(),
        "status": "pending",
        "created_at": datetime.utcnow().isoformat(),
    })

    return {"ok": True, "message": "Report submitted"}


# ===================== BLOCK =====================

@router.get("/blocked/check")
async def check_blocked(email: str = Query(...), other_email: str = Query(...)):
    email = email.lower().strip()
    other_email = other_email.lower().strip()

    blocked = await blocked_col.find_one({
        "$or": [
            {"blocker": email, "blocked": other_email},
            {"blocker": other_email, "blocked": email},
        ]
    })

    return {"blocked": blocked is not None}


# ===================== WISHLIST NOTES =====================

@router.post("/wishlist/notes")
async def add_wishlist_note(payload: WishlistNoteRequest):
    email = payload.email.lower().strip()

    existing = await wishlist_notes_col.find_one({
        "email": email,
        "restaurant_id": payload.restaurant_id,
    })

    if existing:
        await wishlist_notes_col.update_one(
            {"_id": existing["_id"]},
            {"$set": {"note": payload.note.strip(), "updated_at": datetime.utcnow().isoformat()}}
        )
    else:
        await wishlist_notes_col.insert_one({
            "email": email,
            "restaurant_id": payload.restaurant_id,
            "note": payload.note.strip(),
            "created_at": datetime.utcnow().isoformat(),
        })

    return {"ok": True}


@router.get("/wishlist/notes")
async def get_wishlist_notes(email: str = Query(...)):
    email = email.lower().strip()
    cursor = wishlist_notes_col.find({"email": email})
    docs = await cursor.to_list(100)

    notes = {}
    for doc in docs:
        notes[doc["restaurant_id"]] = doc["note"]

    return notes


# ===================== PLAN INVITES =====================

@router.post("/plans/invite")
async def invite_to_plan(payload: PlanInviteRequest):
    inviter = payload.inviter_email.lower().strip()
    invitee = payload.invitee_email.lower().strip()

    if inviter == invitee:
        raise HTTPException(status_code=400, detail="Cannot invite yourself")

    inviter_user = await users_col.find_one({"email": inviter})
    if not inviter_user:
        raise HTTPException(status_code=404, detail="Inviter not found")

    invitee_user = await users_col.find_one({"email": invitee})
    if not invitee_user:
        raise HTTPException(status_code=404, detail="Invitee not found")

    inviter_name = f"{inviter_user.get('first_name', '')} {inviter_user.get('last_name', '')}".strip()

    await plan_invites_col.insert_one({
        "plan_id": payload.plan_id,
        "inviter_email": inviter,
        "invitee_email": invitee,
        "status": "pending",
        "created_at": datetime.utcnow().isoformat(),
    })

    await create_notification(
        email=invitee,
        notif_type="plan_invite",
        title="Plan Invitation",
        message=f"{inviter_name} invited you to a meal plan",
        data={"plan_id": payload.plan_id, "inviter_email": inviter},
    )

    return {"ok": True}


@router.get("/plans/invites")
async def get_plan_invites(email: str = Query(...)):
    email = email.lower().strip()
    cursor = plan_invites_col.find({"invitee_email": email, "status": "pending"}).sort("created_at", -1)
    docs = await cursor.to_list(20)

    results = []
    for doc in docs:
        inviter = await users_col.find_one({"email": doc["inviter_email"]})
        inviter_name = ""
        if inviter:
            inviter_name = f"{inviter.get('first_name', '')} {inviter.get('last_name', '')}".strip()

        results.append({
            "id": str(doc["_id"]),
            "plan_id": doc["plan_id"],
            "inviter_email": doc["inviter_email"],
            "inviter_name": inviter_name,
            "status": doc["status"],
            "created_at": doc["created_at"],
        })

    return results


@router.put("/plans/invites/{invite_id}/accept")
async def accept_plan_invite(invite_id: str):
    if not ObjectId.is_valid(invite_id):
        raise HTTPException(status_code=400, detail="Invalid invite id")

    invite = await plan_invites_col.find_one({"_id": ObjectId(invite_id)})
    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")

    await plan_invites_col.update_one(
        {"_id": ObjectId(invite_id)},
        {"$set": {"status": "accepted"}}
    )

    return {"ok": True}


@router.put("/plans/invites/{invite_id}/decline")
async def decline_plan_invite(invite_id: str):
    if not ObjectId.is_valid(invite_id):
        raise HTTPException(status_code=400, detail="Invalid invite id")

    await plan_invites_col.update_one(
        {"_id": ObjectId(invite_id)},
        {"$set": {"status": "declined"}}
    )

    return {"ok": True}


# ===================== FOLLOWERS/FOLLOWING LISTS =====================

@router.get("/users/{user_email}/followers")
async def get_followers(user_email: str, limit: int = 50):
    user_email = user_email.lower().strip()

    cursor = friends_col.find({
        "to_email": user_email,
        "status": "accepted"
    }).sort("created_at", -1).limit(limit)

    docs = await cursor.to_list(limit)

    followers = []
    for doc in docs:
        follower = await users_col.find_one({"email": doc["from_email"]}, {"password_hash": 0})
        if follower:
            name = f"{follower.get('first_name', '')} {follower.get('last_name', '')}".strip()
            handle = f"{follower.get('username', follower.get('first_name', 'User'))}#{follower.get('tag', '0000')}"
            followers.append({
                "email": follower["email"],
                "name": name,
                "handle": handle,
                "avatar_url": follower.get("avatar_url", ""),
            })

    return followers


@router.get("/users/{user_email}/following")
async def get_following(user_email: str, limit: int = 50):
    user_email = user_email.lower().strip()

    cursor = friends_col.find({
        "from_email": user_email,
        "status": "accepted"
    }).sort("created_at", -1).limit(limit)

    docs = await cursor.to_list(limit)

    following = []
    for doc in docs:
        followed = await users_col.find_one({"email": doc["to_email"]}, {"password_hash": 0})
        if followed:
            name = f"{followed.get('first_name', '')} {followed.get('last_name', '')}".strip()
            handle = f"{followed.get('username', followed.get('first_name', 'User'))}#{followed.get('tag', '0000')}"
            following.append({
                "email": followed["email"],
                "name": name,
                "handle": handle,
                "avatar_url": followed.get("avatar_url", ""),
            })

    return following


# ===================== ACTIVITY FEED =====================

@router.get("/users/{user_email}/activity")
async def get_user_activity(user_email: str, limit: int = 20):
    user_email = user_email.lower().strip()

    activities = []

    posts_cursor = posts_col.find({"user_email": user_email}).sort("created_at", -1).limit(limit)
    async for post in posts_cursor:
        activities.append({
            "type": "post",
            "id": str(post["_id"]),
            "content": f"Reviewed {post.get('restaurant_name', 'a restaurant')}",
            "rating": post.get("rating", 0),
            "created_at": post.get("created_at", ""),
        })

    activities.sort(key=lambda x: x.get("created_at", ""), reverse=True)
    return activities[:limit]


# ===================== RESTAURANT SEARCH FILTERS =====================

@router.get("/restaurants/advanced-search")
async def advanced_search_restaurants(
    q: Optional[str] = Query(default=None),
    cuisine: Optional[str] = Query(default=None),
    min_rating: Optional[float] = Query(default=None),
    max_price: Optional[str] = Query(default=None),
    limit: int = 20,
):
    query = {}

    if q:
        query["name"] = {"$regex": q, "$options": "i"}
    if cuisine:
        query["cuisine"] = {"$regex": cuisine, "$options": "i"}
    if min_rating:
        query["rating"] = {"$gte": min_rating}

    cursor = restaurants_col.find(query).limit(limit)
    docs = await cursor.to_list(limit)

    results = []
    for doc in docs:
        results.append({
            "id": str(doc["_id"]),
            "name": doc.get("name"),
            "cuisine": doc.get("cuisine"),
            "address": doc.get("address"),
            "phone": doc.get("phone"),
            "lat": doc.get("lat"),
            "lng": doc.get("lng"),
            "imageUrl": doc.get("imageUrl", ""),
            "rating": doc.get("rating", 0),
            "createdAt": doc.get("createdAt"),
        })

    return results