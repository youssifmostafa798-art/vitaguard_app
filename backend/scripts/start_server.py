"""Service-safe backend launcher for VitaGuard."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import uvicorn


PROJECT_ROOT = Path(__file__).resolve().parent.parent


def _load_settings():
    """Load app settings after switching into project root."""
    os.chdir(PROJECT_ROOT)
    from app.config import settings

    return settings


def _run_migrations() -> None:
    """Apply Alembic migrations before app startup."""
    subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=str(PROJECT_ROOT),
        check=True,
    )


def main() -> None:
    """Run the API server with optional migration step."""
    settings = _load_settings()
    workers = settings.UVICORN_WORKERS

    if settings.AUTO_APPLY_MIGRATIONS:
        _run_migrations()

    if settings.UVICORN_RELOAD and workers > 1:
        workers = 1

    uvicorn.run(
        "app.main:app",
        host=settings.SERVER_HOST,
        port=settings.SERVER_PORT,
        workers=workers,
        reload=settings.UVICORN_RELOAD,
        log_level=settings.LOG_LEVEL.lower(),
    )


if __name__ == "__main__":
    main()
