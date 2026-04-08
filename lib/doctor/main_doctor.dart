import 'package:flutter/material.dart';
import 'package:vitaguard_app/Hardware/screen/hardware_screen.dart';
import 'package:vitaguard_app/doctor/chat/screen/chat_list_dr.dart';
import 'package:vitaguard_app/doctor/home/screen/doctor_home.dart';
import 'package:vitaguard_app/components/bottom_nav.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/doctor_x_ray_review_entry_screen.dart';

class MainDoctor extends StatefulWidget {
  final String name;

  const MainDoctor({super.key, required this.name});

  @override
  State<MainDoctor> createState() => _MainDoctorState();
}

class _MainDoctorState extends State<MainDoctor> {
  int currentIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      DoctorHomes(name: widget.name),
      ChatListDr(),
      const DoctorXRayReviewEntryScreen(),
      HardwareScreen(),
    ];
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
