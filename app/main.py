from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy import text
from app.database import engine, Base
from app.routers import health, users, events, rsvp, feed, matches, status, bookmarks

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        await conn.run_sync(Base.metadata.create_all)
        for idx_sql in [
            "CREATE INDEX IF NOT EXISTS idx_users_embedding ON users USING hnsw (embedding vector_cosine_ops)",
            "CREATE INDEX IF NOT EXISTS idx_rsvps_intent ON rsvps USING hnsw (intent_embedding vector_cosine_ops)",
        ]:
            try:
                await conn.execute(text(idx_sql))
            except Exception:
                pass  # index may already exist in different form
    yield

app = FastAPI(title="Affiniti API", version="1.0", lifespan=lifespan)

@app.exception_handler(HTTPException)
async def http_exc_handler(request: Request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"error": "http_error", "message": exc.detail})

@app.exception_handler(RequestValidationError)
async def validation_exc_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(status_code=422, content={"error": "validation_error", "message": str(exc)})

@app.exception_handler(Exception)
async def generic_exc_handler(request: Request, exc: Exception):
    return JSONResponse(status_code=500, content={"error": "internal_error", "message": str(exc)})

app.include_router(health.router)
app.include_router(users.router)
app.include_router(events.router)
app.include_router(rsvp.router)
app.include_router(feed.router)
app.include_router(matches.router)
app.include_router(status.router)
app.include_router(bookmarks.router)
