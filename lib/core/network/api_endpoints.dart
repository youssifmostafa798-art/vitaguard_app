class ApiEndpoints {
  // Use http://10.0.2.2:8000/api/v1 for Android Emulator
  // Use http://localhost:8000/api/v1 for iOS/Web/Desktop
  static String baseUrl = "http://10.0.2.2:8000/api/v1";

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
  static const String patientProfile = "/patients/me";
  static const String medicalHistory = "/patients/me/medical-history";
  static const String dailyReports = "/patients/me/reports";
  static const String xrayAnalyze = "/patients/me/xray";
  static const String xrayHistory = "/patients/me/xray-results";
  static const String symptomLogs = "/patients/me/symptoms";
  static const String generateCompanionCode = "/patients/me/companion-code";

  // Doctors
  static const String assignedPatients = "/doctors/me/patients";
  static const String patientMedicalData =
      "/doctors/me/patients"; // /doctors/me/patients/{patient_id}/medical-data
  static const String postFeedback = "/doctors/me/feedback";

  // Companions
  static const String linkPatient = "/companions/me/link";
  static const String linkedPatients = "/companions/me/patients";
  static const String companionLink = linkPatient;
  static const String companionPatient = linkedPatients;

  // Facilities
  static const String facilityOffers = "/facilities/me/offers";
  static const String appointments = "/facilities/me/appointments";
  static const String facilityTests = "/facilities/me/tests";
  static const String facilityAppointments = appointments;

  // Chat
  static const String conversations = "/chat/conversations";
}



