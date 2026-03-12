"""VitaGuard — Pydantic schemas for user profiles."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class UserResponse(BaseModel):
    """Public user data returned by API."""

    id: str
    email: str | None
    name: str
    phone: str | None
    role: str
    is_active: bool
    is_verified: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class PatientProfileResponse(BaseModel):
    """Patient profile data."""

    user: UserResponse
    age: int
    gender: str
    companion_code: str
    assigned_doctor_id: str | None = None

    model_config = {"from_attributes": True}


class PatientUpdateRequest(BaseModel):
    """Patient profile update."""

    name: str | None = Field(None, min_length=2, max_length=150)
    phone: str | None = Field(None, max_length=20)
    age: int | None = Field(None, ge=0, le=150)


class DoctorProfileResponse(BaseModel):
    """Doctor profile data."""

    user: UserResponse
    age: int
    gender: str
    professional_id: str
    verification_status: str = "pending"
    id_card_image_url: str | None = None

    model_config = {"from_attributes": True}


class CompanionProfileResponse(BaseModel):
    """Companion profile data."""

    user: UserResponse
    linked_patient_id: str | None

    model_config = {"from_attributes": True}


class FacilityProfileResponse(BaseModel):
    """Facility profile data."""

    user: UserResponse
    address: str
    facility_type: str
    record_image_url: str | None
    verification_status: str = "pending"

    model_config = {"from_attributes": True}
