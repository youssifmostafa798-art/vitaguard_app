import 'package:flutter/material.dart';
import 'package:vitaguard_app/onbording/ui/onbording_screen/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
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
