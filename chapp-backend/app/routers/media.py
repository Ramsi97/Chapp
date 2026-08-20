"""Media upload. Serving is handled by the StaticFiles mount in main.py."""
from fastapi import APIRouter, Depends, File, UploadFile

from ..deps import get_current_user_id
from ..models import abs_url
from ..models.schemas import MediaResponse
from ..storage import save_upload

router = APIRouter(tags=["media"])


@router.post("/media", response_model=MediaResponse)
async def upload_media(
    file: UploadFile = File(...),
    _: str = Depends(get_current_user_id),
) -> MediaResponse:
    rel, _size = await save_upload(file, subdir="chat")
    return MediaResponse(url=abs_url(rel) or rel, path=rel)
