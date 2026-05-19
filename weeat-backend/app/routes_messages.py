from fastapi import APIRouter, HTTPException, Query, WebSocket, WebSocketDisconnect
from bson import ObjectId
from datetime import datetime, timedelta
from typing import Optional, List
from pydantic import BaseModel

from .db import db, users_col, friends_col, plans_col

router = APIRouter(tags=["messages"])

conversations_col = db["conversations"]
messages_col = db["messages"]
stories_col = db["stories"]
polls_col = db["polls"]
blocked_col = db["blocked_users"]
notifications_col = db["notifications"]

connected_clients = {}


class CreateConversationRequest(BaseModel):
    from_email: str
    to_email: str


class CreateGroupRequest(BaseModel):
    creator_email: str
    group_name: str
    member_emails: List[str]


class SendMessageRequest(BaseModel):
    sender_email: str
    content: str
    message_type: str = "text"
    reply_to: Optional[str] = None
    extra_data: Optional[dict] = None


class MarkReadRequest(BaseModel):
    email: str


class ReactionRequest(BaseModel):
    email: str
    emoji: str


class PollCreateRequest(BaseModel):
    sender_email: str
    question: str
    options: List[str]
    date: Optional[str] = None
    time: Optional[str] = None
    restaurant_name: Optional[str] = None


class PollVoteRequest(BaseModel):
    email: str
    option_index: int


class StoryCreateRequest(BaseModel):
    email: str
    content: str
    story_type: str = "text"
    extra_data: Optional[dict] = None


class BlockRequest(BaseModel):
    email: str
    blocked_email: str


class PinRequest(BaseModel):
    email: str


class MuteRequest(BaseModel):
    email: str


def serialize_conversation(doc, current_email):
    participants = doc.get("participants", [])
    other_email = None
    for p in participants:
        if p != current_email:
            other_email = p
            break

    pinned_by = doc.get("pinned_by", [])
    muted_by = doc.get("muted_by", [])

    result = {
        "id": str(doc["_id"]),
        "is_group": doc.get("is_group", False),
        "group_name": doc.get("group_name", ""),
        "group_icon": doc.get("group_icon", ""),
        "creator_email": doc.get("creator_email", ""),
        "last_message": doc.get("last_message", ""),
        "last_message_time": doc.get("last_message_time", ""),
        "last_message_type": doc.get("last_message_type", "text"),
        "last_message_sender": doc.get("last_message_sender", ""),
        "unread_count": doc.get("unread_count", {}).get(current_email, 0),
        "is_pinned": current_email in pinned_by,
        "is_muted": current_email in muted_by,
        "created_at": doc.get("created_at", ""),
    }

    if doc.get("is_group"):
        result["name"] = doc.get("group_name", "Group")
        result["participants"] = participants
        result["participant_info"] = doc.get("participant_info", {})
    else:
        result["other_email"] = other_email or ""

    return result


def serialize_message(doc):
    reactions = doc.get("reactions", {})
    reaction_list = []
    for emoji, emails in reactions.items():
        reaction_list.append({"emoji": emoji, "count": len(emails), "users": emails})

    msg = {
        "id": str(doc["_id"]),
        "conversation_id": doc.get("conversation_id", ""),
        "sender_email": doc.get("sender_email", ""),
        "sender_name": doc.get("sender_name", ""),
        "sender_handle": doc.get("sender_handle", ""),
        "content": doc.get("content", ""),
        "message_type": doc.get("message_type", "text"),
        "extra_data": doc.get("extra_data", {}),
        "reply_to": doc.get("reply_to"),
        "reply_content": doc.get("reply_content", ""),
        "reply_sender": doc.get("reply_sender", ""),
        "reactions": reaction_list,
        "is_deleted": doc.get("is_deleted", False),
        "timestamp": doc.get("timestamp", ""),
        "read": doc.get("read", False),
        "read_by": doc.get("read_by", []),
    }
    return msg


async def get_user_display(email: str) -> dict:
    user = await users_col.find_one({"email": email})
    if not user:
        return {"name": "Unknown", "handle": "@unknown", "avatar_url": ""}
    name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
    handle = f"{user.get('username', user.get('first_name', 'User'))}#{user.get('tag', '0000')}"
    return {"name": name, "handle": handle, "avatar_url": user.get("avatar_url", "")}


async def enrich_conversation(doc, current_email):
    conv = serialize_conversation(doc, current_email)
    if not doc.get("is_group") and conv.get("other_email"):
        info = await get_user_display(conv["other_email"])
        conv["name"] = info["name"]
        conv["handle"] = info["handle"]
        conv["avatar_url"] = info["avatar_url"]
        conv["is_online"] = conv["other_email"] in connected_clients
    return conv


async def broadcast_to_participants(conversation_id: str, message: dict, exclude_email: str = None):
    try:
        conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
        if not conv:
            return
        for email in conv.get("participants", []):
            if email != exclude_email and email in connected_clients:
                try:
                    await connected_clients[email].send_json(message)
                except Exception:
                    connected_clients.pop(email, None)
    except Exception:
        pass


async def check_blocked(email1: str, email2: str) -> bool:
    blocked = await blocked_col.find_one({
        "$or": [
            {"blocker": email1, "blocked": email2},
            {"blocker": email2, "blocked": email1},
        ]
    })
    return blocked is not None


# ===================== CONVERSATIONS =====================

@router.get("/conversations")
async def get_conversations(email: str = Query(...)):
    email = email.lower().strip()
    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    cursor = conversations_col.find({"participants": email}).sort("last_message_time", -1)
    docs = await cursor.to_list(length=200)

    results = []
    for doc in docs:
        enriched = await enrich_conversation(doc, email)
        results.append(enriched)

    pinned = [c for c in results if c.get("is_pinned")]
    unpinned = [c for c in results if not c.get("is_pinned")]
    pinned.sort(key=lambda x: x.get("last_message_time", ""), reverse=True)
    unpinned.sort(key=lambda x: x.get("last_message_time", ""), reverse=True)

    return pinned + unpinned


@router.post("/conversations")
async def create_conversation(payload: CreateConversationRequest):
    from_email = payload.from_email.lower().strip()
    to_email = payload.to_email.lower().strip()

    if from_email == to_email:
        raise HTTPException(status_code=400, detail="Cannot create conversation with yourself")

    if await check_blocked(from_email, to_email):
        raise HTTPException(status_code=403, detail="Cannot create conversation with this user")

    from_user = await users_col.find_one({"email": from_email})
    to_user = await users_col.find_one({"email": to_email})
    if not from_user:
        raise HTTPException(status_code=404, detail="Sender not found")
    if not to_user:
        raise HTTPException(status_code=404, detail="Recipient not found")

    existing = await conversations_col.find_one({
        "is_group": False,
        "participants": {"$all": [from_email, to_email]},
        "$expr": {"$eq": [{"$size": "$participants"}, 2]}
    })

    if existing:
        enriched = await enrich_conversation(existing, from_email)
        return {"ok": True, "conversation": enriched, "created": False}

    from_info = await get_user_display(from_email)
    to_info = await get_user_display(to_email)

    doc = {
        "is_group": False,
        "group_name": "",
        "participants": [from_email, to_email],
        "participant_info": {
            from_email: from_info,
            to_email: to_info,
        },
        "last_message": "",
        "last_message_time": datetime.utcnow().isoformat(),
        "last_message_type": "text",
        "last_message_sender": "",
        "unread_count": {},
        "pinned_by": [],
        "muted_by": [],
        "created_at": datetime.utcnow().isoformat(),
    }

    result = await conversations_col.insert_one(doc)
    doc["_id"] = result.inserted_id

    enriched = await enrich_conversation(doc, from_email)
    return {"ok": True, "conversation": enriched, "created": True}


@router.post("/conversations/group")
async def create_group(payload: CreateGroupRequest):
    creator_email = payload.creator_email.lower().strip()
    group_name = payload.group_name.strip()
    member_emails = [e.lower().strip() for e in payload.member_emails]

    if not group_name:
        raise HTTPException(status_code=400, detail="Group name is required")
    if len(member_emails) < 2:
        raise HTTPException(status_code=400, detail="Group must have at least 2 members")

    all_emails = list(set([creator_email] + member_emails))

    for email in all_emails:
        user = await users_col.find_one({"email": email})
        if not user:
            raise HTTPException(status_code=404, detail=f"User {email} not found")

    participant_info = {}
    for email in all_emails:
        participant_info[email] = await get_user_display(email)

    doc = {
        "is_group": True,
        "group_name": group_name,
        "group_icon": "",
        "creator_email": creator_email,
        "participants": all_emails,
        "participant_info": participant_info,
        "last_message": "",
        "last_message_time": datetime.utcnow().isoformat(),
        "last_message_type": "text",
        "last_message_sender": "",
        "unread_count": {},
        "pinned_by": [],
        "muted_by": [],
        "created_at": datetime.utcnow().isoformat(),
    }

    result = await conversations_col.insert_one(doc)
    doc["_id"] = result.inserted_id

    enriched = await enrich_conversation(doc, creator_email)
    return {"ok": True, "conversation": enriched}


@router.get("/conversations/{conversation_id}")
async def get_conversation(conversation_id: str, email: str = Query(...)):
    email = email.lower().strip()
    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")
    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if email not in conv.get("participants", []):
        raise HTTPException(status_code=403, detail="Not a participant")
    enriched = await enrich_conversation(conv, email)
    return enriched


@router.put("/conversations/{conversation_id}/rename")
async def rename_group(conversation_id: str, payload: dict):
    email = payload.get("email", "").lower().strip()
    new_name = payload.get("name", "").strip()

    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")
    if not new_name:
        raise HTTPException(status_code=400, detail="Name is required")

    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if not conv.get("is_group"):
        raise HTTPException(status_code=400, detail="Not a group")
    if email not in conv.get("participants", []):
        raise HTTPException(status_code=403, detail="Not a participant")

    await conversations_col.update_one(
        {"_id": ObjectId(conversation_id)},
        {"$set": {"group_name": new_name}}
    )
    return {"ok": True}


# ===================== MESSAGES =====================

@router.get("/conversations/{conversation_id}/messages")
async def get_messages(conversation_id: str, email: str = Query(...), limit: int = 50, before: Optional[str] = None):
    email = email.lower().strip()

    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")

    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if email not in conv.get("participants", []):
        raise HTTPException(status_code=403, detail="Not a participant")

    unread = conv.get("unread_count", {})
    if email in unread:
        unread[email] = 0
        await conversations_col.update_one(
            {"_id": ObjectId(conversation_id)},
            {"$set": {"unread_count": unread}}
        )

    read_by = conv.get("read_by", [])
    if email not in read_by:
        read_by.append(email)
        await conversations_col.update_one(
            {"_id": ObjectId(conversation_id)},
            {"$set": {"read_by": read_by}}
        )

    query = {"conversation_id": conversation_id}
    if before:
        query["timestamp"] = {"$lt": before}

    cursor = messages_col.find(query).sort("timestamp", -1).limit(limit)
    docs = await cursor.to_list(length=limit)
    docs.reverse()

    return [serialize_message(d) for d in docs]


@router.post("/conversations/{conversation_id}/messages")
async def send_message(conversation_id: str, payload: SendMessageRequest):
    sender_email = payload.sender_email.lower().strip()
    content = payload.content.strip()
    message_type = payload.message_type or "text"

    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")
    if not content and message_type == "text":
        raise HTTPException(status_code=400, detail="Content is required")

    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if sender_email not in conv.get("participants", []):
        raise HTTPException(status_code=403, detail="Not a participant")

    for p in conv.get("participants", []):
        if p != sender_email and await check_blocked(sender_email, p):
            raise HTTPException(status_code=403, detail="Cannot send message to this user")

    sender_info = await get_user_display(sender_email)

    unread = conv.get("unread_count", {})
    for p in conv.get("participants", []):
        if p != sender_email:
            unread[p] = unread.get(p, 0) + 1

    reply_content = ""
    reply_sender = ""
    if payload.reply_to:
        reply_msg = await messages_col.find_one({"_id": ObjectId(payload.reply_to)})
        if reply_msg:
            reply_content = reply_msg.get("content", "")
            reply_sender = reply_msg.get("sender_name", "")

    doc = {
        "conversation_id": conversation_id,
        "sender_email": sender_email,
        "sender_name": sender_info["name"],
        "sender_handle": sender_info["handle"],
        "content": content,
        "message_type": message_type,
        "extra_data": payload.extra_data or {},
        "reply_to": payload.reply_to,
        "reply_content": reply_content,
        "reply_sender": reply_sender,
        "reactions": {},
        "is_deleted": False,
        "timestamp": datetime.utcnow().isoformat(),
        "read": False,
        "read_by": [sender_email],
    }

    result = await messages_col.insert_one(doc)
    doc["_id"] = result.inserted_id

    last_msg_display = content
    if message_type == "image":
        last_msg_display = "Photo"
    elif message_type == "restaurant":
        last_msg_display = "Shared a restaurant"
    elif message_type == "post":
        last_msg_display = "Shared a post"
    elif message_type == "location":
        last_msg_display = "Location"
    elif message_type == "poll":
        last_msg_display = "Poll"

    await conversations_col.update_one(
        {"_id": ObjectId(conversation_id)},
        {"$set": {
            "last_message": last_msg_display,
            "last_message_time": doc["timestamp"],
            "last_message_type": message_type,
            "last_message_sender": sender_info["name"],
            "unread_count": unread,
            "read_by": [sender_email],
        }}
    )

    msg_data = serialize_message(doc)
    msg_data["conversation_id"] = conversation_id
    await broadcast_to_participants(conversation_id, {"type": "new_message", "message": msg_data}, exclude_email=sender_email)

    return {"ok": True, "message": msg_data}


@router.put("/conversations/{conversation_id}/messages/{message_id}")
async def delete_message(conversation_id: str, message_id: str, payload: dict):
    email = payload.get("email", "").lower().strip()

    if not ObjectId.is_valid(message_id):
        raise HTTPException(status_code=400, detail="Invalid message id")

    msg = await messages_col.find_one({"_id": ObjectId(message_id)})
    if not msg:
        raise HTTPException(status_code=404, detail="Message not found")
    if msg.get("sender_email") != email:
        raise HTTPException(status_code=403, detail="Can only delete your own messages")

    await messages_col.update_one(
        {"_id": ObjectId(message_id)},
        {"$set": {"is_deleted": True, "content": "This message was deleted"}}
    )

    await broadcast_to_participants(conversation_id, {
        "type": "message_deleted",
        "message_id": message_id,
        "conversation_id": conversation_id,
    })

    return {"ok": True}


@router.post("/conversations/{conversation_id}/messages/{message_id}/reactions")
async def add_reaction(conversation_id: str, message_id: str, payload: ReactionRequest):
    email = payload.email.lower().strip()
    emoji = payload.emoji

    if not ObjectId.is_valid(message_id):
        raise HTTPException(status_code=400, detail="Invalid message id")

    msg = await messages_col.find_one({"_id": ObjectId(message_id)})
    if not msg:
        raise HTTPException(status_code=404, detail="Message not found")

    reactions = msg.get("reactions", {})

    if emoji not in reactions:
        reactions[emoji] = []

    if email in reactions[emoji]:
        reactions[emoji].remove(email)
        if not reactions[emoji]:
            del reactions[emoji]
    else:
        reactions[emoji].append(email)

    await messages_col.update_one(
        {"_id": ObjectId(message_id)},
        {"$set": {"reactions": reactions}}
    )

    reaction_list = []
    for e, emails in reactions.items():
        reaction_list.append({"emoji": e, "count": len(emails), "users": emails})

    await broadcast_to_participants(conversation_id, {
        "type": "reaction_updated",
        "message_id": message_id,
        "conversation_id": conversation_id,
        "reactions": reaction_list,
    })

    return {"ok": True, "reactions": reaction_list}


# ===================== READ RECEIPTS =====================

@router.put("/conversations/{conversation_id}/read")
async def mark_conversation_read(conversation_id: str, payload: MarkReadRequest):
    email = payload.email.lower().strip()

    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")

    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")

    unread = conv.get("unread_count", {})
    unread[email] = 0

    read_by = conv.get("read_by", [])
    if email not in read_by:
        read_by.append(email)

    await conversations_col.update_one(
        {"_id": ObjectId(conversation_id)},
        {"$set": {"unread_count": unread, "read_by": read_by}}
    )

    await broadcast_to_participants(conversation_id, {
        "type": "messages_read",
        "conversation_id": conversation_id,
        "reader_email": email,
    }, exclude_email=email)

    return {"ok": True}


# ===================== PIN / MUTE =====================

@router.put("/conversations/{conversation_id}/pin")
async def toggle_pin(conversation_id: str, payload: PinRequest):
    email = payload.email.lower().strip()

    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")

    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")

    pinned_by = conv.get("pinned_by", [])
    if email in pinned_by:
        pinned_by.remove(email)
    else:
        pinned_by.append(email)

    await conversations_col.update_one(
        {"_id": ObjectId(conversation_id)},
        {"$set": {"pinned_by": pinned_by}}
    )

    return {"ok": True, "is_pinned": email in pinned_by}


@router.put("/conversations/{conversation_id}/mute")
async def toggle_mute(conversation_id: str, payload: MuteRequest):
    email = payload.email.lower().strip()

    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")

    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")

    muted_by = conv.get("muted_by", [])
    if email in muted_by:
        muted_by.remove(email)
    else:
        muted_by.append(email)

    await conversations_col.update_one(
        {"_id": ObjectId(conversation_id)},
        {"$set": {"muted_by": muted_by}}
    )

    return {"ok": True, "is_muted": email in muted_by}


# ===================== BLOCK =====================

@router.post("/block")
async def block_user(payload: BlockRequest):
    email = payload.email.lower().strip()
    blocked_email = payload.blocked_email.lower().strip()

    if email == blocked_email:
        raise HTTPException(status_code=400, detail="Cannot block yourself")

    existing = await blocked_col.find_one({"blocker": email, "blocked": blocked_email})
    if existing:
        await blocked_col.delete_one({"_id": existing["_id"]})
        return {"ok": True, "blocked": False}

    await blocked_col.insert_one({
        "blocker": email,
        "blocked": blocked_email,
        "created_at": datetime.utcnow().isoformat(),
    })

    return {"ok": True, "blocked": True}


@router.get("/blocked")
async def get_blocked(email: str = Query(...)):
    email = email.lower().strip()
    cursor = blocked_col.find({"blocker": email})
    docs = await cursor.to_list(length=100)
    return [{"blocked": d.get("blocked", ""), "created_at": d.get("created_at", "")} for d in docs]


# ===================== GROUP MEMBERS =====================

@router.post("/conversations/{conversation_id}/members")
async def add_group_member(conversation_id: str, payload: dict):
    email = payload.get("email", "").lower().strip()
    member_email = payload.get("member_email", "").lower().strip()

    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")

    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if not conv.get("is_group"):
        raise HTTPException(status_code=400, detail="Not a group conversation")
    if email not in conv.get("participants", []):
        raise HTTPException(status_code=403, detail="Not a participant")

    if member_email in conv.get("participants", []):
        raise HTTPException(status_code=400, detail="User already in group")

    member_user = await users_col.find_one({"email": member_email})
    if not member_user:
        raise HTTPException(status_code=404, detail="User not found")

    member_info = await get_user_display(member_email)
    participants = conv.get("participants", [])
    participants.append(member_email)
    participant_info = conv.get("participant_info", {})
    participant_info[member_email] = member_info

    await conversations_col.update_one(
        {"_id": ObjectId(conversation_id)},
        {"$set": {"participants": participants, "participant_info": participant_info}}
    )

    return {"ok": True, "message": f"Added {member_email} to group"}


@router.delete("/conversations/{conversation_id}/members/{member_email}")
async def remove_group_member(conversation_id: str, member_email: str, email: str = Query(...)):
    email = email.lower().strip()
    member_email = member_email.lower().strip()

    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")

    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if not conv.get("is_group"):
        raise HTTPException(status_code=400, detail="Not a group conversation")

    participants = conv.get("participants", [])
    if member_email not in participants:
        raise HTTPException(status_code=404, detail="User not in group")

    participants.remove(member_email)
    participant_info = conv.get("participant_info", {})
    participant_info.pop(member_email, None)

    await conversations_col.update_one(
        {"_id": ObjectId(conversation_id)},
        {"$set": {"participants": participants, "participant_info": participant_info}}
    )

    return {"ok": True, "message": f"Removed {member_email} from group"}


# ===================== POLLS =====================

@router.post("/conversations/{conversation_id}/polls")
async def create_poll(conversation_id: str, payload: PollCreateRequest):
    sender_email = payload.sender_email.lower().strip()

    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")
    if not payload.question.strip():
        raise HTTPException(status_code=400, detail="Question is required")
    if len(payload.options) < 2:
        raise HTTPException(status_code=400, detail="At least 2 options required")

    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")

    sender_info = await get_user_display(sender_email)

    poll_doc = {
        "conversation_id": conversation_id,
        "creator_email": sender_email,
        "question": payload.question.strip(),
        "options": [{"text": o.strip(), "votes": []} for o in payload.options],
        "created_at": datetime.utcnow().isoformat(),
        "is_active": True,
        "date": payload.date,
        "time": payload.time,
        "restaurant_name": payload.restaurant_name,
    }

    poll_result = await polls_col.insert_one(poll_doc)
    poll_id = str(poll_result.inserted_id)

    msg_doc = {
        "conversation_id": conversation_id,
        "sender_email": sender_email,
        "sender_name": sender_info["name"],
        "sender_handle": sender_info["handle"],
        "content": payload.question.strip(),
        "message_type": "poll",
        "extra_data": {"poll_id": poll_id},
        "reply_to": None,
        "reply_content": "",
        "reply_sender": "",
        "reactions": {},
        "is_deleted": False,
        "timestamp": datetime.utcnow().isoformat(),
        "read": False,
        "read_by": [sender_email],
    }

    msg_result = await messages_col.insert_one(msg_doc)
    msg_doc["_id"] = msg_result.inserted_id

    unread = conv.get("unread_count", {})
    for p in conv.get("participants", []):
        if p != sender_email:
            unread[p] = unread.get(p, 0) + 1

    await conversations_col.update_one(
        {"_id": ObjectId(conversation_id)},
        {"$set": {
            "last_message": "Poll",
            "last_message_time": msg_doc["timestamp"],
            "last_message_type": "poll",
            "last_message_sender": sender_info["name"],
            "unread_count": unread,
        }}
    )

    msg_data = serialize_message(msg_doc)
    msg_data["poll"] = {
        "id": poll_id,
        "question": payload.question.strip(),
        "options": [{"text": o.strip(), "votes": [], "count": 0} for o in payload.options],
        "total_votes": 0,
        "is_active": True,
        "date": payload.date,
        "time": payload.time,
        "restaurant_name": payload.restaurant_name,
        "creator_email": sender_email,
    }

    await broadcast_to_participants(conversation_id, {"type": "new_message", "message": msg_data}, exclude_email=sender_email)

    return {"ok": True, "message": msg_data, "poll_id": poll_id}


@router.post("/polls/{poll_id}/vote")
async def vote_poll(poll_id: str, payload: PollVoteRequest):
    email = payload.email.lower().strip()

    if not ObjectId.is_valid(poll_id):
        raise HTTPException(status_code=400, detail="Invalid poll id")

    poll = await polls_col.find_one({"_id": ObjectId(poll_id)})
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    if not poll.get("is_active"):
        raise HTTPException(status_code=400, detail="Poll is closed")

    options = poll.get("options", [])
    if payload.option_index < 0 or payload.option_index >= len(options):
        raise HTTPException(status_code=400, detail="Invalid option index")

    for opt in options:
        if email in opt.get("votes", []):
            opt["votes"].remove(email)

    options[payload.option_index]["votes"].append(email)

    await polls_col.update_one(
        {"_id": ObjectId(poll_id)},
        {"$set": {"options": options}}
    )

    result_options = []
    total_votes = 0
    for opt in options:
        votes = opt.get("votes", [])
        total_votes += len(votes)
        result_options.append({"text": opt["text"], "votes": votes, "count": len(votes)})

    conversation_id = poll.get("conversation_id", "")
    await broadcast_to_participants(conversation_id, {
        "type": "poll_updated",
        "poll_id": poll_id,
        "conversation_id": conversation_id,
        "options": result_options,
        "total_votes": total_votes,
    })

    return {"ok": True, "options": result_options, "total_votes": total_votes}


@router.post("/polls/{poll_id}/close")
async def close_poll(poll_id: str, payload: dict):
    email = payload.get("email", "").lower().strip()

    if not ObjectId.is_valid(poll_id):
        raise HTTPException(status_code=400, detail="Invalid poll id")

    poll = await polls_col.find_one({"_id": ObjectId(poll_id)})
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")
    if poll.get("creator_email") != email:
        raise HTTPException(status_code=403, detail="Only creator can close poll")

    await polls_col.update_one(
        {"_id": ObjectId(poll_id)},
        {"$set": {"is_active": False}}
    )

    return {"ok": True}


@router.get("/polls/{poll_id}")
async def get_poll(poll_id: str):
    if not ObjectId.is_valid(poll_id):
        raise HTTPException(status_code=400, detail="Invalid poll id")

    poll = await polls_col.find_one({"_id": ObjectId(poll_id)})
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")

    options = poll.get("options", [])
    total_votes = sum(len(opt.get("votes", [])) for opt in options)

    result_options = []
    for opt in options:
        votes = opt.get("votes", [])
        result_options.append({"text": opt["text"], "votes": votes, "count": len(votes)})

    return {
        "id": str(poll["_id"]),
        "question": poll.get("question", ""),
        "options": result_options,
        "total_votes": total_votes,
        "is_active": poll.get("is_active", True),
        "creator_email": poll.get("creator_email", ""),
        "date": poll.get("date"),
        "time": poll.get("time"),
        "restaurant_name": poll.get("restaurant_name"),
    }


@router.post("/polls/{poll_id}/confirm")
async def confirm_poll(poll_id: str, payload: dict):
    """Confirm a poll plan: create calendar entries for all 'I'm In' voters."""
    email = payload.get("email", "").lower().strip()

    if not ObjectId.is_valid(poll_id):
        raise HTTPException(status_code=400, detail="Invalid poll id")

    poll = await polls_col.find_one({"_id": ObjectId(poll_id)})
    if not poll:
        raise HTTPException(status_code=404, detail="Poll not found")

    # Allow creator OR auto-trigger
    is_creator = poll.get("creator_email") == email
    if not is_creator and not payload.get("auto"):
        raise HTTPException(status_code=403, detail="Only creator can confirm")

    options = poll.get("options", [])
    if not options:
        raise HTTPException(status_code=400, detail="No options in poll")

    # "I'm In" is always option index 0
    going_votes = options[0].get("votes", []) if len(options) > 0 else []
    # Creator is always included
    if poll.get("creator_email") and poll.get("creator_email") not in going_votes:
        going_votes.append(poll.get("creator_email"))

    if not going_votes:
        raise HTTPException(status_code=400, detail="No one has confirmed yet")

    date_str = poll.get("date", "")
    time_str = poll.get("time", "")
    restaurant = poll.get("restaurant_name", "")
    question = poll.get("question", "")

    # Get creator name for notification
    creator_info = await get_user_display(poll.get("creator_email", email))
    creator_name = creator_info.get("name", "Someone")

    created_plans = 0
    for voter_email in going_votes:
        plan_doc = {
            "user_email": voter_email,
            "title": f"Plan: {restaurant}" if restaurant else "Confirmed Plan",
            "restaurant_name": restaurant,
            "date": date_str,
            "time": time_str,
            "notes": f"Group plan from poll: {question}",
            "created_at": datetime.utcnow().isoformat(),
            "poll_id": poll_id,
        }
        await plans_col.insert_one(plan_doc)
        created_plans += 1

        # Notify each voter
        await notifications_col.insert_one({
            "email": voter_email,
            "type": "poll_confirmed",
            "title": "Plan Confirmed!",
            "body": f"{creator_name} confirmed the plan! {restaurant} on {date_str} at {time_str} has been added to your Plans.",
            "is_read": False,
            "created_at": datetime.utcnow().isoformat(),
            "extra_data": {
                "poll_id": poll_id,
                "restaurant_name": restaurant,
                "date": date_str,
                "time": time_str,
                "creator_name": creator_name,
            },
        })

    # Close the poll automatically
    await polls_col.update_one(
        {"_id": ObjectId(poll_id)},
        {"$set": {"is_active": False, "confirmed_at": datetime.utcnow().isoformat()}}
    )

    return {
        "ok": True,
        "message": f"Plan confirmed for {len(going_votes)} people",
        "created_plans": created_plans,
    }


# ===================== STORIES =====================

@router.post("/stories")
async def create_story(payload: StoryCreateRequest):
    email = payload.email.lower().strip()
    content = payload.content.strip()

    if not content:
        raise HTTPException(status_code=400, detail="Content is required")

    user_info = await get_user_display(email)

    doc = {
        "email": email,
        "user_name": user_info["name"],
        "user_handle": user_info["handle"],
        "content": content,
        "story_type": payload.story_type or "text",
        "extra_data": payload.extra_data or {},
        "views": [],
        "created_at": datetime.utcnow().isoformat(),
        "expires_at": (datetime.utcnow() + timedelta(hours=24)).isoformat(),
    }

    result = await stories_col.insert_one(doc)
    doc["_id"] = result.inserted_id

    return {
        "ok": True,
        "story": {
            "id": str(doc["_id"]),
            "email": doc["email"],
            "user_name": doc["user_name"],
            "content": doc["content"],
            "story_type": doc["story_type"],
            "views": [],
            "created_at": doc["created_at"],
        }
    }


@router.get("/stories")
async def get_stories(email: str = Query(...)):
    email = email.lower().strip()

    friends_cursor = friends_col.find({
        "$or": [
            {"from_email": email, "status": "accepted"},
            {"to_email": email, "status": "accepted"},
        ]
    })
    friends_docs = await friends_cursor.to_list(length=500)

    friend_emails = set()
    for f in friends_docs:
        if f.get("from_email") == email:
            friend_emails.add(f.get("to_email"))
        else:
            friend_emails.add(f.get("from_email"))
    friend_emails.add(email)

    cursor = stories_col.find({"email": {"$in": list(friend_emails)}}).sort("created_at", -1).limit(50)
    docs = await cursor.to_list(length=50)

    grouped = {}
    for doc in docs:
        story_email = doc.get("email", "")
        if story_email not in grouped:
            user_info = await get_user_display(story_email)
            grouped[story_email] = {
                "email": story_email,
                "user_name": user_info["name"],
                "user_handle": user_info["handle"],
                "stories": [],
            }
        grouped[story_email]["stories"].append({
            "id": str(doc["_id"]),
            "content": doc.get("content", ""),
            "story_type": doc.get("story_type", "text"),
            "extra_data": doc.get("extra_data", {}),
            "views": doc.get("views", []),
            "created_at": doc.get("created_at", ""),
        })

    return list(grouped.values())


@router.post("/stories/{story_id}/view")
async def view_story(story_id: str, payload: dict):
    email = payload.get("email", "").lower().strip()

    if not ObjectId.is_valid(story_id):
        raise HTTPException(status_code=400, detail="Invalid story id")

    story = await stories_col.find_one({"_id": ObjectId(story_id)})
    if not story:
        raise HTTPException(status_code=404, detail="Story not found")

    views = story.get("views", [])
    if email not in views:
        views.append(email)
        await stories_col.update_one(
            {"_id": ObjectId(story_id)},
            {"$set": {"views": views}}
        )

    return {"ok": True}


# ===================== MESSAGE SEARCH =====================

@router.get("/conversations/{conversation_id}/search")
async def search_messages(conversation_id: str, q: str = Query(...), email: str = Query(...)):
    email = email.lower().strip()

    if not ObjectId.is_valid(conversation_id):
        raise HTTPException(status_code=400, detail="Invalid conversation id")

    conv = await conversations_col.find_one({"_id": ObjectId(conversation_id)})
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if email not in conv.get("participants", []):
        raise HTTPException(status_code=403, detail="Not a participant")

    query = {
        "conversation_id": conversation_id,
        "content": {"$regex": q, "$options": "i"},
        "is_deleted": {"$ne": True},
    }

    cursor = messages_col.find(query).sort("timestamp", -1).limit(20)
    docs = await cursor.to_list(length=20)

    return [serialize_message(d) for d in docs]


# ===================== WEBSOCKET =====================

@router.websocket("/ws/{email}")
async def websocket_endpoint(websocket: WebSocket, email: str):
    email = email.lower().strip()
    await websocket.accept()
    connected_clients[email] = websocket

    for conv_cursor in conversations_col.find({"participants": email}):
        for p in conv_cursor.get("participants", []):
            if p in connected_clients and p != email:
                try:
                    await connected_clients[p].send_json({"type": "user_online", "email": email})
                except Exception:
                    pass

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type", "")

            if msg_type == "send_message":
                conv_id = data.get("conversation_id")
                content = data.get("content", "").strip()
                message_type = data.get("message_type", "text")
                reply_to = data.get("reply_to")
                extra_data = data.get("extra_data")

                if conv_id and (content or message_type != "text"):
                    conv = await conversations_col.find_one({"_id": ObjectId(conv_id)})
                    if conv and email in conv.get("participants", []):
                        sender_info = await get_user_display(email)

                        unread = conv.get("unread_count", {})
                        for p in conv.get("participants", []):
                            if p != email:
                                unread[p] = unread.get(p, 0) + 1

                        reply_content = ""
                        reply_sender_name = ""
                        if reply_to:
                            reply_msg = await messages_col.find_one({"_id": ObjectId(reply_to)})
                            if reply_msg:
                                reply_content = reply_msg.get("content", "")
                                reply_sender_name = reply_msg.get("sender_name", "")

                        msg_doc = {
                            "conversation_id": conv_id,
                            "sender_email": email,
                            "sender_name": sender_info["name"],
                            "sender_handle": sender_info["handle"],
                            "content": content,
                            "message_type": message_type,
                            "extra_data": extra_data or {},
                            "reply_to": reply_to,
                            "reply_content": reply_content,
                            "reply_sender": reply_sender_name,
                            "reactions": {},
                            "is_deleted": False,
                            "timestamp": datetime.utcnow().isoformat(),
                            "read": False,
                            "read_by": [email],
                        }
                        result = await messages_col.insert_one(msg_doc)
                        msg_doc["_id"] = result.inserted_id

                        last_msg = content
                        if message_type == "image":
                            last_msg = "Photo"
                        elif message_type == "restaurant":
                            last_msg = "Shared a restaurant"
                        elif message_type == "post":
                            last_msg = "Shared a post"
                        elif message_type == "location":
                            last_msg = "Location"
                        elif message_type == "poll":
                            last_msg = "Poll"

                        await conversations_col.update_one(
                            {"_id": ObjectId(conv_id)},
                            {"$set": {
                                "last_message": last_msg,
                                "last_message_time": msg_doc["timestamp"],
                                "last_message_type": message_type,
                                "last_message_sender": sender_info["name"],
                                "unread_count": unread,
                            }}
                        )

                        msg_data = serialize_message(msg_doc)
                        msg_data["conversation_id"] = conv_id

                        for p in conv.get("participants", []):
                            if p in connected_clients:
                                try:
                                    await connected_clients[p].send_json({"type": "new_message", "message": msg_data})
                                except Exception:
                                    connected_clients.pop(p, None)

            elif msg_type == "typing":
                conv_id = data.get("conversation_id")
                if conv_id:
                    conv = await conversations_col.find_one({"_id": ObjectId(conv_id)})
                    if conv:
                        for p in conv.get("participants", []):
                            if p != email and p in connected_clients:
                                try:
                                    await connected_clients[p].send_json({
                                        "type": "typing",
                                        "conversation_id": conv_id,
                                        "email": email,
                                    })
                                except Exception:
                                    pass

            elif msg_type == "stop_typing":
                conv_id = data.get("conversation_id")
                if conv_id:
                    conv = await conversations_col.find_one({"_id": ObjectId(conv_id)})
                    if conv:
                        for p in conv.get("participants", []):
                            if p != email and p in connected_clients:
                                try:
                                    await connected_clients[p].send_json({
                                        "type": "stop_typing",
                                        "conversation_id": conv_id,
                                        "email": email,
                                    })
                                except Exception:
                                    pass

    except WebSocketDisconnect:
        connected_clients.pop(email, None)
        for conv_cursor in conversations_col.find({"participants": email}):
            for p in conv_cursor.get("participants", []):
                if p in connected_clients and p != email:
                    try:
                        await connected_clients[p].send_json({"type": "user_offline", "email": email})
                    except Exception:
                        pass
    except Exception:
        connected_clients.pop(email, None)