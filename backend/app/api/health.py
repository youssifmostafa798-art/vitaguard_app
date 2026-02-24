"""VitaGuard — Health check endpoints."""

from __future__ import annotations

from fastapi import APIRouter
from sqlalchemy import text

from app.database import async_session_factory

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health():
    """Basic liveliness check."""
    return {"status": "ok", "service": "vitaguard-backend"}


@router.get("/health/ready")
async def readiness():
    """Readiness check — verifies DB connectivity."""
    try:
        async with async_session_factory() as session:
            await session.execute(text("SELECT 1"))
        return {"status": "ready", "database": "connected"}
    except Exception as e:
        return {"status": "not_ready", "database": str(e)}
