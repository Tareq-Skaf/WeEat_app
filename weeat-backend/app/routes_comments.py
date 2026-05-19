from fastapi import APIRouter, HTTPException, Query
from bson import ObjectId
from datetime import datetime

from .db import comments_col, users_col, posts_col

router = APIRouter(prefix="/comments", tags=["comments"])


def serialize_comment(doc: dict) -> dict:
    return {
        "id": str(doc["_id"]),
        "post_id": doc.get("post_id", ""),
        "user_email": doc.get("user_email", ""),
        "user_name": doc.get("user_name", ""),
        "user_handle": doc.get("user_handle", ""),
        "content": doc.get("content", ""),
        "created_at": doc.get("created_at", ""),
    }


@router.get("/post/{post_id}")
async def get_post_comments(post_id: str):
    """Get all comments for a post"""
    if not ObjectId.is_valid(post_id):
        raise HTTPException(status_code=400, detail="Invalid post_id")
    
    cursor = comments_col.find({"post_id": post_id}).sort("created_at", -1)
    docs = await cursor.to_list(length=100)
    
    return [serialize_comment(d) for d in docs]


@router.post("/post/{post_id}")
async def add_comment(post_id: str, payload: dict):
    """Add a comment to a post"""
    if not ObjectId.is_valid(post_id):
        raise HTTPException(status_code=400, detail="Invalid post_id")
    
    user_email = payload.get("user_email", "").lower().strip()
    content = payload.get("content", "").strip()
    
    if not user_email:
        raise HTTPException(status_code=400, detail="user_email is required")
    if not content:
        raise HTTPException(status_code=400, detail="content is required")
    
    # Verify user exists
    user = await users_col.find_one({"email": user_email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Verify post exists
    post = await posts_col.find_one({"_id": ObjectId(post_id)})
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    user_name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
    user_handle = f"{user.get('username', user.get('first_name', 'User'))}#{user.get('tag', '0000')}"
    
    doc = {
        "post_id": post_id,
        "user_email": user_email,
        "user_name": user_name,
        "user_handle": user_handle,
        "content": content,
        "created_at": datetime.utcnow().isoformat(),
    }
    
    result = await comments_col.insert_one(doc)
    doc["_id"] = result.inserted_id
    
    return serialize_comment(doc)


@router.delete("/{comment_id}")
async def delete_comment(comment_id: str, email: str):
    """Delete a comment (only by the author)"""
    if not ObjectId.is_valid(comment_id):
        raise HTTPException(status_code=400, detail="Invalid comment_id")
    
    email = email.lower().strip()
    
    comment = await comments_col.find_one({"_id": ObjectId(comment_id)})
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    
    if comment.get("user_email", "").lower().strip() != email:
        raise HTTPException(status_code=403, detail="Not authorized to delete this comment")
    
    await comments_col.delete_one({"_id": ObjectId(comment_id)})
    
    return {"ok": True, "message": "Comment deleted"}


@router.get("/post/{post_id}/count")
async def get_comment_count(post_id: str):
    """Get comment count for a post"""
    if not ObjectId.is_valid(post_id):
        raise HTTPException(status_code=400, detail="Invalid post_id")
    
    count = await comments_col.count_documents({"post_id": post_id})
    return {"count": count}
