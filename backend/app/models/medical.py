"""VitaGuard — SQLAlchemy ORM models for medical data."""

from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Float, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.models.user import Base


def _generate_uuid() -> str:
    return str(uuid.uuid4())


class MedicalHistory(Base):
    """Patient medical history (chronic diseases, medications, allergies)."""

    __tablename__ = "medical_histories"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_generate_uuid)
    patient_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False
    )
    chronic_diseases: Mapped[str] = mapped_column(Text, default="")
    medications: Mapped[str] = mapped_column(Text, default="")
    allergies: Mapped[str] = mapped_column(Text, default="")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    patient: Mapped[PatientProfile] = relationship(
        "PatientProfile", back_populates="medical_history"
    )


class DailyReport(Base):
    """Patient daily health report (per flowchart: Generate Daily Health Reports)."""

    __tablename__ = "daily_reports"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_generate_uuid)
    patient_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False
    )
    report_date: Mapped[date] = mapped_column(Date, nullable=False)
    tasks_activities: Mapped[str] = mapped_column(Text, default="")
    notes: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    patient: Mapped[PatientProfile] = relationship("PatientProfile", back_populates="daily_reports")


class XRayResult(Base):
    """X-ray analysis result (per flowchart: Is X-ray Valid → AI Model Analysis → Display Result)."""

    __tablename__ = "xray_results"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_generate_uuid)
    patient_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False
    )
    image_path: Mapped[str] = mapped_column(String(500), nullable=False)
    is_valid: Mapped[bool] = mapped_column(Boolean, default=True)
    prediction: Mapped[str | None] = mapped_column(String(50), nullable=True)
    confidence: Mapped[float | None] = mapped_column(Float, nullable=True)
    report_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    patient: Mapped[PatientProfile] = relationship("PatientProfile", back_populates="xray_results")


class MedicalFeedback(Base):
    """Doctor → Patient feedback (per flowchart: Send Medical Feedback)."""

    __tablename__ = "medical_feedbacks"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_generate_uuid)
    doctor_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    patient_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("patient_profiles.id", ondelete="CASCADE"), nullable=False
    )
    xray_result_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("xray_results.id"), nullable=True
    )
    feedback_text: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


# Resolve forward reference
from app.models.user import PatientProfile  # noqa: E402
