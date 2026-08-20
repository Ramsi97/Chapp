"""Messages: paginated list, send, edit, delete (me/everyone), reactions."""
from fastapi import APIRouter, Depends, HTTPException, Query, status

from ..db import get_db
from ..deps import get_current_user
from ..models import message_public, now_utc, oid
from ..models.schemas import (
    EditMessageRequest,
    ReactionRequest,
    SendMessageRequest,
)
from ..realtime import events
from ..realtime.broker import broker
from ..services import (
    ensure_participant,
    get_chat_or_404,
    message_preview,
    publish_chat_updated,
    record_message,
)

router = APIRouter(tags=["messages"])

_ALLOWED_TYPES = {"text", "image", "voice", "file"}


async def _load_message_and_chat(message_id: str, uid: str) -> tuple[dict, dict]:
    _id = oid(message_id)
    if _id is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Message not found")
    msg = await get_db().messages.find_one({"_id": _id})
    if msg is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Message not found")
    chat = await get_chat_or_404(str(msg["chatId"]))
    ensure_participant(chat, uid)
    return msg, chat


@router.get("/chats/{chat_id}/messages")
async def list_messages(
    chat_id: str,
    before: str | None = Query(None, description="message id to page before"),
    limit: int = Query(50, ge=1, le=100),
    user: dict = Depends(get_current_user),
) -> list[dict]:
    db = get_db()
    chat = await get_chat_or_404(chat_id)
    ensure_participant(chat, str(user["_id"]))

    query: dict = {"chatId": chat_id}
    if before:
        bid = oid(before)
        anchor = await db.messages.find_one({"_id": bid}) if bid else None
        if anchor is not None:
            query["sentAt"] = {"$lt": anchor["sentAt"]}

    cursor = db.messages.find(query).sort("sentAt", -1).limit(limit)
    docs = [doc async for doc in cursor]
    docs.reverse()  # return oldest -> newest
    return [message_public(doc) for doc in docs]


@router.post("/chats/{chat_id}/messages")
async def send_message(
    chat_id: str,
    body: SendMessageRequest,
    user: dict = Depends(get_current_user),
) -> dict:
    db = get_db()
    uid = str(user["_id"])
    chat = await get_chat_or_404(chat_id)
    ensure_participant(chat, uid)

    msg_type = body.type if body.type in _ALLOWED_TYPES else "text"
    if msg_type == "text" and not (body.text and body.text.strip()):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Message text is required")

    msg: dict = {
        "chatId": chat_id,
        "senderId": uid,
        "type": msg_type,
        "text": body.text,
        "imageUrl": body.imageUrl,
        "mediaUrl": body.mediaUrl,
        "mimeType": body.mimeType,
        "fileName": body.fileName,
        "fileSize": body.fileSize,
        "duration": body.duration,
        "reactions": {},
        "deletedFor": [],
        "sentAt": now_utc(),
    }

    if body.replyToId:
        rid = oid(body.replyToId)
        replied = await db.messages.find_one({"_id": rid}) if rid else None
        if replied is not None and str(replied.get("chatId")) == chat_id:
            msg["replyToId"] = body.replyToId
            msg["replyPreview"] = {
                "senderId": replied.get("senderId", ""),
                "text": message_preview(replied),
                "type": replied.get("type", "text"),
            }

    res = await db.messages.insert_one(msg)
    msg["_id"] = res.inserted_id

    await broker.publish(
        events.chat_topic(chat_id), events.message_new_event(msg)
    )
    updated_chat = await record_message(chat, msg)
    await publish_chat_updated(updated_chat)

    return message_public(msg)


@router.patch("/messages/{message_id}")
async def edit_message(
    message_id: str,
    body: EditMessageRequest,
    user: dict = Depends(get_current_user),
) -> dict:
    db = get_db()
    uid = str(user["_id"])
    msg, _chat = await _load_message_and_chat(message_id, uid)

    if msg.get("senderId") != uid:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "You can only edit your own messages"
        )
    if msg.get("type", "text") != "text":
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "Only text messages can be edited"
        )

    await db.messages.update_one(
        {"_id": msg["_id"]},
        {"$set": {"text": body.text, "editedAt": now_utc()}},
    )
    updated = await db.messages.find_one({"_id": msg["_id"]})
    await broker.publish(
        events.chat_topic(str(updated["chatId"])),
        events.message_updated_event(updated),
    )
    return message_public(updated)


@router.delete("/messages/{message_id}")
async def delete_message(
    message_id: str,
    scope: str = Query("me", pattern="^(me|everyone)$"),
    user: dict = Depends(get_current_user),
) -> dict:
    db = get_db()
    uid = str(user["_id"])
    msg, _chat = await _load_message_and_chat(message_id, uid)

    if scope == "everyone":
        if msg.get("senderId") != uid:
            raise HTTPException(
                status.HTTP_403_FORBIDDEN,
                "You can only delete your own messages for everyone",
            )
        await db.messages.update_one(
            {"_id": msg["_id"]},
            {
                "$set": {
                    "deletedAt": now_utc(),
                    "text": None,
                    "imageUrl": None,
                    "mediaUrl": None,
                    "reactions": {},
                }
            },
        )
    else:  # scope == "me"
        await db.messages.update_one(
            {"_id": msg["_id"]}, {"$addToSet": {"deletedFor": uid}}
        )

    updated = await db.messages.find_one({"_id": msg["_id"]})
    payload = message_public(updated)
    await broker.publish(
        events.chat_topic(str(updated["chatId"])),
        events.message_deleted_event(str(updated["chatId"]), payload),
    )
    return payload


@router.post("/messages/{message_id}/reactions")
async def toggle_reaction(
    message_id: str,
    body: ReactionRequest,
    user: dict = Depends(get_current_user),
) -> dict:
    db = get_db()
    uid = str(user["_id"])
    msg, _chat = await _load_message_and_chat(message_id, uid)

    reactions: dict = dict(msg.get("reactions", {}))
    members = set(reactions.get(body.emoji, []))
    if uid in members:
        members.discard(uid)
    else:
        members.add(uid)
    if members:
        reactions[body.emoji] = sorted(members)
    else:
        reactions.pop(body.emoji, None)

    await db.messages.update_one(
        {"_id": msg["_id"]}, {"$set": {"reactions": reactions}}
    )
    updated = await db.messages.find_one({"_id": msg["_id"]})
    await broker.publish(
        events.chat_topic(str(updated["chatId"])),
        events.message_updated_event(updated),
    )
    return message_public(updated)
