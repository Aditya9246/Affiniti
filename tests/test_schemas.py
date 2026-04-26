def test_settings_load():
    import os
    os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://u:p@localhost/test")
    os.environ.setdefault("AUTH0_DOMAIN", "test.auth0.com")
    os.environ.setdefault("AUTH0_AUDIENCE", "https://test.api")
    from app.config import settings
    assert settings.MAX_MATCHES == 4
    assert settings.VECTOR_DIMENSIONS == 768


def test_models_import():
    import os
    os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://u:p@localhost/test")
    os.environ.setdefault("AUTH0_DOMAIN", "test.auth0.com")
    os.environ.setdefault("AUTH0_AUDIENCE", "https://test.api")
    from app.models import User, Event, RSVP, Match, Status, Bookmark
    assert User.__tablename__ == "users"
    assert Event.__tablename__ == "events"
    assert RSVP.__tablename__ == "rsvps"
    assert Match.__tablename__ == "matches"
    assert Status.__tablename__ == "statuses"
    assert Bookmark.__tablename__ == "bookmarks"


def test_user_profile_request_defaults():
    from app.schemas import UserProfileRequest
    req = UserProfileRequest(name="Alice")
    assert req.interests == []
    assert req.skills == []
    assert req.bio is None

def test_rsvp_request_fields():
    from app.schemas import RSVPRequest
    req = RSVPRequest(opted_in_fields=["name", "photo"])
    assert "name" in req.opted_in_fields

def test_status_request_valid():
    from app.schemas import StatusRequest
    req = StatusRequest(status="open_to_chat")
    assert req.status == "open_to_chat"


def test_auth_is_async():
    from app.auth import get_current_user
    import inspect
    assert inspect.iscoroutinefunction(get_current_user)

def test_jwks_cache_structure():
    from app.auth import _jwks_cache
    assert "keys" in _jwks_cache
    assert "expires_at" in _jwks_cache
