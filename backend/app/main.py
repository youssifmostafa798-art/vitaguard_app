"""
VitaGuard Backend — FastAPI Application Entry Point.

Secure healthcare backend with AI-powered X-ray analysis.
"""

from __future__ import annotations

import structlog
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api import auth, chat, companions, doctors, facilities, health, patients
from app.config import settings
from app.logging_config import setup_logging
from app.middleware import setup_middleware

# Initialize structured logging
setup_logging(settings.ENVIRONMENT)
logger = structlog.get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup / shutdown lifecycle."""
    # ── Startup ───────────────────────────────────────────
    logger.info("Starting VitaGuard Backend", env=settings.ENVIRONMENT)

    # Create database tables (dev only — use Alembic in production)
    if not settings.is_production:
        from app.database import engine
        from app.models import Base

        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database tables created (dev mode)")

    # Load TFLite model
    try:
        from app.services.xray_service import load_model

        load_model()
    except Exception:
        logger.exception("Failed to load TFLite model — X-ray inference disabled")

    yield

    # ── Shutdown ──────────────────────────────────────────
    logger.info("Shutting down VitaGuard Backend")


def create_app() -> FastAPI:
    """Application factory."""
    app = FastAPI(
        title="VitaGuard API",
        description="Secure healthcare backend with AI-powered X-ray analysis",
        version="1.0.0",
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # Middleware
    setup_middleware(app)

    # Routes
    api_prefix = "/api/v1"
    app.include_router(health.router)
    app.include_router(auth.router, prefix=api_prefix)
    app.include_router(patients.router, prefix=api_prefix)
    app.include_router(doctors.router, prefix=api_prefix)
    app.include_router(companions.router, prefix=api_prefix)
    app.include_router(facilities.router, prefix=api_prefix)
    app.include_router(chat.router, prefix=api_prefix)

    return app


app = create_app()
