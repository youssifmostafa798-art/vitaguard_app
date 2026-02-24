"""VitaGuard — Pydantic schemas for chat/messaging."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class ConversationCreateRequest(BaseModel):
    participant_ids: list[str] = Field(..., min_length=1)


class ConversationResponse(BaseModel):
    id: str
    created_at: datetime
    participant_ids: list[str] = []
    last_message: MessageResponse | None = None

    model_config = {"from_attributes": True}


class MessageCreateRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=5000)


class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    sender_id: str
    content: str
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}
