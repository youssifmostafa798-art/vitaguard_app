import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_patient(client: AsyncClient):
    """Test patient registration."""
    response = await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "John Patient",
            "email": "john.patient@example.com",
            "password": "securepassword123",
            "age": 30,
            "phone": "1234567890",
            "gender": "male",
            "chronic_diseases": "None",
            "medications": "None",
            "allergies": "None",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_register_doctor(client: AsyncClient):
    """Test doctor registration."""
    response = await client.post(
        "/api/v1/auth/register/doctor",
        json={
            "name": "Dr. Smith",
            "email": "dr.smith@example.com",
            "password": "securepassword123",
            "age": 45,
            "phone": "0987654321",
            "gender": "female",
            "professional_id": "MD12345",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data


@pytest.mark.asyncio
async def test_login_patient(client: AsyncClient):
    """Test patient login."""
    # First register
    await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "Jane Patient",
            "email": "jane.patient@example.com",
            "password": "securepassword123",
            "age": 25,
            "phone": "1122334455",
            "gender": "female",
        },
    )

    # Then login
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "jane.patient@example.com", "password": "securepassword123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data


@pytest.mark.asyncio
async def test_login_invalid_credentials(client: AsyncClient):
    """Test login with invalid credentials."""
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": "nonexistent@example.com", "password": "wrongpassword"},
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid email or password"


@pytest.mark.asyncio
async def test_get_current_user_profile(client: AsyncClient):
    """Test retrieving current user's profile."""
    # Register and get tokens
    reg_response = await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "Alice Patient",
            "email": "alice.patient@example.com",
            "password": "securepassword123",
            "age": 28,
            "phone": "5556667777",
            "gender": "female",
        },
    )
    access_token = reg_response.json()["access_token"]

    # Get profile
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Alice Patient"
    assert data["email"] == "alice.patient@example.com"
    assert data["role"] == "patient"


@pytest.mark.asyncio
async def test_verify_account(client: AsyncClient):
    """Test account verification."""
    # Register
    reg_response = await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "Bob Patient",
            "email": "bob.patient@example.com",
            "password": "securepassword123",
            "age": 35,
            "phone": "9998887777",
            "gender": "male",
        },
    )
    access_token = reg_response.json()["access_token"]

    # Check initial verification status
    me_response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert me_response.json()["is_verified"] is False

    # Verify
    verify_response = await client.post(
        "/api/v1/auth/verify",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert verify_response.status_code == 200
    assert verify_response.json()["message"] == "Account verified successfully"

    # Check updated verification status
    me_response_after = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert me_response_after.json()["is_verified"] is True
