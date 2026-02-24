import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:vitaguard_app/doctor/home/widget/category_grid_dr.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/home_header.dart';
import 'package:vitaguard_app/patient/home/widget/home_search.dart';
import '../../ui/doctor_provider.dart';
import 'package:vitaguard_app/auth/ui/auth_provider.dart';
import 'package:vitaguard_app/auth/ui/screens/role_screen.dart';

class DoctorHomes extends StatefulWidget {
  final String name;
  const DoctorHomes({super.key, required this.name});

  @override
  State<DoctorHomes> createState() => _DoctorHomesState();
}

class _DoctorHomesState extends State<DoctorHomes> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().fetchAssignedPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeHeader(
        name_: widget.name,
        profileImage: const AssetImage("assets/PNG/doctor-patient 1.png"),
        onExit: () {
          context.read<AuthProvider>().logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RoleScreen()),
            (route) => false,
          );
        },
      ),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              children: [
                const Gap(20),
                const HomeSearch(),
                const Gap(25),
                const Gap(30),
                CategoryGridDr(drName: widget.name),
                const Gap(10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
