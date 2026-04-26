def test_settings_load():
    import os
    os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://u:p@localhost/test")
    os.environ.setdefault("AUTH0_DOMAIN", "test.auth0.com")
    os.environ.setdefault("AUTH0_AUDIENCE", "https://test.api")
    from app.config import settings
    assert settings.MAX_MATCHES == 4
    assert settings.VECTOR_DIMENSIONS == 768
