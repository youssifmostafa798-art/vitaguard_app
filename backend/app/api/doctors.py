"""VitaGuard — Doctor API routes."""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.dependencies import CurrentUser, DbSession, require_role
from app.models.user import DoctorProfile, PatientProfile, UserRole, VerificationStatus
from app.schemas.medical import (
    DailyReportResponse,
    MedicalFeedbackCreateRequest,
    MedicalFeedbackResponse,
    MedicalHistoryResponse,
    XRayResultResponse,
)
from app.services import medical_service, user_service
from app.services.file_service import (
    ALLOWED_IMAGE_EXTENSIONS,
    FileValidationError,
    validate_and_save,
)

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


# ── Doctor ID Card Upload (Verification) ─────────────────


@router.post("/me/id-card", status_code=status.HTTP_201_CREATED)
async def upload_id_card(
    user: CurrentUser,
    db: DbSession,
    file: UploadFile = File(...),
    _: None = Depends(_require_doctor()),
):
    """Upload Medical Syndicate ID card image for verification."""
    content = await file.read()

    try:
        file_path = validate_and_save(
            content,
            file.filename or "id_card.jpg",
            subdirectory="doctor_id_cards",
            allowed_extensions=ALLOWED_IMAGE_EXTENSIONS,
            max_bytes=settings.max_upload_bytes,
        )
    except FileValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(e)
        )

    # Update doctor profile
    result = await db.execute(
        select(DoctorProfile).where(DoctorProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if profile is None:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    profile.id_card_image_url = file_path
    profile.verification_status = VerificationStatus.PENDING
    await db.flush()

    return {
        "message": "ID card uploaded successfully",
        "verification_status": profile.verification_status.value,
        "id_card_image_url": file_path,
    }


@router.get("/me/verification-status")
async def get_verification_status(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_doctor()),
):
    """Get the current verification status."""
    result = await db.execute(
        select(DoctorProfile).where(DoctorProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if profile is None:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    return {
        "verification_status": profile.verification_status.value,
        "id_card_image_url": profile.id_card_image_url,
        "reviewed_at": profile.reviewed_at.isoformat() if profile.reviewed_at else None,
    }


# ── Admin Review ─────────────────────────────────────────


class VerificationReviewRequest(BaseModel):
    status: str  # "approved" or "rejected"


@router.patch("/verification/{doctor_user_id}")
async def review_doctor_verification(
    doctor_user_id: str,
    data: VerificationReviewRequest,
    user: CurrentUser,
    db: DbSession,
):
    """Admin endpoint: approve or reject a doctor's verification."""
    try:
        new_status = VerificationStatus(data.status)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid status: {data.status}. Use 'approved' or 'rejected'.",
        )

    result = await db.execute(
        select(DoctorProfile).where(DoctorProfile.user_id == doctor_user_id)
    )
    profile = result.scalar_one_or_none()
    if profile is None:
        raise HTTPException(status_code=404, detail="Doctor not found")

    profile.verification_status = new_status
    profile.reviewed_by = user.id
    profile.reviewed_at = datetime.now(timezone.utc)
    await db.flush()

    return {
        "message": f"Doctor verification {new_status.value}",
        "doctor_user_id": doctor_user_id,
        "verification_status": new_status.value,
    }


# ── Helpers ───────────────────────────────────────────────


async def _get_assigned_patient(
    db: AsyncSession, doctor_user_id: str, patient_user_id: str
) -> PatientProfile:
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
