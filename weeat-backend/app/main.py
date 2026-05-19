from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .db import users_col, restaurants_col, db
from .routes_auth import router as auth_router
from .routes_users import router as users_router
from .routes_wishlist import router as wishlist_router
from .routes_restaurants import router as restaurants_router
from .routes_posts import router as posts_router
from .routes_likes import router as likes_router
from .routes_plans import router as plans_router
from .routes_comments import router as comments_router
from .routes_friends import router as friends_router
from .routes_messages import router as messages_router
from .routes_features import router as features_router
from .routes_admin import router as admin_router
from .routes_foursquare import router as foursquare_router
from .routes_ip import router as ip_router
from .routes_directions import router as directions_router
from .routes_recommendations import router as recommendations_router
from .routes_chatbot import router as chatbot_router
from .routes_menus import router as menus_router

app = FastAPI(title="WeEat API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ok for dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_indexes():
    # 1) email unique
    await users_col.create_index("email", unique=True)

    # 2) username unique (sparse allows many docs to have username=None)
    await users_col.create_index("username", unique=True, sparse=True)

    # 3) identity_key + tag must be unique WHEN both exist
    await users_col.create_index(
        [("identity_key", 1), ("tag", 1)],
        unique=True,
        name="identity_key_1_tag_1",
        partialFilterExpression={
            "identity_key": {"$type": "string"},
            "tag": {"$type": "string"},
        },
    )

    # Conversations indexes
    conversations_col = db["conversations"]
    await conversations_col.create_index("participants")
    await conversations_col.create_index("last_message_time")

    # Messages indexes
    messages_col = db["messages"]
    await messages_col.create_index("conversation_id")
    await messages_col.create_index("timestamp")

    print("Database indexes created successfully")

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(wishlist_router)
app.include_router(restaurants_router)
app.include_router(posts_router)
app.include_router(likes_router)
app.include_router(plans_router)
app.include_router(comments_router)
app.include_router(friends_router)
app.include_router(messages_router)
app.include_router(features_router)
app.include_router(admin_router)
app.include_router(foursquare_router)
app.include_router(ip_router)
app.include_router(directions_router)
app.include_router(chatbot_router)
app.include_router(recommendations_router)
app.include_router(menus_router)

@app.get("/health")
def health():
    return {"ok": True}
