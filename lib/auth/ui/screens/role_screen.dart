import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/auth/ui/screens/companion_register_screen.dart';
import 'package:vitaguard_app/auth/ui/screens/doctor_register_screen.dart';
import 'package:vitaguard_app/auth/ui/screens/facility_register_screen.dart';

import 'package:vitaguard_app/auth/ui/screens/patient_register_screen.dart';
import 'package:vitaguard_app/auth/ui/screens/sign_in_screen.dart';

import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/components/custom_logo.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      const Gap(10),
                      const VitaGuardLogo(size: 80),
                      const Gap(20),
                      const CustemText(
                        text: "Choose Your Role",
                        color: Color(0xff003F6B),
                        size: 25,
                        weight: FontWeight.w900,
                      ),
                      const Gap(20),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Button(
                              title: "Patient",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PatientRegisterScreen(),
                                  ),
                                );
                              },
                            ),
                            const Gap(20),
                            Button(
                              title: "Doctor",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const DoctorRegisterScreen(),
                                  ),
                                );
                              },
                            ),
                            const Gap(20),
                            Button(
                              title: "Companion",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CompanionRegisterScreen(),
                                  ),
                                );
                              },
                            ),
                            const Gap(20),
                            Button(
                              title: "Facility",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const FacilityRegisterScreen(),
                                  ),
                                );
                              },
                            ),
                            const Gap(30),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignInScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Already have an account? Sign In",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
