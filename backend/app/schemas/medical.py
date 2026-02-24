"""VitaGuard — Pydantic schemas for medical data."""

from __future__ import annotations

from datetime import date, datetime

from pydantic import BaseModel, Field


# ── Medical History ───────────────────────────────────────


class MedicalHistoryResponse(BaseModel):
    id: str
    chronic_diseases: str
    medications: str
    allergies: str
    surgeries: str
    notes: str
    updated_at: datetime

    model_config = {"from_attributes": True}


class MedicalHistoryUpdateRequest(BaseModel):
    chronic_diseases: str | None = None
    medications: str | None = None
    allergies: str | None = None
    surgeries: str | None = None
    notes: str | None = None


# ── Daily Report ──────────────────────────────────────────


class DailyReportCreateRequest(BaseModel):
    report_date: date
    heart_rate: float
    oxygen_level: float
    temperature: float
    blood_pressure: str
    tasks_activities: str = Field(
        "-", min_length=1
    )  # Defaulting since Flutter doesn't send this yet
    notes: str = ""


class DailyReportResponse(BaseModel):
    id: str
    report_date: date
    heart_rate: float
    oxygen_level: float
    temperature: float
    blood_pressure: str
    tasks_activities: str
    notes: str
    created_at: datetime

    model_config = {"from_attributes": True}


# ── X-Ray Result ─────────────────────────────────────────


class XRayResultResponse(BaseModel):
    id: str
    image_path: str
    is_valid: bool
    prediction: str | None
    confidence: float | None
    report_text: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Medical Feedback ──────────────────────────────────────


class MedicalFeedbackCreateRequest(BaseModel):
    patient_id: str
    xray_result_id: str | None = None
    feedback_text: str = Field(..., min_length=1)


class MedicalFeedbackResponse(BaseModel):
    id: str
    doctor_id: str
    patient_id: str
    xray_result_id: str | None
    feedback_text: str
    created_at: datetime

    model_config = {"from_attributes": True}
