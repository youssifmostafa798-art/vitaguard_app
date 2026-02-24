"""VitaGuard — Models package. Imports all models for Alembic discovery."""

from app.models.chat import Conversation, ConversationParticipant, Message  # noqa: F401
from app.models.facility import Appointment, FacilityOffer, MedicalTestUpload  # noqa: F401
from app.models.medical import DailyReport, MedicalFeedback, MedicalHistory, XRayResult  # noqa: F401
from app.models.user import (  # noqa: F401
    Base,
    CompanionProfile,
    DoctorProfile,
    FacilityProfile,
    PatientProfile,
    User,
    UserRole,
)
