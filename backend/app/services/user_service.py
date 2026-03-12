"""VitaGuard — User CRUD service."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.user import (
    CompanionProfile,
    DoctorProfile,
    FacilityProfile,
    PatientProfile,
    User,
    UserRole,
)
from app.services.auth_service import hash_password


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    """Fetch a user by email."""
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def get_user_by_id(db: AsyncSession, user_id: str) -> User | None:
    """Fetch a user by ID with eager-loaded profile."""
    result = await db.execute(
        select(User)
        .where(User.id == user_id)
        .options(
            selectinload(User.patient_profile),
            selectinload(User.doctor_profile),
            selectinload(User.companion_profile),
            selectinload(User.facility_profile),
        )
    )
    return result.scalar_one_or_none()


async def get_patient_profile(db: AsyncSession, user_id: str) -> PatientProfile | None:
    """Fetch patient profile for a user."""
    result = await db.execute(
        select(PatientProfile)
        .where(PatientProfile.user_id == user_id)
        .options(
            selectinload(PatientProfile.medical_history),
            selectinload(PatientProfile.daily_reports),
            selectinload(PatientProfile.xray_results),
        )
    )
    return result.scalar_one_or_none()


async def get_patient_by_companion_code(db: AsyncSession, code: str) -> PatientProfile | None:
    """Find a patient by their companion code."""
    result = await db.execute(select(PatientProfile).where(PatientProfile.companion_code == code))
    return result.scalar_one_or_none()


async def create_patient(
    db: AsyncSession,
    *,
    name: str,
    email: str,
    password: str,
    age: int,
    phone: str | None,
    gender: str,
    chronic_diseases: str = "",
    medications: str = "",
    allergies: str = "",
) -> User:
    """Register a new patient user."""
    user = User(
        name=name,
        email=email,
        hashed_password=hash_password(password),
        role=UserRole.PATIENT,
        phone=phone,
    )
    db.add(user)
    await db.flush()

    profile = PatientProfile(
        user_id=user.id,
        age=age,
        gender=gender,
    )
    db.add(profile)
    await db.flush()

    # Create initial medical history
    from app.models.medical import MedicalHistory

    history = MedicalHistory(
        patient_id=profile.id,
        chronic_diseases=chronic_diseases,
        medications=medications,
        allergies=allergies,
        surgeries="",
        notes="",
    )
    db.add(history)
    return user


async def create_doctor(
    db: AsyncSession,
    *,
    name: str,
    email: str,
    password: str,
    age: int,
    phone: str | None,
    gender: str,
    professional_id: str,
) -> User:
    """Register a new doctor user."""
    user = User(
        name=name,
        email=email,
        hashed_password=hash_password(password),
        role=UserRole.DOCTOR,
        phone=phone,
    )
    db.add(user)
    await db.flush()

    profile = DoctorProfile(
        user_id=user.id,
        age=age,
        gender=gender,
        professional_id=professional_id,
    )
    db.add(profile)
    return user


async def create_companion(
    db: AsyncSession,
    *,
    name: str,
    companion_code: str,
) -> User:
    """Register a companion and link to patient via companion code."""
    # Find the patient with this companion code
    patient = await get_patient_by_companion_code(db, companion_code)
    if patient is None:
        msg = "Invalid companion code"
        raise ValueError(msg)

    user = User(
        name=name,
        email=None,
        hashed_password=None,
        role=UserRole.COMPANION,
    )
    db.add(user)
    await db.flush()

    profile = CompanionProfile(
        user_id=user.id,
        linked_patient_id=patient.user_id,
    )
    db.add(profile)
    return user


async def create_facility(
    db: AsyncSession,
    *,
    name: str,
    email: str,
    password: str,
    phone: str | None,
    address: str,
    facility_type: str,
    record_image_url: str | None = None,
) -> User:
    """Register a new facility user."""
    user = User(
        name=name,
        email=email,
        hashed_password=hash_password(password),
        role=UserRole.FACILITY,
        phone=phone,
    )
    db.add(user)
    await db.flush()

    profile = FacilityProfile(
        user_id=user.id,
        address=address,
        facility_type=facility_type,
        record_image_url=record_image_url,
    )
    db.add(profile)
    return user


async def get_assigned_patients(db: AsyncSession, doctor_id: str) -> list[PatientProfile]:
    """Get all patients assigned to a doctor."""
    result = await db.execute(
        select(PatientProfile)
        .where(PatientProfile.assigned_doctor_id == doctor_id)
        .options(selectinload(PatientProfile.user))
    )
    return list(result.scalars().all())
