import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:vitaguard_app/auth/ui/auth_provider.dart';
import 'package:vitaguard_app/patient/ui/patient_provider.dart';
import 'package:vitaguard_app/doctor/ui/doctor_provider.dart';
import 'package:vitaguard_app/companion/ui/companion_provider.dart';
import 'package:vitaguard_app/facility/ui/facility_provider.dart';
import 'package:vitaguard_app/core/network/health_provider.dart';

final authProvider = legacy.ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});

final patientProvider = legacy.ChangeNotifierProvider<PatientProvider>((ref) {
  return PatientProvider();
});

final doctorProvider = legacy.ChangeNotifierProvider<DoctorProvider>((ref) {
  return DoctorProvider();
});

final companionProvider = legacy.ChangeNotifierProvider<CompanionProvider>((ref) {
  return CompanionProvider();
});

final facilityProvider = legacy.ChangeNotifierProvider<FacilityProvider>((ref) {
  return FacilityProvider();
});

final healthProvider = legacy.ChangeNotifierProvider<HealthProvider>((ref) {
  return HealthProvider();
});
