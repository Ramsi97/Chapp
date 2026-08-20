"""Auth: email/password signup + login, JWT issuance, and /auth/me."""
from fastapi import APIRouter, Depends, HTTPException, status
from pymongo.errors import DuplicateKeyError

from ..db import get_db
from ..deps import get_current_user
from ..models import now_utc
from ..models.schemas import AuthResponse, LoginRequest, MeResponse, SignupRequest
from ..security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


def _valid_email(email: str) -> bool:
    at = email.find("@")
    return 0 < at < len(email) - 1 and "." in email[at:]


def _has_profile(user: dict) -> bool:
    return bool(user.get("name") and user.get("username"))


@router.post("/signup", response_model=AuthResponse)
async def signup(body: SignupRequest) -> AuthResponse:
    email = body.email.strip()
    email_lower = email.lower()
    if not _valid_email(email_lower):
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, "Invalid email address"
        )

    db = get_db()
    doc = {
        "email": email,
        "emailLower": email_lower,
        "passwordHash": hash_password(body.password),
        "createdAt": now_utc(),
        "lastActiveAt": now_utc(),
        "isOnline": False,
        "contacts": [],
        "blockedUsers": [],
        "settings": {},
    }
    try:
        res = await db.users.insert_one(doc)
    except DuplicateKeyError:
        raise HTTPException(status.HTTP_409_CONFLICT, "Email already registered")

    uid = str(res.inserted_id)
    return AuthResponse(token=create_access_token(uid), userId=uid, email=email)


@router.post("/login", response_model=AuthResponse)
async def login(body: LoginRequest) -> AuthResponse:
    db = get_db()
    email_lower = body.email.strip().lower()
    user = await db.users.find_one({"emailLower": email_lower})
    if user is None or not verify_password(body.password, user.get("passwordHash", "")):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "Invalid email or password"
        )
    uid = str(user["_id"])
    return AuthResponse(
        token=create_access_token(uid), userId=uid, email=user.get("email", "")
    )


@router.get("/me", response_model=MeResponse)
async def me(user: dict = Depends(get_current_user)) -> MeResponse:
    return MeResponse(
        userId=str(user["_id"]),
        email=user.get("email", ""),
        hasProfile=_has_profile(user),
    )
