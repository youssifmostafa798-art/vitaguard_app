import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Override with: --dart-define=API_BASE_URL=http://host:port/api/v1
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }

    // Android emulator maps host machine localhost to 10.0.2.2
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }

    // iOS simulator, desktop, and most local dev setups.
    return 'http://localhost:8000/api/v1';
  }

  // Auth
  static const String login = "/auth/login";
  static const String registerPatient = "/auth/register/patient";
  static const String registerDoctor = "/auth/register/doctor";
  static const String registerCompanion = "/auth/register/companion";
  static const String registerFacility = "/auth/register/facility";
  static const String refreshToken = "/auth/refresh";
  static const String verifyAccount = "/auth/verify";
  static const String profile = "/auth/me";

  // Patients
  static const String patientProfile = "/patients/me/profile";
  static const String medicalHistory = "/patients/me/medical-history";
  static const String dailyReports = "/patients/me/daily-reports";
  static const String xrayAnalyze = "/patients/me/xray";
  static const String xrayHistory = "/patients/me/xray-results";
  static const String symptomLogs = "/patients/me/symptoms";
  static const String generateCompanionCode = "/patients/me/companion-code";
  static const String companionCodeRegenerate = "/patients/me/companion-code/regenerate";
  static const String patientDocuments = "/patients/me/documents";

  // Doctors
  static const String assignedPatients = "/doctors/patients";
  static const String patientMedicalData =
      "/doctors/patients"; // /doctors/patients/{patient_id}/medical-data
  static const String postFeedback = "/doctors/feedback";
  static const String doctorIdCard = "/doctors/me/id-card";
  static const String doctorVerificationStatus = "/doctors/me/verification-status";

  // Companions
  static const String linkPatient = "/companions/link";
  static const String linkedPatients = "/companions/patient";
  static const String companionLink = linkPatient;
  static const String companionPatient = linkedPatients;

  // Facilities
  static const String facilityOffers = "/facilities/offers";
  static const String appointments = "/facilities/appointments";
  static const String facilityTests = "/facilities/tests";
  static const String facilityAppointments = appointments;

  // Chat
  static const String conversations = "/chat/conversations";
}
