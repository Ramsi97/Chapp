"""WebSocket event type constants, topic helpers, and payload builders."""
from ..models import chat_public, message_public, user_public

# ---- event types (mirror the Dart realtime adapter's switch) ----
MESSAGE_NEW = "message.new"
MESSAGE_UPDATED = "message.updated"
MESSAGE_DELETED = "message.deleted"
CHAT_UPDATED = "chat.updated"
CHAT_NEW = "chat.new"
USER_UPDATED = "user.updated"


# ---- topics ----
def chat_topic(chat_id: str) -> str:
    return f"chat:{chat_id}"


def user_topic(user_id: str) -> str:
    return f"user:{user_id}"


def inbox_topic(user_id: str) -> str:
    return f"inbox:{user_id}"


# ---- payload builders ----
def message_new_event(doc: dict) -> dict:
    return {
        "type": MESSAGE_NEW,
        "chatId": str(doc.get("chatId", "")),
        "message": message_public(doc),
    }


def message_updated_event(doc: dict) -> dict:
    return {
        "type": MESSAGE_UPDATED,
        "chatId": str(doc.get("chatId", "")),
        "message": message_public(doc),
    }


def message_deleted_event(chat_id: str, message: dict) -> dict:
    # For "delete for everyone" we still send the (tombstoned) message so the
    # client can render the placeholder in place.
    return {
        "type": MESSAGE_DELETED,
        "chatId": chat_id,
        "messageId": message["id"],
        "message": message,
    }


def chat_updated_event(doc: dict) -> dict:
    return {
        "type": CHAT_UPDATED,
        "chatId": str(doc["_id"]),
        "chat": chat_public(doc),
    }


def chat_new_event(doc: dict) -> dict:
    return {
        "type": CHAT_NEW,
        "chatId": str(doc["_id"]),
        "chat": chat_public(doc),
    }


def user_updated_event(doc: dict) -> dict:
    return {
        "type": USER_UPDATED,
        "userId": str(doc["_id"]),
        "user": user_public(doc),
    }
