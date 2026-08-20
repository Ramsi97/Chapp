"""Per-connection state and a process-wide presence counter.

Each WebSocket connection owns one asyncio.Queue. The broker pushes events onto
that queue for every topic the connection has subscribed to; a reader task in
the ws router drains the queue to the socket.
"""
import asyncio

from .broker import broker


class Connection:
    """Tracks the topics one socket is subscribed to and its inbound queue."""

    def __init__(self, user_id: str) -> None:
        self.user_id = user_id
        self.queue: asyncio.Queue = asyncio.Queue()
        self.topics: set[str] = set()

    def subscribe(self, topic: str) -> None:
        if topic not in self.topics:
            self.topics.add(topic)
            broker.subscribe(topic, self.queue)

    def unsubscribe(self, topic: str) -> None:
        if topic in self.topics:
            self.topics.discard(topic)
            broker.unsubscribe(topic, self.queue)

    def close(self) -> None:
        for topic in list(self.topics):
            broker.unsubscribe(topic, self.queue)
        self.topics.clear()


class PresenceTracker:
    """Reference-counts live connections per user (multi-device aware)."""

    def __init__(self) -> None:
        self._counts: dict[str, int] = {}

    def connect(self, user_id: str) -> bool:
        """Register a connection; return True if the user just came online."""
        n = self._counts.get(user_id, 0)
        self._counts[user_id] = n + 1
        return n == 0

    def disconnect(self, user_id: str) -> bool:
        """Drop a connection; return True if the user just went offline."""
        n = self._counts.get(user_id, 0)
        if n <= 1:
            self._counts.pop(user_id, None)
            return True
        self._counts[user_id] = n - 1
        return False

    def is_online(self, user_id: str) -> bool:
        return self._counts.get(user_id, 0) > 0


presence = PresenceTracker()
