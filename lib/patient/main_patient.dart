import 'package:flutter/material.dart';
import 'package:vitaguard_app/patient/chat/screen/chat_list_patient.dart';
import 'package:vitaguard_app/patient/home/screen/patient_home.dart';
import 'package:vitaguard_app/patient/X_ray_Model/screen/upload_x_ray.dart';
import 'package:vitaguard_app/components/bottom_nav.dart';

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
    screens = [PatientHome(name: widget.name), ChatListPatient(), UploadXRay()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}



