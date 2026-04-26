import re
import time
import httpx
from jose import jwt, JWTError
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.config import settings
from app.database import get_db
from app.models import User

_jwks_cache: dict = {"keys": None, "expires_at": 0}
_DEMO_RE = re.compile(r"^demo-token-(\d+)$")

async def _get_jwks() -> list:
    if _jwks_cache["keys"] and time.time() < _jwks_cache["expires_at"]:
        return _jwks_cache["keys"]
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"https://{settings.AUTH0_DOMAIN}/.well-known/jwks.json")
        resp.raise_for_status()
    _jwks_cache["keys"] = resp.json()["keys"]
    _jwks_cache["expires_at"] = time.time() + 3600
    return _jwks_cache["keys"]

async def _get_or_create_demo_user(db: AsyncSession, auth0_id: str) -> User:
    result = await db.execute(select(User).where(User.auth0_id == auth0_id))
    user = result.scalar_one_or_none()
    if user is None:
        user = User(auth0_id=auth0_id, name=f"Demo User {auth0_id[-1]}")
        db.add(user)
        await db.commit()
        await db.refresh(user)
    return user

_bearer = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials

    if settings.DEMO_MODE:
        m = _DEMO_RE.match(token)
        if m:
            return await _get_or_create_demo_user(db, f"demo-user-{m.group(1)}")

    try:
        header = jwt.get_unverified_header(token)
        keys = await _get_jwks()
        rsa_key = next((k for k in keys if k.get("kid") == header.get("kid")), None)
        if not rsa_key:
            raise JWTError("No matching key")
        payload = jwt.decode(
            token,
            rsa_key,
            algorithms=["RS256"],
            audience=settings.AUTH0_AUDIENCE,
            issuer=f"https://{settings.AUTH0_DOMAIN}/",
        )
        auth0_id: str = payload["sub"]
    except JWTError as e:
        unverified = jwt.get_unverified_claims(token) if token.count(".") == 2 else {}
        print(f"[auth] JWTError: {e} | aud={unverified.get('aud')} iss={unverified.get('iss')}")
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    result = await db.execute(select(User).where(User.auth0_id == auth0_id))
    user = result.scalar_one_or_none()
    if user is None:
        user = User(auth0_id=auth0_id, name=auth0_id)
        db.add(user)
        await db.commit()
        await db.refresh(user)
    return user
