import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/auth/ui/screens/companion_register_screen.dart';
import 'package:vitaguard_app/auth/ui/screens/doctor_register_screen.dart';
import 'package:vitaguard_app/auth/ui/screens/facility_register_screen.dart';

import 'package:vitaguard_app/auth/ui/screens/patient_register_screen.dart';

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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                Gap(5),
                VitaGuardLogo(size: 20),
                Gap(5),
                CustemText(
                  text: "Choose Your Role",
                  color: Color(0xff003F6B),
                  size: 25,
                  weight: FontWeight.w900,
                ),
                Gap(5),

                Padding(
                  padding: EdgeInsets.all(50),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //patient
                      Button(
                        title: "Patient",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientRegisterScreen(),
                            ),
                          );
                        },
                      ),
                      Gap(20),
                      // Doctor
                      Button(
                        title: "Doctor",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorRegisterScreen(),
                            ),
                          );
                        },
                      ),
                      Gap(20),
                      //Companion
                      Button(
                        title: "Companion",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CompanionRegisterScreen(),
                            ),
                          );
                        },
                      ),
                      Gap(20),
                      // Facility
                      Button(
                        title: "Facility",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FacilityRegisterScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



