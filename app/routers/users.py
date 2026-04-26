from fastapi import APIRouter, Depends, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
from app.auth import get_current_user
from app.database import get_db
from app.models import User
from app.schemas import UserProfileRequest, UserResponse
from app.tasks import generalize_and_embed

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.post("/profile", status_code=202)
async def upsert_profile(
    body: UserProfileRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    current_user.name = body.name
    current_user.photo_url = body.photo_url
    current_user.bio = body.bio
    current_user.interests = body.interests
    current_user.hobbies = body.hobbies
    current_user.projects = body.projects
    current_user.skills = body.skills
    current_user.want_to_learn = body.want_to_learn
    current_user.github_url = body.github_url
    current_user.linkedin_url = body.linkedin_url
    current_user.raw_profile = body.model_dump()
    current_user.updated_at = datetime.now(timezone.utc)
    await db.commit()
    background_tasks.add_task(generalize_and_embed, current_user.id)
    return {"status": "profile_saved", "embedding_status": "processing"}
