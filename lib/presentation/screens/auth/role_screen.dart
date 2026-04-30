import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/presentation/screens/auth/companion_register_screen.dart';
import 'package:vitaguard_app/presentation/screens/auth/doctor_register_screen.dart';
import 'package:vitaguard_app/presentation/screens/auth/facility_register_screen.dart';
import 'package:vitaguard_app/presentation/screens/auth/patient_register_screen.dart';
import 'package:vitaguard_app/presentation/screens/auth/sign_in_screen.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/presentation/widgets/custem_bottom.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';
import 'package:vitaguard_app/presentation/widgets/custom_logo.dart';

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
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Column(
                    children: [
                      Gap(10.h),
                      VitaGuardLogo(size: 180.h),
                      Gap(20.h),
                      const CustemText(
                        text: "Choose Your Role",
                        color: Color(0xff003F6B),
                        size: 25,
                        weight: FontWeight.w900,
                      ),
                      Gap(20.h),
                      Padding(
                        padding: EdgeInsets.all(20.r),
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
                            Gap(20.h),
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
                            Gap(20.h),
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
                            Gap(20.h),
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
                            Gap(30.h),
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
