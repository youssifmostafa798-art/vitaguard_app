"""VitaGuard — SQLAlchemy ORM model for patient medical documents."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.models.user import Base


def _generate_uuid() -> str:
    return str(uuid.uuid4())


class MedicalDocument(Base):
    """Patient-uploaded medical documents (PDFs, lab results, scans)."""

    __tablename__ = "medical_documents"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=_generate_uuid
    )
    patient_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("patient_profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    file_url: Mapped[str] = mapped_column(String(500), nullable=False)
    document_type: Mapped[str] = mapped_column(
        String(50), nullable=False
    )  # e.g. "pdf", "image"
    original_filename: Mapped[str] = mapped_column(
        String(255), nullable=False
    )
    uploaded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
