"""Chats: list, fetch, direct get-or-create, group create, read, typing."""
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pymongo.errors import DuplicateKeyError

from ..db import get_db
from ..deps import get_current_user
from ..models import chat_public, now_utc, oid
from ..models.schemas import DirectChatRequest, TypingRequest
from ..services import (
    direct_key,
    ensure_participant,
    get_chat_or_404,
    publish_chat_new,
    publish_chat_updated,
)
from ..storage import save_upload

router = APIRouter(prefix="/chats", tags=["chats"])


@router.get("")
async def list_chats(user: dict = Depends(get_current_user)) -> list[dict]:
    uid = str(user["_id"])
    cursor = (
        get_db()
        .chats.find({"participants": uid})
        .sort("lastMessageAt", -1)
    )
    return [chat_public(doc) async for doc in cursor]


@router.get("/{chat_id}")
async def get_chat(chat_id: str, user: dict = Depends(get_current_user)) -> dict:
    chat = await get_chat_or_404(chat_id)
    ensure_participant(chat, str(user["_id"]))
    return chat_public(chat)


@router.post("/direct")
async def get_or_create_direct(
    body: DirectChatRequest, user: dict = Depends(get_current_user)
) -> dict:
    db = get_db()
    uid = str(user["_id"])
    other = body.otherUid.strip()

    if other == uid:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "Cannot start a chat with yourself"
        )
    other_id = oid(other)
    if other_id is None or await db.users.find_one({"_id": other_id}) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")

    key = direct_key(uid, other)
    existing = await db.chats.find_one({"directKey": key})
    if existing is not None:
        return chat_public(existing)

    doc = {
        "type": "direct",
        "participants": sorted([uid, other]),
        "directKey": key,
        "createdBy": uid,
        "createdAt": now_utc(),
        "lastMessageAt": now_utc(),
        "unreadCounts": {uid: 0, other: 0},
        "lastRead": {},
        "typing": {},
    }
    try:
        res = await db.chats.insert_one(doc)
    except DuplicateKeyError:
        existing = await db.chats.find_one({"directKey": key})
        return chat_public(existing)

    doc["_id"] = res.inserted_id
    await publish_chat_new(doc)
    return chat_public(doc)


@router.post("/group")
async def create_group(
    name: str = Form(...),
    participants: list[str] = Form(...),
    image: UploadFile | None = File(None),
    user: dict = Depends(get_current_user),
) -> dict:
    db = get_db()
    uid = str(user["_id"])

    members = list(dict.fromkeys([uid, *[p.strip() for p in participants if p.strip()]]))
    if len(members) < 2:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "A group needs at least two members"
        )

    photo_url = None
    if image is not None:
        photo_url, _ = await save_upload(image, subdir="avatars")

    doc = {
        "type": "group",
        "participants": members,
        "name": name.strip(),
        "photoUrl": photo_url,
        "createdBy": uid,
        "createdAt": now_utc(),
        "lastMessageAt": now_utc(),
        "unreadCounts": {m: 0 for m in members},
        "lastRead": {},
        "typing": {},
    }
    res = await db.chats.insert_one(doc)
    doc["_id"] = res.inserted_id
    await publish_chat_new(doc)
    return chat_public(doc)


@router.post("/{chat_id}/read")
async def mark_read(chat_id: str, user: dict = Depends(get_current_user)) -> dict:
    db = get_db()
    uid = str(user["_id"])
    chat = await get_chat_or_404(chat_id)
    ensure_participant(chat, uid)

    await db.chats.update_one(
        {"_id": chat["_id"]},
        {"$set": {f"unreadCounts.{uid}": 0, f"lastRead.{uid}": now_utc()}},
    )
    updated = await db.chats.find_one({"_id": chat["_id"]})
    await publish_chat_updated(updated)
    return chat_public(updated)


@router.post("/{chat_id}/typing")
async def set_typing(
    chat_id: str, body: TypingRequest, user: dict = Depends(get_current_user)
) -> dict:
    db = get_db()
    uid = str(user["_id"])
    chat = await get_chat_or_404(chat_id)
    ensure_participant(chat, uid)

    if body.isTyping:
        update = {"$set": {f"typing.{uid}": now_utc()}}
    else:
        update = {"$unset": {f"typing.{uid}": ""}}
    await db.chats.update_one({"_id": chat["_id"]}, update)
    updated = await db.chats.find_one({"_id": chat["_id"]})
    await publish_chat_updated(updated)
    return chat_public(updated)
