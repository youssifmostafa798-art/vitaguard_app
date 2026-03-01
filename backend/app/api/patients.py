"""VitaGuard — Patient API routes."""

from __future__ import annotations

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from app.config import settings
from app.dependencies import CurrentUser, DbSession, require_role
from app.models.user import UserRole
from app.schemas.medical import (
    DailyReportCreateRequest,
    DailyReportResponse,
    MedicalHistoryResponse,
    MedicalHistoryUpdateRequest,
    XRayResultResponse,
)
from app.schemas.user import PatientProfileResponse, PatientUpdateRequest
from app.services import medical_service, user_service, xray_service

router = APIRouter(prefix="/patients", tags=["Patients"])


def _require_patient():
    return require_role(UserRole.PATIENT)


# ── Profile ───────────────────────────────────────────────


@router.get("/me/profile", response_model=PatientProfileResponse)
async def get_my_profile(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_patient()),
):
    """Get the authed patient's profile."""
    profile = await user_service.get_patient_profile(db, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    return PatientProfileResponse(
        user=user,
        age=profile.age,
        gender=profile.gender,
        companion_code=profile.companion_code,
        assigned_doctor_id=profile.assigned_doctor_id,
    )


# ── Companion Code ────────────────────────────────────────


@router.get("/me/companion-code")
async def get_companion_code(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_patient()),
):
    """Get the patient's companion code for sharing."""
    profile = await user_service.get_patient_profile(db, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    return {"companion_code": profile.companion_code}


# ── Medical History ───────────────────────────────────────


@router.get("/me/medical-history", response_model=list[MedicalHistoryResponse])
async def get_medical_history(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_patient()),
):
    """Get the patient's medical history."""
    profile = await user_service.get_patient_profile(db, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    records = await medical_service.get_medical_history(db, profile.id)
    return [MedicalHistoryResponse.model_validate(r) for r in records]


@router.put("/me/medical-history", response_model=MedicalHistoryResponse)
async def update_medical_history(
    data: MedicalHistoryUpdateRequest,
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_patient()),
):
    """Update the patient's medical history."""
    profile = await user_service.get_patient_profile(db, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    history = await medical_service.upsert_medical_history(
        db,
        profile.id,
        chronic_diseases=data.chronic_diseases,
        medications=data.medications,
        allergies=data.allergies,
        surgeries=data.surgeries,
        notes=data.notes,
    )
    return MedicalHistoryResponse.model_validate(history)


# ── Daily Reports ─────────────────────────────────────────


@router.get("/me/daily-reports", response_model=list[DailyReportResponse])
async def list_daily_reports(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_patient()),
):
    """Get all daily reports for the authed patient."""
    profile = await user_service.get_patient_profile(db, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    reports = await medical_service.get_daily_reports(db, profile.id)
    return [DailyReportResponse.model_validate(r) for r in reports]


@router.post(
    "/me/daily-reports",
    response_model=DailyReportResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_daily_report(
    data: DailyReportCreateRequest,
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_patient()),
):
    """Create a new daily report."""
    profile = await user_service.get_patient_profile(db, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    report = await medical_service.create_daily_report(
        db,
        profile.id,
        report_date=data.report_date,
        heart_rate=data.heart_rate,
        oxygen_level=data.oxygen_level,
        temperature=data.temperature,
        blood_pressure=data.blood_pressure,
        tasks_activities=data.tasks_activities,
        notes=data.notes,
    )
    return DailyReportResponse.model_validate(report)


# ── X-Ray Upload & Analysis ──────────────────────────────


@router.post(
    "/me/xray",
    response_model=XRayResultResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_xray(
    user: CurrentUser,
    db: DbSession,
    file: UploadFile = File(...),
    _: None = Depends(_require_patient()),
):
    """Upload an X-ray image for AI analysis (per flowchart pipeline)."""
    # Read file content
    content = await file.read()
    if len(content) > settings.max_upload_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File too large. Maximum allowed size is {settings.MAX_UPLOAD_SIZE_MB} MB",
        )

    # Save to disk
    file_path = xray_service.save_uploaded_image(content, file.filename or "xray.jpg")

    # Step 1: Validate ("Is X-ray Valid?")
    is_valid, error_msg = xray_service.validate_xray_image(file_path)

    profile = await user_service.get_patient_profile(db, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Patient profile not found")

    if not is_valid:
        # Store invalid result and return
        result = await medical_service.create_xray_result(
            db,
            profile.id,
            image_path=file_path,
            is_valid=False,
            report_text=error_msg,
        )
        return XRayResultResponse.model_validate(result)

    # Step 2: Run AI inference
    inference = xray_service.run_inference(file_path)

    # Step 3: Store result
    result = await medical_service.create_xray_result(
        db,
        profile.id,
        image_path=file_path,
        is_valid=True,
        prediction=inference["prediction"],
        confidence=inference["confidence"],
        report_text=inference["report_text"],
    )
    return XRayResultResponse.model_validate(result)


@router.get("/me/xray-results", response_model=list[XRayResultResponse])
async def list_xray_results(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_patient()),
):
    """Get all X-ray results for the authed patient."""
    profile = await user_service.get_patient_profile(db, user.id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    results = await medical_service.get_xray_results(db, profile.id)
    return [XRayResultResponse.model_validate(r) for r in results]
