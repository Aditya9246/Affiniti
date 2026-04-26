import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, Text, Float, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID, JSONB, ARRAY
from pgvector.sqlalchemy import Vector
from app.database import Base

def _now():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    auth0_id = Column(Text, unique=True, nullable=False)
    name = Column(Text, nullable=False, default="")
    photo_url = Column(Text)
    bio = Column(Text)
    interests = Column(ARRAY(Text))
    hobbies = Column(Text)
    projects = Column(Text)
    skills = Column(ARRAY(Text))
    want_to_learn = Column(Text)
    github_url = Column(Text)
    linkedin_url = Column(Text)
    raw_profile = Column(JSONB)
    generalized_summary = Column(Text)
    embedding = Column(Vector(768))
    created_at = Column(DateTime(timezone=True), default=_now)
    updated_at = Column(DateTime(timezone=True), default=_now, onupdate=_now)

class Event(Base):
    __tablename__ = "events"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    host_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(Text, nullable=False)
    date = Column(DateTime(timezone=True))
    location = Column(Text)
    description = Column(Text)
    cover_image_url = Column(Text)
    created_at = Column(DateTime(timezone=True), default=_now)

class RSVP(Base):
    __tablename__ = "rsvps"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    event_id = Column(UUID(as_uuid=True), ForeignKey("events.id"), primary_key=True)
    opted_in_fields = Column(JSONB)
    intent_text = Column(Text)
    intent_embedding = Column(Vector(768))
    created_at = Column(DateTime(timezone=True), default=_now)

class Match(Base):
    __tablename__ = "matches"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    event_id = Column(UUID(as_uuid=True), ForeignKey("events.id"), nullable=False)
    matched_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    score = Column(Float)
    icebreaker_text = Column(Text)
    created_at = Column(DateTime(timezone=True), default=_now)
    __table_args__ = (UniqueConstraint("user_id", "event_id", "matched_user_id"),)

class Status(Base):
    __tablename__ = "statuses"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    event_id = Column(UUID(as_uuid=True), ForeignKey("events.id"), primary_key=True)
    status = Column(Text, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)

class Bookmark(Base):
    __tablename__ = "bookmarks"
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    event_id = Column(UUID(as_uuid=True), ForeignKey("events.id"), primary_key=True)
    bookmarked_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    created_at = Column(DateTime(timezone=True), default=_now)
