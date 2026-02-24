"""VitaGuard — Companion API routes."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from app.dependencies import CurrentUser, DbSession, require_role
from app.models.user import UserRole
from app.schemas.medical import (
    DailyReportResponse,
    MedicalHistoryResponse,
)
from app.services import medical_service, user_service

router = APIRouter(prefix="/companions", tags=["Companions"])


def _require_companion():
    return require_role(UserRole.COMPANION)


@router.get("/patient")
async def get_linked_patient(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_companion()),
):
    """View linked patient's basic info."""
    profile = await user_service.get_patient_profile(db, _get_linked_patient_id(user))
    if profile is None:
        raise HTTPException(status_code=404, detail="Linked patient not found")
    return {
        "patient_id": profile.user_id,
        "name": profile.user.name if profile.user else "Unknown",
        "age": profile.age,
        "gender": profile.gender,
    }


@router.get("/patient/medical-history", response_model=list[MedicalHistoryResponse])
async def get_patient_medical_history(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_companion()),
):
    """View linked patient's medical history."""
    profile = await user_service.get_patient_profile(db, _get_linked_patient_id(user))
    if profile is None:
        raise HTTPException(status_code=404, detail="Linked patient not found")
    records = await medical_service.get_medical_history(db, profile.id)
    return [MedicalHistoryResponse.model_validate(r) for r in records]


@router.get("/patient/daily-reports", response_model=list[DailyReportResponse])
async def get_patient_daily_reports(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_companion()),
):
    """View linked patient's daily reports."""
    profile = await user_service.get_patient_profile(db, _get_linked_patient_id(user))
    if profile is None:
        raise HTTPException(status_code=404, detail="Linked patient not found")
    reports = await medical_service.get_daily_reports(db, profile.id)
    return [DailyReportResponse.model_validate(r) for r in reports]


def _get_linked_patient_id(user) -> str:
    """Extract the linked patient's user_id from companion profile."""
    if user.companion_profile and user.companion_profile.linked_patient_id:
        return user.companion_profile.linked_patient_id
    raise HTTPException(status_code=400, detail="No linked patient found")
