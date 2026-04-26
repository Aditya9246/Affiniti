import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.auth import get_current_user
from app.database import get_db
from app.models import User, Event, RSVP
from app.schemas import EventCreateRequest, EventResponse, HostResponse

router = APIRouter(prefix="/events", tags=["events"])

async def _build_event_response(
    event: Event, db: AsyncSession, current_user_id: uuid.UUID
) -> EventResponse:
    host_result = await db.execute(select(User).where(User.id == event.host_user_id))
    host = host_result.scalar_one()

    count_result = await db.execute(
        select(func.count()).select_from(RSVP).where(RSVP.event_id == event.id)
    )
    rsvp_count = count_result.scalar()

    rsvped_result = await db.execute(
        select(RSVP).where(RSVP.user_id == current_user_id, RSVP.event_id == event.id)
    )
    user_rsvped = rsvped_result.scalar_one_or_none() is not None

    return EventResponse(
        id=event.id,
        name=event.name,
        date=event.date,
        location=event.location,
        description=event.description,
        cover_image_url=event.cover_image_url,
        host=HostResponse(id=host.id, name=host.name, photo_url=host.photo_url),
        rsvp_count=rsvp_count,
        user_rsvped=user_rsvped,
    )

@router.get("", response_model=list[EventResponse])
async def list_events(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Event))
    events = result.scalars().all()
    return [await _build_event_response(e, db, current_user.id) for e in events]

@router.post("", status_code=201)
async def create_event(
    body: EventCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event = Event(
        host_user_id=current_user.id,
        name=body.name,
        date=body.date,
        location=body.location,
        description=body.description,
        cover_image_url=body.cover_image_url,
    )
    db.add(event)
    await db.commit()
    await db.refresh(event)
    return await _build_event_response(event, db, current_user.id)

@router.get("/{event_id}", response_model=EventResponse)
async def get_event(
    event_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Event).where(Event.id == event_id))
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return await _build_event_response(event, db, current_user.id)
