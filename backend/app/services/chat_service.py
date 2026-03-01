"""VitaGuard — Chat/messaging service."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.chat import Conversation, ConversationParticipant, Message
from app.models.user import User


async def get_user_conversations(db: AsyncSession, user_id: str) -> list[Conversation]:
    """Get all conversations for a user."""
    result = await db.execute(
        select(Conversation)
        .join(ConversationParticipant)
        .where(ConversationParticipant.user_id == user_id)
        .options(selectinload(Conversation.participants), selectinload(Conversation.messages))
        .order_by(Conversation.created_at.desc())
    )
    return list(result.scalars().unique().all())


async def create_conversation(
    db: AsyncSession, creator_id: str, participant_ids: list[str]
) -> Conversation:
    """Create a new conversation with the given participants."""
    # Ensure creator is included
    all_ids = list(set([creator_id, *participant_ids]))

    result = await db.execute(select(User.id).where(User.id.in_(all_ids)))
    existing_ids = set(result.scalars().all())
    missing_ids = sorted(set(all_ids) - existing_ids)
    if missing_ids:
        msg = f"Unknown participant IDs: {', '.join(missing_ids)}"
        raise ValueError(msg)

    conversation = Conversation()
    db.add(conversation)
    await db.flush()

    for uid in all_ids:
        db.add(ConversationParticipant(conversation_id=conversation.id, user_id=uid))

    await db.flush()

    # Reload with relationships
    result = await db.execute(
        select(Conversation)
        .where(Conversation.id == conversation.id)
        .options(selectinload(Conversation.participants))
    )
    return result.scalar_one()


async def get_conversation_messages(db: AsyncSession, conversation_id: str) -> list[Message]:
    """Get all messages in a conversation."""
    result = await db.execute(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.asc())
    )
    return list(result.scalars().all())


async def send_message(
    db: AsyncSession,
    conversation_id: str,
    sender_id: str,
    content: str,
) -> Message:
    """Send a message in an existing conversation."""
    message = Message(
        conversation_id=conversation_id,
        sender_id=sender_id,
        content=content,
    )
    db.add(message)
    await db.flush()
    return message


async def is_participant(db: AsyncSession, conversation_id: str, user_id: str) -> bool:
    """Check if a user is a participant in a conversation."""
    result = await db.execute(
        select(ConversationParticipant).where(
            ConversationParticipant.conversation_id == conversation_id,
            ConversationParticipant.user_id == user_id,
        )
    )
    return result.scalar_one_or_none() is not None
