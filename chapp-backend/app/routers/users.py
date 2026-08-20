"""Users: profile create/update, listing, lookup, presence."""
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pymongo.errors import DuplicateKeyError

from ..db import get_db
from ..deps import get_current_user
from ..models import now_utc, oid, user_public
from ..models.schemas import PresenceRequest
from ..realtime.broker import broker
from ..realtime.events import user_topic, user_updated_event
from ..storage import save_upload

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/me")
async def create_profile(
    name: str = Form(...),
    username: str = Form(...),
    bio: str | None = Form(None),
    phoneNumber: str | None = Form(None),
    image: UploadFile | None = File(None),
    user: dict = Depends(get_current_user),
) -> dict:
    db = get_db()
    uid = user["_id"]
    username_clean = username.strip()
    username_lower = username_clean.lower()

    clash = await db.users.find_one(
        {"usernameLower": username_lower, "_id": {"$ne": uid}}
    )
    if clash is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Username already taken")

    update: dict = {
        "name": name.strip(),
        "username": username_clean,
        "usernameLower": username_lower,
    }
    if bio is not None:
        update["bio"] = bio
    if phoneNumber is not None:
        update["phoneNumber"] = phoneNumber
    if image is not None:
        rel, _ = await save_upload(image, subdir="avatars")
        update["profilePic"] = rel

    try:
        await db.users.update_one({"_id": uid}, {"$set": update})
    except DuplicateKeyError:
        raise HTTPException(status.HTTP_409_CONFLICT, "Username already taken")

    doc = await db.users.find_one({"_id": uid})
    return user_public(doc)


@router.patch("/me")
async def update_profile(
    name: str | None = Form(None),
    bio: str | None = Form(None),
    image: UploadFile | None = File(None),
    user: dict = Depends(get_current_user),
) -> dict:
    db = get_db()
    uid = user["_id"]

    update: dict = {}
    if name is not None:
        update["name"] = name.strip()
    if bio is not None:
        update["bio"] = bio
    if image is not None:
        rel, _ = await save_upload(image, subdir="avatars")
        update["profilePic"] = rel

    if update:
        await db.users.update_one({"_id": uid}, {"$set": update})

    doc = await db.users.find_one({"_id": uid})
    await broker.publish(user_topic(str(uid)), user_updated_event(doc))
    return user_public(doc)


@router.post("/me/presence")
async def set_presence(
    body: PresenceRequest, user: dict = Depends(get_current_user)
) -> dict:
    db = get_db()
    uid = user["_id"]
    await db.users.update_one(
        {"_id": uid},
        {"$set": {"isOnline": body.isOnline, "lastActiveAt": now_utc()}},
    )
    doc = await db.users.find_one({"_id": uid})
    await broker.publish(user_topic(str(uid)), user_updated_event(doc))
    return user_public(doc)


@router.get("")
async def list_users(user: dict = Depends(get_current_user)) -> list[dict]:
    """All other users that have completed a profile (for starting chats)."""
    db = get_db()
    cursor = db.users.find(
        {"_id": {"$ne": user["_id"]}, "username": {"$exists": True, "$ne": None}}
    )
    return [user_public(doc) async for doc in cursor]


@router.get("/{user_id}")
async def get_user(user_id: str, _: dict = Depends(get_current_user)) -> dict:
    _id = oid(user_id)
    if _id is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    doc = await get_db().users.find_one({"_id": _id})
    if doc is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    return user_public(doc)
