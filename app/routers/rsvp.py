import uuid
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.auth import get_current_user
from app.database import get_db
from app.models import User, Event, RSVP
from app.schemas import RSVPRequest, IntentRequest
from app.ollama import embed
from app.tasks import run_matching

router = APIRouter(prefix="/events/{event_id}", tags=["rsvp"])

async def _require_event(event_id: uuid.UUID, db: AsyncSession) -> Event:
    result = await db.execute(select(Event).where(Event.id == event_id))
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event

async def _require_rsvp(user_id: uuid.UUID, event_id: uuid.UUID, db: AsyncSession) -> RSVP:
    result = await db.execute(
        select(RSVP).where(RSVP.user_id == user_id, RSVP.event_id == event_id)
    )
    rsvp = result.scalar_one_or_none()
    if not rsvp:
        raise HTTPException(status_code=403, detail="User not RSVPed to event")
    return rsvp

@router.post("/rsvp", status_code=202)
async def rsvp_to_event(
    event_id: uuid.UUID,
    body: RSVPRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _require_event(event_id, db)

    result = await db.execute(
        select(RSVP).where(RSVP.user_id == current_user.id, RSVP.event_id == event_id)
    )
    existing = result.scalar_one_or_none()
    if existing:
        existing.opted_in_fields = body.opted_in_fields
    else:
        db.add(RSVP(user_id=current_user.id, event_id=event_id, opted_in_fields=body.opted_in_fields))
    await db.commit()

    background_tasks.add_task(run_matching, current_user.id, event_id)
    return {"status": "rsvped"}

@router.post("/intent", status_code=202)
async def set_intent(
    event_id: uuid.UUID,
    body: IntentRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _require_event(event_id, db)
    rsvp = await _require_rsvp(current_user.id, event_id, db)

    rsvp.intent_text = body.intent_text
    rsvp.intent_embedding = await embed(body.intent_text)
    await db.commit()

    background_tasks.add_task(run_matching, current_user.id, event_id)
    return {"status": "intent_set", "matching": "processing"}

@router.delete("/intent", status_code=200)
async def clear_intent(
    event_id: uuid.UUID,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _require_event(event_id, db)
    rsvp = await _require_rsvp(current_user.id, event_id, db)

    rsvp.intent_text = None
    rsvp.intent_embedding = None
    await db.commit()

    background_tasks.add_task(run_matching, current_user.id, event_id)
    return {"status": "intent_cleared"}
