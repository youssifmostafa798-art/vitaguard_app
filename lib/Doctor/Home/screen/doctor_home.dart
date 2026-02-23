import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/Doctor/Home/widget/category_grid_dr.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/core/home_header.dart';
import 'package:vitaguard_app/patient/Home/widget/home_search.dart';

class DoctorHomes extends StatelessWidget {
  final String name;
  const DoctorHomes({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeHeader(
        name_: name,
        profileImage: const AssetImage("assets/PNG/doctor-patient 1.png"),
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

                Gap(30),
                CategoryGridDr(drName: name),
                Gap(10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
