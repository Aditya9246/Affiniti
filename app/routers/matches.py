import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.auth import get_current_user
from app.database import get_db
from app.models import User, Event, Match, RSVP
from app.schemas import MatchResponse
from app.ranking import apply_field_mask

router = APIRouter(prefix="/events/{event_id}", tags=["matches"])

@router.get("/matches", response_model=list[MatchResponse])
async def get_matches(
    event_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event_result = await db.execute(select(Event).where(Event.id == event_id))
    if not event_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Event not found")

    matches_result = await db.execute(
        select(Match)
        .where(Match.user_id == current_user.id, Match.event_id == event_id)
        .order_by(Match.score.desc())
    )
    matches = matches_result.scalars().all()

    responses = []
    for match in matches:
        u_result = await db.execute(select(User).where(User.id == match.matched_user_id))
        matched_user = u_result.scalar_one_or_none()
        if not matched_user:
            continue

        rsvp_result = await db.execute(
            select(RSVP).where(RSVP.user_id == match.matched_user_id, RSVP.event_id == event_id)
        )
        rsvp = rsvp_result.scalar_one_or_none()
        opted_in = rsvp.opted_in_fields if rsvp else []

        masked = apply_field_mask(
            name=matched_user.name, photo_url=matched_user.photo_url,
            bio=matched_user.bio, interests=matched_user.interests,
            skills=matched_user.skills, opted_in_fields=opted_in,
        )

        cur_int = set(current_user.interests or [])
        cur_sk = set(current_user.skills or [])
        att_int = set(matched_user.interests or []) if "interests" in opted_in else set()
        att_sk = set(matched_user.skills or []) if "skills" in opted_in else set()
        shared_tags = list((cur_int & att_int) | (cur_sk & att_sk))

        responses.append(MatchResponse(
            matched_user_id=match.matched_user_id,
            name=masked["name"],
            photo_url=masked["photo_url"],
            headline=(masked["bio"] or "")[:100] or None,
            shared_tags=shared_tags,
            icebreaker_text=match.icebreaker_text,
            score=match.score,
        ))
    return responses
