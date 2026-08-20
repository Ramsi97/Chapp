"""In-process async pub/sub broker.

Single-process only: works with one uvicorn worker (the dev setup). To scale
horizontally, swap this for Redis pub/sub or Mongo change streams behind the
same subscribe/unsubscribe/publish interface.

Topics:
  chat:{chatId}   -> message.new/updated/deleted, chat.updated for that chat
  user:{userId}   -> user.updated (presence/profile) for watchUser
  inbox:{userId}  -> chat.new / chat.updated for a user's chat list
"""
import asyncio


class Broker:
    def __init__(self) -> None:
        self._subs: dict[str, set[asyncio.Queue]] = {}

    def subscribe(self, topic: str, q: asyncio.Queue) -> None:
        self._subs.setdefault(topic, set()).add(q)

    def unsubscribe(self, topic: str, q: asyncio.Queue) -> None:
        subs = self._subs.get(topic)
        if subs is None:
            return
        subs.discard(q)
        if not subs:
            self._subs.pop(topic, None)

    async def publish(self, topic: str, event: dict) -> None:
        # asyncio is single-threaded, so a snapshot of the set is enough to be
        # safe against subscribers coming/going during the fan-out.
        for q in list(self._subs.get(topic, ())):
            q.put_nowait(event)


broker = Broker()
