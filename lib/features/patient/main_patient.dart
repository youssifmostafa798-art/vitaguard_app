import 'package:flutter/material.dart';
import 'package:vitaguard_app/presentation/screens/vitals/hardware_screen.dart';
import 'package:vitaguard_app/presentation/screens/patient/chat_list_patient.dart';
import 'package:vitaguard_app/presentation/screens/patient/patient_home.dart';
import 'package:vitaguard_app/presentation/widgets/flexible_nav_bar.dart';
import 'package:vitaguard_app/presentation/screens/xray/upload_x_ray.dart';

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