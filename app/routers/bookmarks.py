import uuid
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.auth import get_current_user
from app.database import get_db
from app.models import User, Event, Bookmark
from app.schemas import BookmarkRequest
from app.config import settings

router = APIRouter(prefix="/events/{event_id}", tags=["bookmarks"])

@router.get("/bookmarks")
async def get_bookmarks(
    event_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event_result = await db.execute(select(Event).where(Event.id == event_id))
    event = event_result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    cutoff = datetime.now(timezone.utc) - timedelta(days=settings.BOOKMARK_RETENTION_DAYS)
    if event.date and event.date < cutoff:
        return []

    result = await db.execute(
        select(Bookmark).where(Bookmark.user_id == current_user.id, Bookmark.event_id == event_id)
    )
    out = []
    for bm in result.scalars().all():
        u_result = await db.execute(select(User).where(User.id == bm.bookmarked_user_id))
        u = u_result.scalar_one_or_none()
        if u:
            out.append({"user_id": str(bm.bookmarked_user_id), "name": u.name, "photo_url": u.photo_url})
    return out

@router.post("/bookmarks", status_code=201)
async def add_bookmark(
    event_id: uuid.UUID,
    body: BookmarkRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event_result = await db.execute(select(Event).where(Event.id == event_id))
    if not event_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Event not found")

    existing = await db.execute(
        select(Bookmark).where(
            Bookmark.user_id == current_user.id,
            Bookmark.event_id == event_id,
            Bookmark.bookmarked_user_id == body.bookmarked_user_id,
        )
    )
    if existing.scalar_one_or_none():
        return {"status": "already_bookmarked"}

    db.add(Bookmark(user_id=current_user.id, event_id=event_id, bookmarked_user_id=body.bookmarked_user_id))
    await db.commit()
    return {"status": "bookmarked"}

@router.delete("/bookmarks/{bookmarked_user_id}", status_code=200)
async def remove_bookmark(
    event_id: uuid.UUID,
    bookmarked_user_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Bookmark).where(
            Bookmark.user_id == current_user.id,
            Bookmark.event_id == event_id,
            Bookmark.bookmarked_user_id == bookmarked_user_id,
        )
    )
    bm = result.scalar_one_or_none()
    if not bm:
        raise HTTPException(status_code=404, detail="Bookmark not found")
    await db.delete(bm)
    await db.commit()
    return {"status": "removed"}
