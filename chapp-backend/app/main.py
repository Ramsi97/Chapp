"""FastAPI application: lifespan (Mongo connect + indexes), CORS, routers,
media static mount, and a health check."""
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .config import settings
from .db import close_mongo_connection, connect_to_mongo
from .routers import auth, chats, media, messages, users, ws


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_to_mongo()
    yield
    await close_mongo_connection()


app = FastAPI(title="Chapp API", version="1.0.0", lifespan=lifespan)

_origins = settings.cors_origin_list
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    # Wildcard origins can't be combined with credentials per the CORS spec;
    # the mobile client uses bearer tokens, not cookies, so this is fine.
    allow_credentials="*" not in _origins,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["health"])
async def health() -> dict:
    return {"status": "ok"}


# REST + WS routers first, so `POST /media` resolves before the static mount.
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(media.router)
app.include_router(chats.router)
app.include_router(messages.router)
app.include_router(ws.router)

# Serve uploaded files at /media/<path>. Directory must exist before mounting.
Path(settings.upload_dir).mkdir(parents=True, exist_ok=True)
app.mount("/media", StaticFiles(directory=settings.upload_dir), name="media")
