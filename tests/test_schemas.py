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
