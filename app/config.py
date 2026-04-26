from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str
    AUTH0_DOMAIN: str
    AUTH0_AUDIENCE: str
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    EMBED_MODEL: str = "nomic-embed-text"
    GENERALIZE_MODEL: str = "gemma3:4b"
    VECTOR_DIMENSIONS: int = 768
    STATUS_TTL_SECONDS: int = 3600
    BOOKMARK_RETENTION_DAYS: int = 7
    MAX_MATCHES: int = 4

    model_config = {"env_file": ".env"}

settings = Settings()
