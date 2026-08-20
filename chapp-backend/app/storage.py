"""Local-filesystem media storage behind a tiny abstraction.

Files are written under settings.upload_dir and served by a StaticFiles mount
at the `/media` URL prefix. We store the *relative* URL path in Mongo and let
the serializers resolve it to an absolute URL, so the DB stays host-agnostic.
Swap this module for an S3/MinIO client later without touching callers.
"""
import uuid
from pathlib import Path

from fastapi import UploadFile

from .config import settings

MEDIA_URL_PREFIX = "/media"
_CHUNK = 1024 * 1024  # 1 MiB


def _ext(filename: str | None) -> str:
    return Path(filename or "").suffix.lower()


async def save_upload(file: UploadFile, subdir: str = "") -> tuple[str, int]:
    """Persist an UploadFile and return (relative_url_path, size_bytes)."""
    base = Path(settings.upload_dir)
    target_dir = base / subdir if subdir else base
    target_dir.mkdir(parents=True, exist_ok=True)

    name = f"{uuid.uuid4().hex}{_ext(file.filename)}"
    dest = target_dir / name

    size = 0
    with dest.open("wb") as out:
        while True:
            chunk = await file.read(_CHUNK)
            if not chunk:
                break
            size += len(chunk)
            out.write(chunk)

    parts = [MEDIA_URL_PREFIX] + ([subdir] if subdir else []) + [name]
    rel_path = "/".join(parts)
    return rel_path, size
