from pydantic import BaseModel, EmailStr
from typing import Optional

class RegisterIn(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    password: str
    username: Optional[str] = None


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class WishlistToggleRequest(BaseModel):
    email: EmailStr
    restaurant_id: str
