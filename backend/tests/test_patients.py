import pytest
import pytest_asyncio
from httpx import AsyncClient


@pytest_asyncio.fixture
async def patient_auth(client: AsyncClient):
    """Fixture to register a patient and return their access token."""
    response = await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "Test Patient",
            "email": "test.patient@example.com",
            "password": "password123",
            "age": 30,
            "gender": "male",
        },
    )
    return response.json()["access_token"]


@pytest.mark.asyncio
async def test_get_patient_profile(client: AsyncClient, patient_auth: str):
    """Test retrieving the authed patient's profile."""
    response = await client.get(
        "/api/v1/patients/me/profile",
        headers={"Authorization": f"Bearer {patient_auth}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["user"]["name"] == "Test Patient"
    assert "companion_code" in data
    assert len(data["companion_code"]) == 6


@pytest.mark.asyncio
async def test_medical_history_flow(client: AsyncClient, patient_auth: str):
    """Test the patient's medical history update and retrieval."""
    # Update
    update_response = await client.put(
        "/api/v1/patients/me/medical-history",
        json={"chronic_diseases": "Diabetes", "medications": "Insulin", "allergies": "Peanuts"},
        headers={"Authorization": f"Bearer {patient_auth}"},
    )
    assert update_response.status_code == 200
    assert update_response.json()["chronic_diseases"] == "Diabetes"

    # Get
    get_response = await client.get(
        "/api/v1/patients/me/medical-history",
        headers={"Authorization": f"Bearer {patient_auth}"},
    )
    assert get_response.status_code == 200
    records = get_response.json()
    assert len(records) > 0
    assert records[0]["chronic_diseases"] == "Diabetes"


@pytest.mark.asyncio
async def test_daily_reports_flow(client: AsyncClient, patient_auth: str):
    """Test creating and listing daily reports."""
    # Create
    from datetime import date

    create_response = await client.post(
        "/api/v1/patients/me/daily-reports",
        json={
            "report_date": str(date.today()),
            "tasks_activities": "Morning walk, medicine at 8am",
            "notes": "Feeling good today",
        },
        headers={"Authorization": f"Bearer {patient_auth}"},
    )
    assert create_response.status_code == 201

    # List
    list_response = await client.get(
        "/api/v1/patients/me/daily-reports",
        headers={"Authorization": f"Bearer {patient_auth}"},
    )
    assert list_response.status_code == 200
    assert len(list_response.json()) == 1
    assert list_response.json()[0]["tasks_activities"] == "Morning walk, medicine at 8am"


@pytest.mark.asyncio
async def test_upload_invalid_xray(client: AsyncClient, patient_auth: str):
    """Test X-ray upload validation (invalid file)."""
    # Create a dummy non-image file
    files = {"file": ("test.txt", b"this is not an image", "text/plain")}
    response = await client.post(
        "/api/v1/patients/me/xray",
        files=files,
        headers={"Authorization": f"Bearer {patient_auth}"},
    )
    # The API returns 201 Created but with is_valid=False for invalid images per flowchart logic
    assert response.status_code == 201
    data = response.json()
    assert data["is_valid"] is False
    assert "Invalid file type" in data["report_text"]
