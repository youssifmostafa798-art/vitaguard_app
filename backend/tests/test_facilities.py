import pytest
import pytest_asyncio
from httpx import AsyncClient


@pytest_asyncio.fixture
async def facility_auth(client: AsyncClient):
    """Fixture to register a facility and return access token."""
    response = await client.post(
        "/api/v1/auth/register/facility",
        data={
            "name": "Radiology Center",
            "email": "facility@example.com",
            "password": "password123",
            "phone": "555-FAC",
            "address": "123 Medical Way",
            "facility_type": "Imaging Center",
        },
    )
    return response.json()["access_token"]


@pytest.mark.asyncio
async def test_facility_offers(client: AsyncClient, facility_auth):
    """Test facility offer management."""
    token = facility_auth

    # Create offer
    create_response = await client.post(
        "/api/v1/facilities/offers",
        data={"title": "50% off Chest X-rays", "description": "Summer discount"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert create_response.status_code == 201

    # List offers
    list_response = await client.get(
        "/api/v1/facilities/offers", headers={"Authorization": f"Bearer {token}"}
    )
    assert list_response.status_code == 200
    assert len(list_response.json()) == 1
    assert list_response.json()[0]["title"] == "50% off Chest X-rays"


@pytest.mark.asyncio
async def test_facility_appointments(client: AsyncClient, facility_auth):
    """Test facility appointment creation."""
    token = facility_auth

    # Register a patient to get their ID
    pat = await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "Patient P",
            "email": "p@example.com",
            "password": "password123",
            "age": 20,
            "gender": "male",
        },
    )
    pat_token = pat.json()["access_token"]
    pat_id = (
        await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {pat_token}"})
    ).json()["id"]

    from datetime import datetime, timedelta

    scheduled = (datetime.now() + timedelta(days=1)).isoformat()

    # Create appointment
    response = await client.post(
        "/api/v1/facilities/appointments",
        json={"patient_id": pat_id, "scheduled_at": scheduled, "notes": "Fasting required"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    assert response.json()["status"] == "pending"
