import pytest
import pytest_asyncio
from httpx import AsyncClient


@pytest_asyncio.fixture
async def users_auth(client: AsyncClient):
    """Register two patients to test chat."""
    u1 = await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "User 1",
            "email": "u1@example.com",
            "password": "password123",
            "age": 20,
            "gender": "male",
        },
    )
    u2 = await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "User 2",
            "email": "u2@example.com",
            "password": "password123",
            "age": 20,
            "gender": "male",
        },
    )

    t1 = u1.json()["access_token"]
    t2 = u2.json()["access_token"]

    id1 = (await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {t1}"})).json()[
        "id"
    ]
    id2 = (await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {t2}"})).json()[
        "id"
    ]

    return (t1, id1), (t2, id2)


@pytest.mark.asyncio
async def test_chat_flow(client: AsyncClient, users_auth):
    """Test conversation creation and messaging."""
    (t1, id1), (t2, id2) = users_auth

    # Create conversation
    response = await client.post(
        "/api/v1/chat/conversations",
        json={"participant_ids": [id2]},
        headers={"Authorization": f"Bearer {t1}"},
    )
    assert response.status_code == 201
    convo_id = response.json()["id"]

    # Send message from user 1
    msg_response = await client.post(
        f"/api/v1/chat/conversations/{convo_id}/messages",
        json={"content": "Hello User 2!"},
        headers={"Authorization": f"Bearer {t1}"},
    )
    assert msg_response.status_code == 201
    assert msg_response.json()["content"] == "Hello User 2!"

    # User 2 gets messages
    messages_response = await client.get(
        f"/api/v1/chat/conversations/{convo_id}/messages", headers={"Authorization": f"Bearer {t2}"}
    )
    assert messages_response.status_code == 200
    assert len(messages_response.json()) == 1
    assert messages_response.json()[0]["content"] == "Hello User 2!"


@pytest.mark.asyncio
async def test_chat_security(client: AsyncClient, users_auth):
    """Test that non-participants cannot access a conversation."""
    (t1, id1), (t2, id2) = users_auth

    # User 3 registered
    u3 = await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "User 3",
            "email": "u3@example.com",
            "password": "password123",
            "age": 20,
            "gender": "male",
        },
    )
    t3 = u3.json()["access_token"]

    # User 1 creates convo with User 2
    response = await client.post(
        "/api/v1/chat/conversations",
        json={"participant_ids": [id2]},
        headers={"Authorization": f"Bearer {t1}"},
    )
    convo_id = response.json()["id"]

    # User 3 tries to access
    access_response = await client.get(
        f"/api/v1/chat/conversations/{convo_id}/messages", headers={"Authorization": f"Bearer {t3}"}
    )
    assert access_response.status_code == 403


@pytest.mark.asyncio
async def test_create_conversation_with_unknown_user_fails(client: AsyncClient, users_auth):
    """Conversation creation should reject unknown participant IDs."""
    (t1, _), _ = users_auth
    response = await client.post(
        "/api/v1/chat/conversations",
        json={"participant_ids": ["missing-user-id"]},
        headers={"Authorization": f"Bearer {t1}"},
    )
    assert response.status_code == 400
    assert "Unknown participant IDs" in response.json()["detail"]
