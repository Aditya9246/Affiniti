from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str
    AUTH0_DOMAIN: str
    AUTH0_AUDIENCE: str
    EMBED_MODEL: str = "sentence-transformers/all-MiniLM-L6-v2"
    GENERALIZE_MODEL: str = "mlx-community/gemma-4-26b-a4b-it-4bit"
    VECTOR_DIMENSIONS: int = 384
    STATUS_TTL_SECONDS: int = 3600
    BOOKMARK_RETENTION_DAYS: int = 7
    MAX_MATCHES: int = 4

    model_config = {"env_file": ".env"}

settings = Settings()
