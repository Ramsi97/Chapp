"""MongoDB connection (Motor) and index setup."""
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from .config import settings

_client: AsyncIOMotorClient | None = None
_db: AsyncIOMotorDatabase | None = None


async def connect_to_mongo() -> None:
    global _client, _db
    # tz_aware so datetimes come back as timezone-aware UTC values.
    _client = AsyncIOMotorClient(settings.mongo_uri, tz_aware=True)
    _db = _client[settings.db_name]
    await ensure_indexes()


async def close_mongo_connection() -> None:
    global _client
    if _client is not None:
        _client.close()
        _client = None


def get_db() -> AsyncIOMotorDatabase:
    if _db is None:
        raise RuntimeError("Database not initialised. Call connect_to_mongo() first.")
    return _db


async def ensure_indexes() -> None:
    db = get_db()

    # Users: unique email + username (case-insensitive via *Lower fields).
    await db.users.create_index("emailLower", unique=True)
    await db.users.create_index("usernameLower", unique=True, sparse=True)

    # Chats: chat-list query (participant + recency) and direct-chat dedupe.
    await db.chats.create_index([("participants", 1), ("lastMessageAt", -1)])
    await db.chats.create_index("directKey", unique=True, sparse=True)

    # Messages: per-chat ordered fetch.
    await db.messages.create_index([("chatId", 1), ("sentAt", 1)])

    # Device tokens (push): one row per token.
    await db.device_tokens.create_index("token", unique=True)
    await db.device_tokens.create_index("userId")
