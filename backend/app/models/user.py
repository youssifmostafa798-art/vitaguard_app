"""VitaGuard — SQLAlchemy ORM models for users and role-specific profiles."""

from __future__ import annotations

import enum
import secrets
import string
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Integer, String
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy.sql import func


class Base(DeclarativeBase):
    """Shared declarative base for all models."""


class UserRole(str, enum.Enum):
    """Enumeration of user roles matching the Flutter app."""

    PATIENT = "patient"
    DOCTOR = "doctor"
    COMPANION = "companion"
    FACILITY = "facility"


def _generate_uuid() -> str:
    return str(uuid.uuid4())


def _generate_companion_code() -> str:
    """Generate a 6-character alphanumeric companion code."""
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(6))


class User(Base):
    """Base user model — common fields for all roles."""

    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_generate_uuid)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, index=True, nullable=True)
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # ── Role-specific profiles (one-to-one) ───────────────
    patient_profile: Mapped[PatientProfile | None] = relationship(
        "PatientProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
        primaryjoin="User.id == PatientProfile.user_id",
    )
    doctor_profile: Mapped[DoctorProfile | None] = relationship(
        "DoctorProfile", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    companion_profile: Mapped[CompanionProfile | None] = relationship(
        "CompanionProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
        primaryjoin="User.id == CompanionProfile.user_id",
    )
    facility_profile: Mapped[FacilityProfile | None] = relationship(
        "FacilityProfile", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )


class PatientProfile(Base):
    """Patient-specific fields (age, gender, companion_code, assigned doctor)."""

    __tablename__ = "patient_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_generate_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    age: Mapped[int] = mapped_column(Integer, nullable=False)
    gender: Mapped[str] = mapped_column(String(10), nullable=False)
    companion_code: Mapped[str] = mapped_column(
        String(6), unique=True, default=_generate_companion_code, nullable=False
    )
    assigned_doctor_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("users.id"), nullable=True
    )

    # Relationships
    user: Mapped[User] = relationship(
        "User", back_populates="patient_profile", foreign_keys=[user_id]
    )
    assigned_doctor: Mapped[User | None] = relationship("User", foreign_keys=[assigned_doctor_id])
    medical_history: Mapped[list[MedicalHistory]] = relationship(
        "MedicalHistory", back_populates="patient", cascade="all, delete-orphan"
    )
    daily_reports: Mapped[list[DailyReport]] = relationship(
        "DailyReport", back_populates="patient", cascade="all, delete-orphan"
    )
    xray_results: Mapped[list[XRayResult]] = relationship(
        "XRayResult", back_populates="patient", cascade="all, delete-orphan"
    )


class DoctorProfile(Base):
    """Doctor-specific fields (age, gender, professional_id)."""

    __tablename__ = "doctor_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_generate_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    age: Mapped[int] = mapped_column(Integer, nullable=False)
    gender: Mapped[str] = mapped_column(String(10), nullable=False)
    professional_id: Mapped[str] = mapped_column(String(100), nullable=False)

    user: Mapped[User] = relationship("User", back_populates="doctor_profile")


class CompanionProfile(Base):
    """Companion-specific fields (linked patient via companion code)."""

    __tablename__ = "companion_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_generate_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    linked_patient_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("users.id"), nullable=True
    )

    user: Mapped[User] = relationship(
        "User", back_populates="companion_profile", foreign_keys=[user_id]
    )
    linked_patient: Mapped[User | None] = relationship("User", foreign_keys=[linked_patient_id])


class FacilityProfile(Base):
    """Facility-specific fields (address, type, record image)."""

    __tablename__ = "facility_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_generate_uuid)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    address: Mapped[str] = mapped_column(String(500), nullable=False)
    facility_type: Mapped[str] = mapped_column(String(100), nullable=False)
    record_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    user: Mapped[User] = relationship("User", back_populates="facility_profile")


# ── Forward-reference imports (resolved after class definitions) ──
from app.models.medical import DailyReport, MedicalHistory, XRayResult  # noqa: E402
