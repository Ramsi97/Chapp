"""Shared chat/message operations used by the chats and messages routers.

Keeps Mongo write shapes and the "publish after write" fan-out in one place so
direct/group chats and every message mutation behave consistently.
"""
from fastapi import HTTPException, status

from .db import get_db
from .models import chat_public, now_utc, oid
from .realtime import events
from .realtime.broker import broker


def direct_key(a: str, b: str) -> str:
    """Stable key for a direct chat between two users (order-independent)."""
    return "_".join(sorted([a, b]))


def message_preview(msg: dict) -> str:
    """Short text summary for chat-list previews and reply quotes."""
    t = msg.get("type", "text")
    if t == "image":
        return "📷 Photo"
    if t == "voice":
        return "🎤 Voice message"
    if t == "file":
        return msg.get("fileName") or "📎 File"
    return msg.get("text") or ""


async def get_chat_or_404(chat_id: str) -> dict:
    _id = oid(chat_id)
    if _id is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Chat not found")
    doc = await get_db().chats.find_one({"_id": _id})
    if doc is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Chat not found")
    return doc


def ensure_participant(chat: dict, uid: str) -> None:
    if uid not in chat.get("participants", []):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Not a participant of this chat"
        )


async def publish_chat_new(chat_doc: dict) -> None:
    event = events.chat_new_event(chat_doc)
    for uid in chat_doc.get("participants", []):
        await broker.publish(events.inbox_topic(uid), event)


async def publish_chat_updated(chat_doc: dict) -> None:
    """Push chat.updated to the chat topic and every participant's inbox."""
    event = events.chat_updated_event(chat_doc)
    await broker.publish(events.chat_topic(str(chat_doc["_id"])), event)
    for uid in chat_doc.get("participants", []):
        await broker.publish(events.inbox_topic(uid), event)


async def record_message(chat: dict, msg: dict) -> dict:
    """Update a chat's lastMessage / recency / unread counts after a send.

    Returns the refreshed chat document.
    """
    db = get_db()
    sender_id = msg["senderId"]
    sent_at = msg["sentAt"]

    inc = {
        f"unreadCounts.{uid}": 1
        for uid in chat.get("participants", [])
        if uid != sender_id
    }
    update: dict = {
        "$set": {
            "lastMessage": {
                "text": message_preview(msg),
                "senderId": sender_id,
                "type": msg.get("type", "text"),
                "sentAt": sent_at,
            },
            "lastMessageAt": sent_at,
        }
    }
    if inc:
        update["$inc"] = inc

    await db.chats.update_one({"_id": chat["_id"]}, update)
    return await db.chats.find_one({"_id": chat["_id"]})
