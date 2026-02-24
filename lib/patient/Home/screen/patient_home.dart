import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/home_header.dart';
import 'package:vitaguard_app/patient/home/widget/category_grid_patient.dart';
import 'package:vitaguard_app/patient/home/widget/home_search.dart';
import 'package:vitaguard_app/patient/home/widget/info_slider.dart';

class PatientHome extends StatelessWidget {
  final String name;

  const PatientHome({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeHeader(
        name_: name,
        profileImage: const AssetImage("assets/PNG/youth_14.png"),
        onExit: () {
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              children: [
                Gap(20),
                HomeSearch(),
                Gap(25),
                // Video / Slider
                InfoSlider(
                  images: [
                    'assets/PNG/2437635 1.png',
                    'assets/PNG/توعيه 1.png',
                    'assets/PNG/توعيه 2.png',
                    'assets/PNG/توعيه 3.png',
                  ],
                ),
                Gap(30),
                CategoryGridPatient(patientName: name),
                Gap(10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



