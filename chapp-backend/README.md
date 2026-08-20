# Chapp backend (FastAPI + MongoDB)

Self-hosted backend for the Chapp Flutter app — replaces Firebase Auth,
Firestore, and Storage. Provides email/password auth (JWT), users, chats
(direct + group), messages (text / image / voice / file, with replies,
reactions, edit & delete), media uploads, and a WebSocket for realtime updates.

## Stack

- **FastAPI** + **Uvicorn** (single worker in dev)
- **MongoDB** via **Motor** (async driver), Pydantic v2 for schemas
- **JWT** bearer auth (PyJWT), **bcrypt** password hashing
- Realtime via **WebSocket** + an in-process asyncio pub/sub broker
- Media on the local filesystem, served at `/media/...`

## Run with Docker (recommended)

```bash
cp .env.example .env        # then edit JWT_SECRET and PUBLIC_BASE_URL
docker compose up --build
```

This starts MongoDB and the API. Open http://localhost:8000/docs for the
interactive API, and http://localhost:8000/health for a health check.

## Run locally (without Docker)

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # set MONGO_URI to your local Mongo
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

You need a running MongoDB (e.g. `docker run -p 27017:27017 mongo:7`).

## Configuration (`.env`)

| Var | Meaning |
|---|---|
| `MONGO_URI` | Mongo connection string (compose overrides to `mongodb://mongo:27017`) |
| `DB_NAME` | Database name (default `chapp`) |
| `JWT_SECRET` | **Change this.** Signs access tokens |
| `JWT_ALGORITHM` | Default `HS256` |
| `ACCESS_TOKEN_TTL_MINUTES` | Token lifetime (default 30 days) |
| `UPLOAD_DIR` | Where uploads are written (default `uploads`) |
| `PUBLIC_BASE_URL` | Base URL the **device** uses to reach this server; media URLs are built from it |
| `CORS_ORIGINS` | `*` or comma-separated origins |

### `PUBLIC_BASE_URL` per platform (important)

Media URLs returned by the API are absolute, built from `PUBLIC_BASE_URL`, so it
must be reachable from the client device:

- **Android emulator** → `http://10.0.2.2:8000`
- **iOS simulator** → `http://127.0.0.1:8000`
- **Physical device** → `http://<your-computer-LAN-IP>:8000`

The Flutter app's API base URL must point at the same host.

## API overview

Auth: `POST /auth/signup`, `POST /auth/login`, `GET /auth/me`
Users: `POST /users/me` (create profile, multipart), `PATCH /users/me`,
`GET /users`, `GET /users/{id}`, `POST /users/me/presence`
Chats: `GET /chats`, `GET /chats/{id}`, `POST /chats/direct`,
`POST /chats/group` (multipart), `POST /chats/{id}/read`, `POST /chats/{id}/typing`
Messages: `GET /chats/{id}/messages?before=&limit=`, `POST /chats/{id}/messages`,
`PATCH /messages/{id}`, `DELETE /messages/{id}?scope=me|everyone`,
`POST /messages/{id}/reactions`
Media: `POST /media` (multipart) → `{url, path}`; files served at `GET /media/...`
Realtime: `GET /ws?token=<JWT>`

All endpoints except signup/login and media serving require
`Authorization: Bearer <token>`.

## WebSocket protocol

Connect to `ws://<host>/ws?token=<JWT>`. On connect the server marks you online
and subscribes you to your inbox (chat-list updates) and your own user topic.

Client → server frames:

```json
{"action": "subscribe",   "topic": "chat:<chatId>"}
{"action": "unsubscribe", "topic": "chat:<chatId>"}
{"action": "subscribe",   "topic": "user:<userId>"}
{"action": "ping"}
```

Server → client events: `message.new`, `message.updated`, `message.deleted`,
`chat.new`, `chat.updated`, `user.updated`, and `{"type":"pong"}`.

## Notes / scaling

- The pub/sub broker is **in-process** → run a **single** worker. To scale out,
  swap `app/realtime/broker.py` for Redis pub/sub or Mongo change streams.
- Media is local-disk behind `app/storage.py`; swap for S3/MinIO later.
- Every chat/message endpoint enforces participant authorization.
