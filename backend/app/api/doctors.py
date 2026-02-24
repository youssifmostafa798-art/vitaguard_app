"""VitaGuard — Doctor API routes."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import CurrentUser, DbSession, require_role
from app.models.user import PatientProfile, UserRole
from app.schemas.medical import (
    DailyReportResponse,
    MedicalFeedbackCreateRequest,
    MedicalFeedbackResponse,
    MedicalHistoryResponse,
    XRayResultResponse,
)
from app.services import medical_service, user_service

router = APIRouter(prefix="/doctors", tags=["Doctors"])


def _require_doctor():
    return require_role(UserRole.DOCTOR)


# ── Assigned Patients ─────────────────────────────────────


@router.get("/patients")
async def list_assigned_patients(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_doctor()),
):
    """Get the doctor's assigned patients list."""
    patients = await user_service.get_assigned_patients(db, user.id)
    return [
        {
            "patient_id": p.user_id,
            "name": p.user.name if p.user else "Unknown",
            "age": p.age,
            "gender": p.gender,
        }
        for p in patients
    ]


# ── Review Patient Data ──────────────────────────────────


@router.get(
    "/patients/{patient_user_id}/medical-history", response_model=list[MedicalHistoryResponse]
)
async def get_patient_medical_history(
    patient_user_id: str,
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_doctor()),
):
    """Review a patient's medical history."""
    profile = await _get_assigned_patient(db, user.id, patient_user_id)
    records = await medical_service.get_medical_history(db, profile.id)
    return [MedicalHistoryResponse.model_validate(r) for r in records]


@router.get("/patients/{patient_user_id}/daily-reports", response_model=list[DailyReportResponse])
async def get_patient_daily_reports(
    patient_user_id: str,
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_doctor()),
):
    """Review a patient's daily reports."""
    profile = await _get_assigned_patient(db, user.id, patient_user_id)
    reports = await medical_service.get_daily_reports(db, profile.id)
    return [DailyReportResponse.model_validate(r) for r in reports]


@router.get("/patients/{patient_user_id}/xray-results", response_model=list[XRayResultResponse])
async def get_patient_xray_results(
    patient_user_id: str,
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_doctor()),
):
    """Review AI X-ray results for a patient."""
    profile = await _get_assigned_patient(db, user.id, patient_user_id)
    results = await medical_service.get_xray_results(db, profile.id)
    return [XRayResultResponse.model_validate(r) for r in results]


# ── Medical Feedback ──────────────────────────────────────


@router.post(
    "/feedback",
    response_model=MedicalFeedbackResponse,
    status_code=status.HTTP_201_CREATED,
)
async def send_feedback(
    data: MedicalFeedbackCreateRequest,
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_doctor()),
):
    """Send medical feedback to a patient (per flowchart)."""
    # Verify this patient is assigned to this doctor
    await _get_assigned_patient(db, user.id, data.patient_id)

    feedback = await medical_service.create_medical_feedback(
        db,
        doctor_id=user.id,
        patient_id=data.patient_id,
        xray_result_id=data.xray_result_id,
        feedback_text=data.feedback_text,
    )
    return MedicalFeedbackResponse.model_validate(feedback)


# ── Helpers ───────────────────────────────────────────────


async def _get_assigned_patient(db, doctor_user_id: str, patient_user_id: str) -> PatientProfile:
    """Verify the patient is assigned to the doctor, return their profile."""
    profile = await user_service.get_patient_profile(db, patient_user_id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Patient not found")
    if profile.assigned_doctor_id != doctor_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Patient not assigned to you",
        )
    return profile
