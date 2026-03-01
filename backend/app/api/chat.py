"""VitaGuard — Chat API routes."""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, status

from app.dependencies import CurrentUser, DbSession
from app.schemas.chat import (
    ConversationCreateRequest,
    ConversationResponse,
    MessageCreateRequest,
    MessageResponse,
)
from app.services import chat_service

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.get("/conversations", response_model=list[ConversationResponse])
async def list_conversations(user: CurrentUser, db: DbSession):
    """Get all conversations for the authed user."""
    convos = await chat_service.get_user_conversations(db, user.id)
    results = []
    for c in convos:
        last_msg = c.messages[-1] if c.messages else None
        results.append(
            ConversationResponse(
                id=c.id,
                created_at=c.created_at,
                participant_ids=[p.id for p in c.participants],
                last_message=MessageResponse.model_validate(last_msg) if last_msg else None,
            )
        )
    return results


@router.post(
    "/conversations",
    response_model=ConversationResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_conversation(
    data: ConversationCreateRequest,
    user: CurrentUser,
    db: DbSession,
):
    """Start a new conversation."""
    try:
        convo = await chat_service.create_conversation(db, user.id, data.participant_ids)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return ConversationResponse(
        id=convo.id,
        created_at=convo.created_at,
        participant_ids=[p.id for p in convo.participants],
        last_message=None,
    )


@router.get("/conversations/{conversation_id}/messages", response_model=list[MessageResponse])
async def get_messages(conversation_id: str, user: CurrentUser, db: DbSession):
    """Get all messages in a conversation."""
    if not await chat_service.is_participant(db, conversation_id, user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a participant of this conversation",
        )
    messages = await chat_service.get_conversation_messages(db, conversation_id)
    return [MessageResponse.model_validate(m) for m in messages]


@router.post(
    "/conversations/{conversation_id}/messages",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def send_message(
    conversation_id: str,
    data: MessageCreateRequest,
    user: CurrentUser,
    db: DbSession,
):
    """Send a message in a conversation."""
    if not await chat_service.is_participant(db, conversation_id, user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a participant of this conversation",
        )
    message = await chat_service.send_message(db, conversation_id, user.id, data.content)
    return MessageResponse.model_validate(message)
