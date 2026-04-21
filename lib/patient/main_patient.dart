import 'package:flutter/material.dart';
import 'package:vitaguard_app/Hardware/screen/hardware_screen.dart';
import 'package:vitaguard_app/patient/chat/screen/chat_list_patient.dart';
import 'package:vitaguard_app/patient/home/screen/patient_home.dart';
import 'package:vitaguard_app/components/flexible_nav_bar.dart';

import '../x_ray_model/screen/upload_x_ray.dart';

class MainPatient extends StatefulWidget {
  final String name;

  const MainPatient({super.key, required this.name});

  @override
  State<MainPatient> createState() => _MainPatientState();
}

class _MainPatientState extends State<MainPatient> {
  int currentIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    // FIX: Keep `screens` length aligned with bottom-nav tabs to prevent index overflow
    // when users open the Device tab (index 3).
    screens = [
      PatientHome(name: widget.name),
      ChatListPatient(),
      UploadXRay(),
      HardwareScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
