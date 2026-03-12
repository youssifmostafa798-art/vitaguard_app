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


@router.get("/health/ai")
async def ai_health():
    """Check AI model loading status for X-ray analysis."""
    from app.services.xray_service import ensure_model_loaded

    try:
        interpreter = ensure_model_loaded()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        return {
            "status": "ready",
            "model_path": "model_optimized.tflite",
            "inputs": [{"name": d["name"], "shape": d["shape"].tolist()} for d in input_details],
            "outputs": [{"name": d["name"], "shape": d["shape"].tolist()} for d in output_details],
        }
    except Exception as e:
        return {"status": "error", "detail": f"Failed to load AI model: {e}"}
