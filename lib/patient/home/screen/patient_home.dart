import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/auth/ui/screens/role_screen.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/patient/home/widget/category_grid_patient.dart';
import 'package:vitaguard_app/patient/home/widget/home_search.dart';
import 'package:vitaguard_app/core/providers.dart';

class PatientHome extends ConsumerWidget {
  final String name;

  const PatientHome({super.key, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: HomeHeader(
        name_: name,

        onExit: () {
          ref.read(authProvider).logout();
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
                Gap(20),
                HomeSearch(),
                Gap(25),

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
