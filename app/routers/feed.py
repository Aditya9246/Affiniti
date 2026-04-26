import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from app.auth import get_current_user
from app.database import get_db
from app.models import User, Event, RSVP, Status, Bookmark
from app.schemas import FeedItemResponse
from app.ranking import compute_score, apply_field_mask

router = APIRouter(prefix="/events/{event_id}", tags=["feed"])
_OPEN_STATUSES = {"open_to_chat", "looking_for_group"}

def _vec_str(v) -> str:
    return "[" + ",".join(f"{x:.8f}" for x in v) + "]"

@router.get("/feed", response_model=list[FeedItemResponse])
async def get_feed(
    event_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event_result = await db.execute(select(Event).where(Event.id == event_id))
    if not event_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Event not found")

    if current_user.embedding is None:
        raise HTTPException(status_code=422, detail="Profile not yet embedded — retry in a moment")

    rsvps_result = await db.execute(
        select(RSVP).where(RSVP.event_id == event_id, RSVP.user_id != current_user.id)
    )
    rsvps = rsvps_result.scalars().all()
    if not rsvps:
        return []

    user_ids = [r.user_id for r in rsvps]
    emb_str = _vec_str(current_user.embedding)

    sim_rows = await db.execute(
        text("""
            SELECT u.id, 1 - (u.embedding <=> :emb::vector) AS profile_sim
            FROM users u
            WHERE u.id = ANY(:ids) AND u.embedding IS NOT NULL
        """),
        {"emb": emb_str, "ids": [str(uid) for uid in user_ids]},
    )
    profile_sims = {row.id: row.profile_sim for row in sim_rows}

    intent_sims: dict = {}
    cur_rsvp_result = await db.execute(
        select(RSVP).where(RSVP.user_id == current_user.id, RSVP.event_id == event_id)
    )
    cur_rsvp = cur_rsvp_result.scalar_one_or_none()
    if cur_rsvp and cur_rsvp.intent_embedding is not None:
        i_emb_str = _vec_str(cur_rsvp.intent_embedding)
        intent_rows = await db.execute(
            text("""
                SELECT r.user_id, 1 - (r.intent_embedding <=> :emb::vector) AS intent_sim
                FROM rsvps r
                WHERE r.event_id = :event_id
                  AND r.user_id != :uid
                  AND r.intent_embedding IS NOT NULL
            """),
            {"emb": i_emb_str, "event_id": str(event_id), "uid": str(current_user.id)},
        )
        intent_sims = {row.user_id: row.intent_sim for row in intent_rows}

    now = datetime.now(timezone.utc)
    statuses_result = await db.execute(
        select(Status).where(
            Status.event_id == event_id,
            Status.user_id.in_(user_ids),
            Status.expires_at > now,
        )
    )
    statuses = {s.user_id: s.status for s in statuses_result.scalars().all()}

    bookmarks_result = await db.execute(
        select(Bookmark).where(
            Bookmark.user_id == current_user.id,
            Bookmark.event_id == event_id,
            Bookmark.bookmarked_user_id.in_(user_ids),
        )
    )
    bookmarked_ids = {b.bookmarked_user_id for b in bookmarks_result.scalars().all()}

    users_result = await db.execute(select(User).where(User.id.in_(user_ids)))
    users_by_id = {u.id: u for u in users_result.scalars().all()}
    rsvp_by_user = {r.user_id: r for r in rsvps}

    items = []
    for uid in user_ids:
        user = users_by_id.get(uid)
        if not user:
            continue
        opted_in = rsvp_by_user[uid].opted_in_fields or []
        masked = apply_field_mask(
            name=user.name, photo_url=user.photo_url, bio=user.bio,
            interests=user.interests, skills=user.skills,
            opted_in_fields=opted_in,
        )
        p_sim = profile_sims.get(uid, 0.0)
        final_score = compute_score(p_sim, intent_sims.get(uid))

        cur_int = set(current_user.interests or [])
        cur_sk = set(current_user.skills or [])
        att_int = set(user.interests or []) if "interests" in opted_in else set()
        att_sk = set(user.skills or []) if "skills" in opted_in else set()
        shared_tags = list((cur_int & att_int) | (cur_sk & att_sk))

        headline = (masked["bio"] or "")[:100] or None
        user_status = statuses.get(uid)

        items.append(FeedItemResponse(
            user_id=uid,
            name=masked["name"],
            photo_url=masked["photo_url"],
            headline=headline,
            shared_tags=shared_tags,
            status=user_status,
            looking_to_meet=user_status in _OPEN_STATUSES if user_status else False,
            bookmarked=uid in bookmarked_ids,
            similarity_score=final_score,
        ))

    items.sort(key=lambda x: x.similarity_score, reverse=True)
    return items
