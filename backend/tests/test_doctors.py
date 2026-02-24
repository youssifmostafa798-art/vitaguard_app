import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy import update
from app.models.user import PatientProfile


@pytest_asyncio.fixture
async def doctor_auth(client: AsyncClient):
    """Fixture to register a doctor and return their access token."""
    response = await client.post(
        "/api/v1/auth/register/doctor",
        json={
            "name": "Dr. House",
            "email": "house@example.com",
            "password": "password123",
            "age": 50,
            "gender": "male",
            "professional_id": "MD999",
        },
    )
    return response.json()["access_token"], "house@example.com"


@pytest_asyncio.fixture
async def patient_auth(client: AsyncClient):
    """Fixture to register a patient and return their access token."""
    response = await client.post(
        "/api/v1/auth/register/patient",
        json={
            "name": "Patient X",
            "email": "patient.x@example.com",
            "password": "password123",
            "age": 25,
            "gender": "female",
        },
    )
    return response.json()["access_token"], "patient.x@example.com"


@pytest.mark.asyncio
async def test_doctor_assigned_patients(client: AsyncClient, doctor_auth, patient_auth, db_session):
    """Test doctor listing and accessing assigned patients."""
    doc_token, doc_email = doctor_auth
    pat_token, pat_email = patient_auth

    # Get IDs
    doc_profile = (
        await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {doc_token}"})
    ).json()
    pat_profile_data = (
        await client.get(
            "/api/v1/patients/me/profile", headers={"Authorization": f"Bearer {pat_token}"}
        )
    ).json()

    pat_user_id = pat_profile_data["user"]["id"]
    doc_user_id = doc_profile["id"]

    # Assign patient to doctor in DB
    await db_session.execute(
        update(PatientProfile)
        .where(PatientProfile.user_id == pat_user_id)
        .values(assigned_doctor_id=doc_user_id)
    )
    await db_session.commit()

    # Doctor lists patients
    response = await client.get(
        "/api/v1/doctors/patients", headers={"Authorization": f"Bearer {doc_token}"}
    )
    assert response.status_code == 200
    patients = response.json()
    assert len(patients) == 1
    assert patients[0]["name"] == "Patient X"

    # Doctor reviews patient medical history
    history_response = await client.get(
        f"/api/v1/doctors/patients/{pat_user_id}/medical-history",
        headers={"Authorization": f"Bearer {doc_token}"},
    )
    assert history_response.status_code == 200


@pytest.mark.asyncio
async def test_send_medical_feedback(client: AsyncClient, doctor_auth, patient_auth, db_session):
    """Test doctor sending feedback to an assigned patient."""
    doc_token, _ = doctor_auth
    pat_token, _ = patient_auth

    pat_profile_data = (
        await client.get(
            "/api/v1/patients/me/profile", headers={"Authorization": f"Bearer {pat_token}"}
        )
    ).json()
    pat_user_id = pat_profile_data["user"]["id"]
    doc_user_id = (
        await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {doc_token}"})
    ).json()["id"]

    # Assign
    await db_session.execute(
        update(PatientProfile)
        .where(PatientProfile.user_id == pat_user_id)
        .values(assigned_doctor_id=doc_user_id)
    )
    await db_session.commit()

    # Send feedback
    response = await client.post(
        "/api/v1/doctors/feedback",
        json={"patient_id": pat_user_id, "feedback_text": "Please take your medications on time."},
        headers={"Authorization": f"Bearer {doc_token}"},
    )
    assert response.status_code == 201
    assert response.json()["feedback_text"] == "Please take your medications on time."


@pytest.mark.asyncio
async def test_doctor_access_unassigned_patient(client: AsyncClient, doctor_auth, patient_auth):
    """Test doctor attempting to access a patient NOT assigned to them."""
    doc_token, _ = doctor_auth
    pat_token, _ = patient_auth

    pat_profile_data = (
        await client.get(
            "/api/v1/patients/me/profile", headers={"Authorization": f"Bearer {pat_token}"}
        )
    ).json()
    pat_user_id = pat_profile_data["user"]["id"]

    # Attempt to review history
    response = await client.get(
        f"/api/v1/doctors/patients/{pat_user_id}/medical-history",
        headers={"Authorization": f"Bearer {doc_token}"},
    )
    assert response.status_code == 403
    assert "Patient not assigned to you" in response.json()["detail"]
