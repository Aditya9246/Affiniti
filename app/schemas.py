from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime

class UserProfileRequest(BaseModel):
    name: str
    photo_url: Optional[str] = None
    bio: Optional[str] = None
    interests: list[str] = []
    hobbies: Optional[str] = None
    projects: Optional[str] = None
    skills: list[str] = []
    want_to_learn: Optional[str] = None
    github_url: Optional[str] = None
    linkedin_url: Optional[str] = None

class UserResponse(BaseModel):
    id: UUID
    name: str
    photo_url: Optional[str] = None
    bio: Optional[str] = None
    interests: list[str] = []
    skills: list[str] = []
    generalized_summary: Optional[str] = None
    model_config = {"from_attributes": True}

class HostResponse(BaseModel):
    id: UUID
    name: str
    photo_url: Optional[str] = None
    model_config = {"from_attributes": True}

class EventCreateRequest(BaseModel):
    name: str
    date: Optional[datetime] = None
    location: Optional[str] = None
    description: Optional[str] = None
    cover_image_url: Optional[str] = None

class EventResponse(BaseModel):
    id: UUID
    name: str
    date: Optional[datetime] = None
    location: Optional[str] = None
    description: Optional[str] = None
    cover_image_url: Optional[str] = None
    host: HostResponse
    rsvp_count: int
    user_rsvped: bool

class RSVPRequest(BaseModel):
    opted_in_fields: list[str]

class IntentRequest(BaseModel):
    intent_text: str

class StatusRequest(BaseModel):
    status: str

class StatusResponse(BaseModel):
    status: str
    expires_at: datetime

class BookmarkRequest(BaseModel):
    bookmarked_user_id: UUID

class FeedItemResponse(BaseModel):
    user_id: UUID
    name: Optional[str] = None
    photo_url: Optional[str] = None
    headline: Optional[str] = None
    shared_tags: list[str] = []
    status: Optional[str] = None
    looking_to_meet: bool
    bookmarked: bool
    similarity_score: float

class MatchResponse(BaseModel):
    matched_user_id: UUID
    name: Optional[str] = None
    photo_url: Optional[str] = None
    headline: Optional[str] = None
    shared_tags: list[str] = []
    icebreaker_text: str
    score: float
