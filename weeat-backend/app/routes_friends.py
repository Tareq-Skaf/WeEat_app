from fastapi import APIRouter, HTTPException, Query
from bson import ObjectId
from datetime import datetime

from .db import friends_col, users_col

router = APIRouter(prefix="/friends", tags=["friends"])


def serialize_friend(doc: dict) -> dict:
    return {
        "id": str(doc["_id"]),
        "from_email": doc.get("from_email", ""),
        "to_email": doc.get("to_email", ""),
        "from_name": doc.get("from_name", ""),
        "from_handle": doc.get("from_handle", ""),
        "to_name": doc.get("to_name", ""),
        "to_handle": doc.get("to_handle", ""),
        "status": doc.get("status", "pending"),
        "created_at": doc.get("created_at", ""),
    }


async def get_user_info(email: str) -> dict:
    """Get user info for display"""
    user = await users_col.find_one({"email": email.lower().strip()})
    if not user:
        return {"name": "Unknown User", "handle": "@unknown"}
    
    name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
    handle = f"{user.get('username', user.get('first_name', 'User'))}#{user.get('tag', '0000')}"
    return {"name": name, "handle": handle}


@router.post("/request")
async def send_friend_request(payload: dict):
    """Send a friend request"""
    from_email = payload.get("from_email", "").lower().strip()
    to_email = payload.get("to_email", "").lower().strip()
    
    if not from_email:
        raise HTTPException(status_code=400, detail="from_email is required")
    if not to_email:
        raise HTTPException(status_code=400, detail="to_email is required")
    
    if from_email == to_email:
        raise HTTPException(status_code=400, detail="Cannot send friend request to yourself")
    
    # Check if users exist
    from_user = await users_col.find_one({"email": from_email})
    to_user = await users_col.find_one({"email": to_email})
    
    if not from_user:
        raise HTTPException(status_code=404, detail="From user not found")
    if not to_user:
        raise HTTPException(status_code=404, detail="To user not found")
    
    # Check if request already exists (pending or accepted)
    existing = await friends_col.find_one({
        "$or": [
            {"from_email": from_email, "to_email": to_email},
            {"from_email": to_email, "to_email": from_email},
        ]
    })
    
    if existing:
        status = existing.get("status", "")
        if status == "accepted":
            raise HTTPException(status_code=400, detail="Already friends")
        elif status == "pending":
            # Check who sent the original request
            if existing.get("from_email") == from_email:
                raise HTTPException(status_code=400, detail="Request already sent")
            else:
                # Accept the pending request
                await friends_col.update_one(
                    {"_id": existing["_id"]},
                    {"$set": {"status": "accepted"}}
                )
                return {"ok": True, "message": "Friend request accepted"}
    
    from_info = await get_user_info(from_email)
    to_info = await get_user_info(to_email)
    
    doc = {
        "from_email": from_email,
        "to_email": to_email,
        "from_name": from_info["name"],
        "from_handle": from_info["handle"],
        "to_name": to_info["name"],
        "to_handle": to_info["handle"],
        "status": "pending",
        "created_at": datetime.utcnow().isoformat(),
    }
    
    result = await friends_col.insert_one(doc)
    doc["_id"] = result.inserted_id
    
    return {"ok": True, "message": "Friend request sent", "friend": serialize_friend(doc)}


@router.post("/accept")
async def accept_friend_request(payload: dict):
    """Accept a friend request"""
    from_email = payload.get("from_email", "").lower().strip()
    to_email = payload.get("to_email", "").lower().strip()
    
    if not from_email or not to_email:
        raise HTTPException(status_code=400, detail="from_email and to_email are required")
    
    # Find pending request
    request = await friends_col.find_one({
        "from_email": from_email,
        "to_email": to_email,
        "status": "pending"
    })
    
    if not request:
        raise HTTPException(status_code=404, detail="Friend request not found")
    
    await friends_col.update_one(
        {"_id": request["_id"]},
        {"$set": {"status": "accepted"}}
    )
    
    return {"ok": True, "message": "Friend request accepted"}


@router.post("/decline")
async def decline_friend_request(payload: dict):
    """Decline a friend request"""
    from_email = payload.get("from_email", "").lower().strip()
    to_email = payload.get("to_email", "").lower().strip()
    
    if not from_email or not to_email:
        raise HTTPException(status_code=400, detail="from_email and to_email are required")
    
    # Find and delete pending request
    result = await friends_col.delete_one({
        "from_email": from_email,
        "to_email": to_email,
        "status": "pending"
    })
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Friend request not found")
    
    return {"ok": True, "message": "Friend request declined"}


@router.get("/requests")
async def get_pending_requests(email: str = Query(...)):
    """Get pending friend requests for a user"""
    email = email.lower().strip()
    
    # Get requests where user is the recipient
    cursor = friends_col.find({
        "to_email": email,
        "status": "pending"
    }).sort("created_at", -1)
    
    docs = await cursor.to_list(length=50)
    
    return [serialize_friend(d) for d in docs]


@router.get("")
async def get_friends(email: str = Query(...)):
    """Get user's friends list"""
    email = email.lower().strip()
    
    # Get accepted friendships where user is either party
    cursor = friends_col.find({
        "$or": [
            {"from_email": email, "status": "accepted"},
            {"to_email": email, "status": "accepted"},
        ]
    }).sort("created_at", -1)
    
    docs = await cursor.to_list(length=100)
    
    friends = []
    for doc in docs:
        friend = serialize_friend(doc)
        # Determine which user is the "friend" (not the current user)
        if doc.get("from_email") == email:
            friend["friend_name"] = doc.get("to_name", "")
            friend["friend_handle"] = doc.get("to_handle", "")
            friend["friend_email"] = doc.get("to_email", "")
        else:
            friend["friend_name"] = doc.get("from_name", "")
            friend["friend_handle"] = doc.get("from_handle", "")
            friend["friend_email"] = doc.get("from_email", "")
        friends.append(friend)
    
    return friends


@router.delete("")
async def remove_friend(payload: dict):
    """Remove a friend"""
    email = payload.get("email", "").lower().strip()
    friend_email = payload.get("friend_email", "").lower().strip()
    
    if not email or not friend_email:
        raise HTTPException(status_code=400, detail="email and friend_email are required")
    
    result = await friends_col.delete_one({
        "$or": [
            {"from_email": email, "to_email": friend_email, "status": "accepted"},
            {"from_email": friend_email, "to_email": email, "status": "accepted"},
        ]
    })
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Friend not found")
    
    return {"ok": True, "message": "Friend removed"}


@router.get("/status")
async def get_friendship_status(email: str = Query(...), other_email: str = Query(...)):
    """Check friendship status between two users"""
    email = email.lower().strip()
    other_email = other_email.lower().strip()
    
    friendship = await friends_col.find_one({
        "$or": [
            {"from_email": email, "to_email": other_email},
            {"from_email": other_email, "to_email": email},
        ]
    })
    
    if not friendship:
        return {"status": "none"}
    
    status = friendship.get("status", "pending")
    
    # Determine if current user sent the request
    is_sent_by_me = friendship.get("from_email") == email
    
    return {
        "status": status,
        "is_sent_by_me": is_sent_by_me,
    }


@router.get("/suggestions")
async def get_suggested_users(email: str = Query(...), limit: int = 10):
    """Get suggested users to follow (not friends yet)"""
    email = email.lower().strip()
    
    # Get current friends (both pending and accepted)
    existing = await friends_col.find({
        "$or": [
            {"from_email": email},
            {"to_email": email},
        ]
    }).to_list(length=500)
    
    # Build list of emails to exclude
    exclude_emails = {email}  # Exclude self
    for f in existing:
        exclude_emails.add(f.get("from_email", ""))
        exclude_emails.add(f.get("to_email", ""))
    
    # Find users not in exclusion list
    cursor = users_col.find({
        "email": {"$nin": list(exclude_emails)}
    }).limit(limit)
    
    docs = await cursor.to_list(length=limit)
    
    suggestions = []
    for user in docs:
        suggestions.append({
            "email": user.get("email", ""),
            "name": f"{user.get('first_name', '')} {user.get('last_name', '')}".strip(),
            "handle": f"{user.get('username', user.get('first_name', 'User'))}#{user.get('tag', '0000')}",
            "username": user.get("username"),
        })
    
    return suggestions
