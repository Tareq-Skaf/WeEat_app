from fastapi import APIRouter, HTTPException
import bcrypt
from datetime import datetime

from .db import users_col
from .models import RegisterIn, LoginIn
from .utils_tags import make_4_digit_tag

router = APIRouter(prefix="/auth", tags=["auth"])


def _obj_id(x) -> str:
    return str(x)


def _make_display_name(first: str, last: str) -> str:
    name = f"{first.strip()} {last.strip()}".strip()
    return name if name else first.strip()


async def _generate_unique_tag(identity_key: str) -> str:
    # identity_key is NEVER null here
    for _ in range(300):
        tag = make_4_digit_tag()
        exists = await users_col.find_one(
            {"identity_key": identity_key, "tag": tag},
            {"_id": 1}
        )
        if not exists:
            return tag
    raise HTTPException(status_code=500, detail="Could not generate unique tag. Try again.")


@router.post("/register")
async def register(payload: RegisterIn):
    email = payload.email.lower().strip()

    # username optional
    username = payload.username.strip() if payload.username else ""
    username = username.lower() if username else None

    # email unique
    if await users_col.find_one({"email": email}, {"_id": 1}):
        raise HTTPException(status_code=400, detail="Email already registered")

    # username unique if provided
    if username:
        if await users_col.find_one({"username": username}, {"_id": 1}):
            raise HTTPException(status_code=400, detail="Username already taken")

    password_hash = bcrypt.hashpw(payload.password.encode(), bcrypt.gensalt()).decode()
    display_name = _make_display_name(payload.first_name, payload.last_name)

    # ✅ identity_key must NEVER be None
    identity_key = (username or payload.first_name).strip().lower()
    if not identity_key:
        identity_key = email  # super safe fallback

    tag = await _generate_unique_tag(identity_key)

    handle_base = username if username else payload.first_name.strip()
    if not handle_base:
        handle_base = email.split("@")[0]
    handle = f"{handle_base}#{tag}"

    doc = {
        "first_name": payload.first_name.strip(),
        "last_name": payload.last_name.strip(),
        "display_name": display_name,
        "email": email,
        "username": username,              # can be None
        "identity_key": identity_key,      # ✅ always string
        "tag": tag,                        # ✅ always string
        "handle": handle,
        "password_hash": password_hash,
        "wishlist_restaurant_ids": [],
        "created_at": datetime.utcnow(),
    }

    result = await users_col.insert_one(doc)

    return {
        "ok": True,
        "user_id": _obj_id(result.inserted_id),
        "email": doc["email"],
        "first_name": doc["first_name"],
        "last_name": doc["last_name"],
        "display_name": doc["display_name"],
        "username": doc["username"],
        "tag": doc["tag"],
        "handle": doc["handle"],
    }


@router.post("/login")
async def login(payload: LoginIn):
    email = payload.email.lower().strip()
    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not bcrypt.checkpw(payload.password.encode(), user.get("password_hash", "").encode()):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    return {
        "ok": True,
        "user_id": _obj_id(user["_id"]),
        "email": user["email"],
        "first_name": user.get("first_name", ""),
        "last_name": user.get("last_name", ""),
        "display_name": user.get("display_name", user.get("first_name", "")),
        "username": user.get("username"),
        "tag": user.get("tag", "0000"),
        "handle": user.get("handle", f'{user.get("first_name","User")}#{user.get("tag","0000")}'),
    }


@router.post("/reset-password")
async def reset_password(payload: dict):
    """
    Reset password using email and new password.
    Expects: {"email": "user@example.com", "new_password": "newpass123"}
    """
    email = payload.get("email", "").lower().strip()
    new_password = payload.get("new_password", "")

    if not email or not new_password:
        raise HTTPException(status_code=400, detail="Email and new_password are required")

    if len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    user = await users_col.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Hash the new password
    new_hash = bcrypt.hashpw(new_password.encode(), bcrypt.gensalt()).decode()

    # Update the password
    await users_col.update_one(
        {"_id": user["_id"]},
        {"$set": {"password_hash": new_hash}}
    )

    return {"ok": True, "message": "Password reset successfully"}