import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vitaguard_app/auth/ui/auth_provider.dart';
import 'package:vitaguard_app/patient/ui/patient_provider.dart';
import 'package:vitaguard_app/doctor/ui/doctor_provider.dart';
import 'package:vitaguard_app/companion/ui/companion_provider.dart';
import 'package:vitaguard_app/facility/ui/facility_provider.dart';
import 'package:vitaguard_app/onbording/ui/onbording_screen/onboarding_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => CompanionProvider()),
        ChangeNotifierProvider(create: (_) => FacilityProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'WixMadeforDisplay'),
      home: OnboardingScreen(),
    );
  }
}
