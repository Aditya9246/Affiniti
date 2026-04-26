import uuid
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.auth import get_current_user
from app.database import get_db
from app.models import User, Event, Status
from app.schemas import StatusRequest, StatusResponse
from app.config import settings

router = APIRouter(prefix="/events/{event_id}", tags=["status"])

_VALID = {"open_to_chat", "looking_for_group", "deep_in_work", "taking_a_break"}

@router.post("/status", response_model=StatusResponse)
async def set_status(
    event_id: uuid.UUID,
    body: StatusRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if body.status not in _VALID:
        raise HTTPException(status_code=422, detail=f"status must be one of {sorted(_VALID)}")

    event_result = await db.execute(select(Event).where(Event.id == event_id))
    if not event_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Event not found")

    expires_at = datetime.now(timezone.utc) + timedelta(seconds=settings.STATUS_TTL_SECONDS)

    result = await db.execute(
        select(Status).where(Status.user_id == current_user.id, Status.event_id == event_id)
    )
    existing = result.scalar_one_or_none()
    if existing:
        existing.status = body.status
        existing.expires_at = expires_at
    else:
        db.add(Status(user_id=current_user.id, event_id=event_id, status=body.status, expires_at=expires_at))
    await db.commit()

    return StatusResponse(status=body.status, expires_at=expires_at)
