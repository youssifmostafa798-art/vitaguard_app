"""VitaGuard — Medical records CRUD service."""

from __future__ import annotations

from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.medical import DailyReport, MedicalFeedback, MedicalHistory, XRayResult


# ── Medical History ───────────────────────────────────────


async def get_medical_history(db: AsyncSession, patient_profile_id: str) -> list[MedicalHistory]:
    """Get all medical history entries for a patient."""
    result = await db.execute(
        select(MedicalHistory).where(MedicalHistory.patient_id == patient_profile_id)
    )
    return list(result.scalars().all())


async def upsert_medical_history(
    db: AsyncSession,
    patient_profile_id: str,
    *,
    chronic_diseases: str | None = None,
    medications: str | None = None,
    allergies: str | None = None,
    surgeries: str | None = None,
    notes: str | None = None,
) -> MedicalHistory:
    """Create or update the patient's medical history."""
    result = await db.execute(
        select(MedicalHistory).where(MedicalHistory.patient_id == patient_profile_id)
    )
    history = result.scalar_one_or_none()

    if history is None:
        history = MedicalHistory(patient_id=patient_profile_id)
        db.add(history)

    if chronic_diseases is not None:
        history.chronic_diseases = chronic_diseases
    if medications is not None:
        history.medications = medications
    if allergies is not None:
        history.allergies = allergies
    if surgeries is not None:
        history.surgeries = surgeries
    if notes is not None:
        history.notes = notes

    await db.flush()
    await db.refresh(history)
    return history


# ── Daily Reports ─────────────────────────────────────────


async def get_daily_reports(db: AsyncSession, patient_profile_id: str) -> list[DailyReport]:
    """Get all daily reports for a patient, newest first."""
    result = await db.execute(
        select(DailyReport)
        .where(DailyReport.patient_id == patient_profile_id)
        .order_by(DailyReport.created_at.desc())
    )
    return list(result.scalars().all())


async def get_daily_report_by_id(
    db: AsyncSession, report_id: str, patient_profile_id: str
) -> DailyReport | None:
    """Get a single daily report by ID."""
    result = await db.execute(
        select(DailyReport).where(
            DailyReport.id == report_id,
            DailyReport.patient_id == patient_profile_id,
        )
    )
    return result.scalar_one_or_none()


async def create_daily_report(
    db: AsyncSession,
    patient_profile_id: str,
    *,
    report_date: date,
    heart_rate: float,
    oxygen_level: float,
    temperature: float,
    blood_pressure: str,
    tasks_activities: str = "-",
    notes: str = "",
) -> DailyReport:
    """Create a new daily report."""
    report = DailyReport(
        patient_id=patient_profile_id,
        report_date=report_date,
        heart_rate=heart_rate,
        oxygen_level=oxygen_level,
        temperature=temperature,
        blood_pressure=blood_pressure,
        tasks_activities=tasks_activities,
        notes=notes,
    )
    db.add(report)
    await db.flush()
    return report


# ── X-Ray Results ─────────────────────────────────────────


async def get_xray_results(db: AsyncSession, patient_profile_id: str) -> list[XRayResult]:
    """Get all X-ray results for a patient, newest first."""
    result = await db.execute(
        select(XRayResult)
        .where(XRayResult.patient_id == patient_profile_id)
        .order_by(XRayResult.created_at.desc())
    )
    return list(result.scalars().all())


async def get_xray_result_by_id(db: AsyncSession, result_id: str) -> XRayResult | None:
    """Get a single X-ray result by ID."""
    result = await db.execute(select(XRayResult).where(XRayResult.id == result_id))
    return result.scalar_one_or_none()


async def create_xray_result(
    db: AsyncSession,
    patient_profile_id: str,
    *,
    image_path: str,
    is_valid: bool,
    prediction: str | None = None,
    confidence: float | None = None,
    report_text: str | None = None,
) -> XRayResult:
    """Persist an X-ray analysis result."""
    xray = XRayResult(
        patient_id=patient_profile_id,
        image_path=image_path,
        is_valid=is_valid,
        prediction=prediction,
        confidence=confidence,
        report_text=report_text,
    )
    db.add(xray)
    await db.flush()
    return xray


# ── Medical Feedback ──────────────────────────────────────


async def create_medical_feedback(
    db: AsyncSession,
    *,
    doctor_id: str,
    patient_id: str,
    xray_result_id: str | None = None,
    feedback_text: str,
) -> MedicalFeedback:
    """Create a doctor → patient feedback entry."""
    feedback = MedicalFeedback(
        doctor_id=doctor_id,
        patient_id=patient_id,
        xray_result_id=xray_result_id,
        feedback_text=feedback_text,
    )
    db.add(feedback)
    await db.flush()
    return feedback


async def get_feedback_for_patient(
    db: AsyncSession, patient_profile_id: str
) -> list[MedicalFeedback]:
    """Get all feedback for a patient."""
    result = await db.execute(
        select(MedicalFeedback)
        .where(MedicalFeedback.patient_id == patient_profile_id)
        .order_by(MedicalFeedback.created_at.desc())
    )
    return list(result.scalars().all())
