import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/Hardware/screen/hardware_screen.dart';
import 'package:vitaguard_app/companion/home/screens/companion_home.dart';
import 'package:vitaguard_app/components/flexible_nav_bar.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/patient/chat/screen/chat_list_patient.dart';

import '../x_ray_model/screen/upload_x_ray.dart';

class MainCompanion extends ConsumerStatefulWidget {
  final String name;

  const MainCompanion({super.key, required this.name});

  @override
  ConsumerState<MainCompanion> createState() => _MainCompanionState();
}

class _MainCompanionState extends ConsumerState<MainCompanion> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final patientStatus = ref.watch(companionProvider).patientStatus;

    final List<Widget> screens = [
      CompanionHome(name: widget.name),
      ChatListPatient(),
      UploadXRay(),
      HardwareScreen(
        patientId: patientStatus?.patientId,
        patientName: patientStatus?.name,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: FlexibleNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        hiddenIndexes: [],
      ),
    );
  }
}
