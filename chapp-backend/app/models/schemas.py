"""Pydantic request/response schemas for JSON endpoints.

Multipart endpoints (profile create/update, group create, media upload) read
Form/File params directly in their routers rather than through these models.
"""
from pydantic import BaseModel, Field


# ---- Auth ----
class SignupRequest(BaseModel):
    email: str
    password: str = Field(min_length=6, max_length=128)


class LoginRequest(BaseModel):
    email: str
    password: str


class AuthResponse(BaseModel):
    token: str
    userId: str
    email: str


class MeResponse(BaseModel):
    userId: str
    email: str
    hasProfile: bool


# ---- Chats ----
class DirectChatRequest(BaseModel):
    otherUid: str


class TypingRequest(BaseModel):
    isTyping: bool


class PresenceRequest(BaseModel):
    isOnline: bool


# ---- Messages ----
class SendMessageRequest(BaseModel):
    type: str = "text"  # text | image | voice | file
    text: str | None = None
    imageUrl: str | None = None
    mediaUrl: str | None = None
    mimeType: str | None = None
    fileName: str | None = None
    fileSize: int | None = None
    duration: float | None = None
    replyToId: str | None = None


class EditMessageRequest(BaseModel):
    text: str


class ReactionRequest(BaseModel):
    emoji: str


# ---- Media ----
class MediaResponse(BaseModel):
    url: str   # absolute, for immediate preview
    path: str  # relative, send this back in message payloads


# ---- Push (later phase) ----
class DeviceTokenRequest(BaseModel):
    token: str
    platform: str = "android"
