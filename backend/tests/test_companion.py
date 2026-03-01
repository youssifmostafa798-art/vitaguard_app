import pytest
import pytest_asyncio
from httpx import AsyncClient


@pytest_asyncio.fixture
async def patient_and_companion_auth(client: AsyncClient):
    """Register a patient and companion, returning their auth tokens."""
    patient_res = await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "Companion Patient",
            "email": "comp.patient@example.com",
            "password": "password123",
            "age": 32,
            "gender": "female",
        },
    )
    patient_token = patient_res.json()["access_token"]

    patient_profile = await client.get(
        "/api/v1/patients/me/profile",
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    companion_code = patient_profile.json()["companion_code"]

    companion_res = await client.post(
        "/api/v1/auth/register/companion",
        json={"name": "Companion One", "companion_code": companion_code},
    )
    companion_token = companion_res.json()["access_token"]

    return companion_token, companion_code


@pytest.mark.asyncio
async def test_companion_link_endpoint(client: AsyncClient, patient_and_companion_auth):
    """Companion can (re)link to a patient with a valid companion code."""
    companion_token, companion_code = patient_and_companion_auth

    response = await client.post(
        "/api/v1/companions/link",
        json={"companion_code": companion_code},
        headers={"Authorization": f"Bearer {companion_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Companion linked successfully"
    assert "patient_id" in data
