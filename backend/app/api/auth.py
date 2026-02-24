"""VitaGuard — Authentication API routes."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser, DbSession
from app.models.user import UserRole
from app.schemas.auth import (
    CompanionLoginRequest,
    CompanionRegisterRequest,
    DoctorRegisterRequest,
    FacilityRegisterRequest,
    LoginRequest,
    MessageResponse,
    PatientRegisterRequest,
    RefreshRequest,
    TokenResponse,
)
from app.schemas.user import UserResponse
from app.services.auth_service import (
    create_token_pair,
    decode_token,
    verify_password,
)
from app.services.user_service import (
    create_companion,
    create_doctor,
    create_facility,
    create_patient,
    get_patient_by_companion_code,
    get_user_by_email,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


# ── Registration endpoints ────────────────────────────────


@router.post("/register/patient", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register_patient(data: PatientRegisterRequest, db: DbSession):
    """Register a new patient account."""
    existing = await get_user_by_email(db, data.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    user = await create_patient(
        db,
        name=data.name,
        email=data.email,
        password=data.password,
        age=data.age,
        phone=data.phone,
        gender=data.gender,
        chronic_diseases=data.chronic_diseases,
        medications=data.medications,
        allergies=data.allergies,
    )
    return create_token_pair(user.id, user.role.value)


@router.post("/register/doctor", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register_doctor(data: DoctorRegisterRequest, db: DbSession):
    """Register a new doctor account."""
    existing = await get_user_by_email(db, data.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    user = await create_doctor(
        db,
        name=data.name,
        email=data.email,
        password=data.password,
        age=data.age,
        phone=data.phone,
        gender=data.gender,
        professional_id=data.professional_id,
    )
    return create_token_pair(user.id, user.role.value)


@router.post(
    "/register/companion", response_model=TokenResponse, status_code=status.HTTP_201_CREATED
)
async def register_companion(data: CompanionRegisterRequest, db: DbSession):
    """Register a companion via patient's companion code."""
    try:
        user = await create_companion(
            db,
            name=data.name,
            companion_code=data.companion_code,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    return create_token_pair(user.id, user.role.value)


@router.post(
    "/register/facility", response_model=TokenResponse, status_code=status.HTTP_201_CREATED
)
async def register_facility(data: FacilityRegisterRequest, db: DbSession):
    """Register a new facility account."""
    existing = await get_user_by_email(db, data.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )
    user = await create_facility(
        db,
        name=data.name,
        email=data.email,
        password=data.password,
        phone=data.phone,
        address=data.address,
        facility_type=data.facility_type,
    )
    return create_token_pair(user.id, user.role.value)


# ── Login endpoints ───────────────────────────────────────


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: DbSession):
    """Authenticate with email and password."""
    user = await get_user_by_email(db, data.email)
    if user is None or not verify_password(data.password, user.hashed_password or ""):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated",
        )
    return create_token_pair(user.id, user.role.value)


@router.post("/login/companion", response_model=TokenResponse)
async def login_companion(data: CompanionLoginRequest, db: DbSession):
    """Authenticate a companion via name and companion code."""
    patient = await get_patient_by_companion_code(db, data.companion_code)
    if patient is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid companion code",
        )
    # Find companion linked to this patient with matching name
    from sqlalchemy import select
    from app.models.user import CompanionProfile, User

    result = await db.execute(
        select(User)
        .join(CompanionProfile, CompanionProfile.user_id == User.id)
        .where(
            CompanionProfile.linked_patient_id == patient.user_id,
            User.name == data.name,
        )
    )
    companion_user = result.scalar_one_or_none()
    if companion_user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid companion credentials",
        )
    return create_token_pair(companion_user.id, companion_user.role.value)


# ── Token management ──────────────────────────────────────


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(data: RefreshRequest, db: DbSession):
    """Refresh an access token using a valid refresh token."""
    try:
        payload = decode_token(data.refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
            )
        user_id = payload.get("sub")
        role = payload.get("role")
        return create_token_pair(user_id, role)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )


@router.post("/verify", response_model=MessageResponse)
async def verify_account(user: CurrentUser, db: DbSession):
    """Mark account as verified (Account Verification & Profile Setup)."""
    user.is_verified = True
    return MessageResponse(message="Account verified successfully")


@router.post("/logout", response_model=MessageResponse)
async def logout(user: CurrentUser):
    """Logout — client should discard tokens. Server-side token blacklisting can be added."""
    return MessageResponse(message="Successfully logged out")


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(user: CurrentUser):
    """Get the currently authenticated user's profile."""
    return UserResponse.model_validate(user)
