"""WebSocket endpoint: authenticated fan-out of realtime events.

Connect with `GET /ws?token=<JWT>`. The server validates the token, marks the
user online, auto-subscribes their inbox, and forwards every event published to
a subscribed topic. Clients manage chat/user subscriptions with JSON frames:

    {"action": "subscribe",   "topic": "chat:<id>"}
    {"action": "unsubscribe", "topic": "chat:<id>"}
    {"action": "ping"}                     -> {"type": "pong"}
"""
import asyncio
import json

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect

from ..db import get_db
from ..models import now_utc, oid
from ..realtime import events
from ..realtime.broker import broker
from ..realtime.manager import Connection, presence
from ..security import decode_access_token

router = APIRouter()


async def _set_online(uid: str, online: bool) -> None:
    db = get_db()
    _id = oid(uid)
    if _id is None:
        return
    await db.users.update_one(
        {"_id": _id}, {"$set": {"isOnline": online, "lastActiveAt": now_utc()}}
    )
    doc = await db.users.find_one({"_id": _id})
    if doc is not None:
        await broker.publish(events.user_topic(uid), events.user_updated_event(doc))


async def _authorized_topic(uid: str, topic: str) -> bool:
    if topic.startswith("user:"):
        return True  # presence/profile is public to authenticated users
    if topic.startswith("inbox:"):
        return topic == events.inbox_topic(uid)
    if topic.startswith("chat:"):
        _id = oid(topic.split(":", 1)[1])
        if _id is None:
            return False
        chat = await get_db().chats.find_one({"_id": _id}, {"participants": 1})
        return bool(chat and uid in chat.get("participants", []))
    return False


@router.websocket("/ws")
async def ws_endpoint(websocket: WebSocket, token: str = Query(...)) -> None:
    uid = decode_access_token(token)
    if not uid or oid(uid) is None:
        await websocket.close(code=4401)
        return
    if await get_db().users.find_one({"_id": oid(uid)}) is None:
        await websocket.close(code=4401)
        return

    await websocket.accept()
    conn = Connection(uid)
    conn.subscribe(events.inbox_topic(uid))
    conn.subscribe(events.user_topic(uid))

    if presence.connect(uid):
        await _set_online(uid, True)

    async def reader() -> None:
        # Sole sender on this socket, so concurrent sends can't interleave.
        try:
            while True:
                event = await conn.queue.get()
                await websocket.send_json(event)
        except Exception:
            pass

    reader_task = asyncio.create_task(reader())
    try:
        while True:
            raw = await websocket.receive_text()
            try:
                data = json.loads(raw)
            except (ValueError, TypeError):
                continue
            action = data.get("action")
            topic = data.get("topic", "")
            if action == "subscribe" and await _authorized_topic(uid, topic):
                conn.subscribe(topic)
            elif action == "unsubscribe":
                conn.unsubscribe(topic)
            elif action == "ping":
                conn.queue.put_nowait({"type": "pong"})
    except WebSocketDisconnect:
        pass
    except Exception:
        pass
    finally:
        reader_task.cancel()
        conn.close()
        if presence.disconnect(uid):
            await _set_online(uid, False)
