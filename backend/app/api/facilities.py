"""VitaGuard — Facility API routes."""

from __future__ import annotations

from datetime import datetime

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
    status,
)
from pydantic import BaseModel, Field

from app.config import settings
from app.dependencies import CurrentUser, DbSession, require_role
from app.models.facility import (
    Appointment,
    AppointmentStatus,
    FacilityOffer,
    MedicalTestUpload,
)
from app.models.user import UserRole
from app.services.file_service import (
    ALLOWED_DOCUMENT_EXTENSIONS,
    ALLOWED_IMAGE_EXTENSIONS,
    FileValidationError,
    validate_and_save,
)

router = APIRouter(prefix="/facilities", tags=["Facilities"])


def _require_facility():
    return require_role(UserRole.FACILITY)


# ── Schemas (local to facility routes) ────────────────────


class TestUploadResponse(BaseModel):
    id: str
    test_type: str
    file_path: str
    patient_id: str | None
    notes: str | None
    created_at: datetime
    model_config = {"from_attributes": True}


class AppointmentCreateRequest(BaseModel):
    patient_id: str
    doctor_id: str | None = None
    scheduled_at: datetime
    notes: str | None = None


class AppointmentResponse(BaseModel):
    id: str
    facility_id: str
    patient_id: str
    doctor_id: str | None
    scheduled_at: datetime
    status: str
    notes: str | None
    created_at: datetime
    model_config = {"from_attributes": True}


class AppointmentUpdateRequest(BaseModel):
    status: str | None = None
    scheduled_at: datetime | None = None
    notes: str | None = None


class OfferResponse(BaseModel):
    id: str
    facility_id: str
    title: str
    description: str
    image_url: str | None = None
    is_active: bool
    created_at: datetime
    model_config = {"from_attributes": True}


# ── Medical Test Uploads ──────────────────────────────────


@router.post("/tests", response_model=TestUploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_medical_test(
    user: CurrentUser,
    db: DbSession,
    test_type: str = Form(...),
    patient_id: str | None = Form(None),
    patient_phone: str | None = Form(None),
    notes: str | None = Form(None),
    file: UploadFile = File(...),
    _: None = Depends(_require_facility()),
):
    """Upload a medical test or report (per flowchart)."""

    # Resolve patient_id via phone if not provided directly
    if not patient_id and patient_phone:
        from sqlalchemy import select
        from app.models.user import User, PatientProfile
        
        result = await db.execute(
            select(PatientProfile.id)
            .join(User, User.id == PatientProfile.user_id)
            .where(User.phone == patient_phone)
        )
        patient_id = result.scalar_one_or_none()
        if not patient_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Patient with phone {patient_phone} not found"
            )

    content = await file.read()

    try:
        file_path = validate_and_save(
            content,
            file.filename or "test.pdf",
            subdirectory=f"lab_reports/{user.id}",
            allowed_extensions=ALLOWED_DOCUMENT_EXTENSIONS,
            max_bytes=settings.max_upload_bytes,
        )
    except FileValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(e)
        ) from e

    upload = MedicalTestUpload(
        facility_id=user.id,
        patient_id=patient_id,
        test_type=test_type,
        file_path=file_path,
        notes=notes,
    )
    db.add(upload)
    await db.flush()
    return TestUploadResponse.model_validate(upload)


@router.get("/tests", response_model=list[TestUploadResponse])
async def list_tests(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_facility()),
):
    """List all uploaded tests for this facility."""
    from sqlalchemy import select

    result = await db.execute(
        select(MedicalTestUpload)
        .where(MedicalTestUpload.facility_id == user.id)
        .order_by(MedicalTestUpload.created_at.desc())
    )
    return [TestUploadResponse.model_validate(t) for t in result.scalars().all()]


# ── Appointments ──────────────────────────────────────────


@router.post(
    "/appointments", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED
)
async def create_appointment(
    data: AppointmentCreateRequest,
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_facility()),
):
    """Create a new appointment."""
    appt = Appointment(
        facility_id=user.id,
        patient_id=data.patient_id,
        doctor_id=data.doctor_id,
        scheduled_at=data.scheduled_at,
        notes=data.notes,
    )
    db.add(appt)
    await db.flush()
    return AppointmentResponse.model_validate(appt)


@router.get("/appointments", response_model=list[AppointmentResponse])
async def list_appointments(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_facility()),
):
    """List all appointments for this facility."""
    from sqlalchemy import select

    result = await db.execute(
        select(Appointment)
        .where(Appointment.facility_id == user.id)
        .order_by(Appointment.scheduled_at.desc())
    )
    return [AppointmentResponse.model_validate(a) for a in result.scalars().all()]


@router.patch("/appointments/{appointment_id}", response_model=AppointmentResponse)
async def update_appointment(
    appointment_id: str,
    data: AppointmentUpdateRequest,
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_facility()),
):
    """Update an appointment (status, reschedule, notes)."""
    from sqlalchemy import select

    result = await db.execute(
        select(Appointment).where(
            Appointment.id == appointment_id,
            Appointment.facility_id == user.id,
        )
    )
    appt = result.scalar_one_or_none()
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if data.status is not None:
        try:
            appt.status = AppointmentStatus(data.status)
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid appointment status: {data.status}",
            ) from exc
    if data.scheduled_at is not None:
        appt.scheduled_at = data.scheduled_at
    if data.notes is not None:
        appt.notes = data.notes

    return AppointmentResponse.model_validate(appt)


# ── Medical Offers ────────────────────────────────────────


@router.post("/offers", response_model=OfferResponse, status_code=status.HTTP_201_CREATED)
async def create_offer(
    user: CurrentUser,
    db: DbSession,
    title: str = Form(...),
    description: str = Form(...),
    image: UploadFile | None = File(None),
    _: None = Depends(_require_facility()),
):
    """Create a medical offer with optional image."""
    image_url = None
    if image and image.filename:
        content = await image.read()
        try:
            image_url = validate_and_save(
                content,
                image.filename,
                subdirectory=f"offer_images/{user.id}",
                allowed_extensions=ALLOWED_IMAGE_EXTENSIONS,
                max_bytes=settings.max_upload_bytes,
            )
        except FileValidationError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail=str(e)
            ) from e

    offer = FacilityOffer(
        facility_id=user.id,
        title=title,
        description=description,
        image_url=image_url,
    )
    db.add(offer)
    await db.flush()
    return OfferResponse.model_validate(offer)


@router.get("/offers", response_model=list[OfferResponse])
async def list_offers(
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_facility()),
):
    """List all offers for this facility."""
    from sqlalchemy import select

    result = await db.execute(
        select(FacilityOffer)
        .where(FacilityOffer.facility_id == user.id)
        .order_by(FacilityOffer.created_at.desc())
    )
    return [OfferResponse.model_validate(o) for o in result.scalars().all()]


@router.delete("/offers/{offer_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_offer(
    offer_id: str,
    user: CurrentUser,
    db: DbSession,
    _: None = Depends(_require_facility()),
):
    """Delete (deactivate) a medical offer."""
    from sqlalchemy import select

    result = await db.execute(
        select(FacilityOffer).where(
            FacilityOffer.id == offer_id,
            FacilityOffer.facility_id == user.id,
        )
    )
    offer = result.scalar_one_or_none()
    if offer is None:
        raise HTTPException(status_code=404, detail="Offer not found")
    offer.is_active = False
