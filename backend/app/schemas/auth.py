"""VitaGuard — Pydantic schemas for authentication."""

from __future__ import annotations

from pydantic import BaseModel, EmailStr, Field


# ── Registration ──────────────────────────────────────────


class PatientRegisterRequest(BaseModel):
    """Patient registration payload."""

    name: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    age: int = Field(..., ge=0, le=150)
    phone: str | None = Field(None, max_length=20)
    gender: str = Field(..., pattern=r"^(male|female)$")
    # Medical history (optional at registration)
    chronic_diseases: str = ""
    medications: str = ""
    allergies: str = ""


class DoctorRegisterRequest(BaseModel):
    """Doctor registration payload."""

    name: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    age: int = Field(..., ge=0, le=150)
    phone: str | None = Field(None, max_length=20)
    gender: str = Field(..., pattern=r"^(male|female)$")
    professional_id: str = Field(..., min_length=1, max_length=100)


class CompanionRegisterRequest(BaseModel):
    """Companion registration — simplified code-based auth."""

    name: str = Field(..., min_length=2, max_length=150)
    companion_code: str = Field(..., min_length=6, max_length=6)


class FacilityRegisterRequest(BaseModel):
    """Facility registration payload."""

    name: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    phone: str | None = Field(None, max_length=20)
    address: str = Field(..., min_length=1, max_length=500)
    facility_type: str = Field(..., min_length=1, max_length=100)


# ── Login ─────────────────────────────────────────────────


class LoginRequest(BaseModel):
    """Standard email/password login."""

    email: EmailStr
    password: str


class CompanionLoginRequest(BaseModel):
    """Companion login via name + companion code."""

    name: str
    companion_code: str


# ── Token Response ────────────────────────────────────────


class TokenResponse(BaseModel):
    """JWT token pair returned on login/refresh."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    """Refresh token request."""

    refresh_token: str


# ── Verification ──────────────────────────────────────────


class VerifyAccountRequest(BaseModel):
    """Account verification & profile setup."""

    # Could be extended with OTP/code verification later
    pass


class MessageResponse(BaseModel):
    """Generic message response."""

    message: str
