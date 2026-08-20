"""Shared helpers: id/datetime conversion and document -> API-JSON serializers.

Serializers emit exactly the keys the Flutter models parse, with datetimes as
ISO-8601 strings and media paths resolved to absolute URLs.
"""
from datetime import datetime, timezone
from typing import Any

from bson import ObjectId

from ..config import settings


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def oid(value: str) -> ObjectId | None:
    """Parse a string into an ObjectId, or None if malformed."""
    if isinstance(value, ObjectId):
        return value
    try:
        return ObjectId(value)
    except Exception:
        return None


def iso(value: Any) -> str | None:
    """Serialize a datetime to an ISO-8601 UTC string ('...Z')."""
    if value is None:
        return None
    if isinstance(value, str):
        return value
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
    return None


def abs_url(path: str | None) -> str | None:
    """Resolve a stored relative media path (e.g. '/media/x.jpg') to a full URL."""
    if not path:
        return path
    if path.startswith("http://") or path.startswith("https://"):
        return path
    base = settings.public_base_url.rstrip("/")
    return f"{base}{path}" if path.startswith("/") else f"{base}/{path}"


def _date_map(value: dict | None) -> dict[str, str]:
    if not value:
        return {}
    return {k: iso(v) for k, v in value.items() if iso(v) is not None}


def user_public(doc: dict) -> dict:
    """Shape matches Flutter RegisteredUserModel.fromJson."""
    return {
        "userId": str(doc["_id"]),
        "name": doc.get("name", ""),
        "username": doc.get("username", ""),
        "phoneNumber": doc.get("phoneNumber", ""),
        "profilePic": abs_url(doc.get("profilePic")),
        "bio": doc.get("bio"),
        "isOnline": doc.get("isOnline", False),
        "lastActiveAt": iso(doc.get("lastActiveAt")) or iso(now_utc()),
        "contacts": doc.get("contacts", []),
        "blockedUsers": doc.get("blockedUsers", []),
        "settings": doc.get("settings", {}),
        "createdAt": iso(doc.get("createdAt")) or iso(now_utc()),
    }


def chat_public(doc: dict) -> dict:
    """Shape matches Flutter ChatModel (with top-level `id`)."""
    last = doc.get("lastMessage")
    last_json = None
    if last:
        last_json = {
            "text": last.get("text", ""),
            "senderId": last.get("senderId", ""),
            "type": last.get("type", "text"),
            "sentAt": iso(last.get("sentAt")),
        }
    return {
        "id": str(doc["_id"]),
        "type": doc.get("type", "direct"),
        "participants": doc.get("participants", []),
        "name": doc.get("name"),
        "photoUrl": abs_url(doc.get("photoUrl")),
        "createdBy": doc.get("createdBy", ""),
        "createdAt": iso(doc.get("createdAt")),
        "lastMessage": last_json,
        "lastMessageAt": iso(doc.get("lastMessageAt")),
        "unreadCounts": doc.get("unreadCounts", {}),
        "lastRead": _date_map(doc.get("lastRead")),
        "typing": _date_map(doc.get("typing")),
    }


def message_public(doc: dict) -> dict:
    """Shape matches Flutter MessageModel (extended for the new features)."""
    return {
        "id": str(doc["_id"]),
        "chatId": str(doc.get("chatId", "")),
        "senderId": doc.get("senderId", ""),
        "type": doc.get("type", "text"),
        "text": doc.get("text"),
        "imageUrl": abs_url(doc.get("imageUrl")),
        "mediaUrl": abs_url(doc.get("mediaUrl")),
        "mimeType": doc.get("mimeType"),
        "fileName": doc.get("fileName"),
        "fileSize": doc.get("fileSize"),
        "duration": doc.get("duration"),
        "replyToId": doc.get("replyToId"),
        "replyPreview": doc.get("replyPreview"),
        "reactions": doc.get("reactions", {}),
        "editedAt": iso(doc.get("editedAt")),
        "deletedAt": iso(doc.get("deletedAt")),
        "deletedFor": doc.get("deletedFor", []),
        "sentAt": iso(doc.get("sentAt")),
    }
