import 'package:flutter/material.dart';
import 'package:vitaguard_app/companion/home/screens/companion_home.dart';
import 'package:vitaguard_app/components/bottom_nav.dart';
import 'package:vitaguard_app/patient/chat/screen/chat_list_patient.dart';
import 'package:vitaguard_app/patient/X_ray_Model/screen/upload_x_ray.dart';

class MainCompanion extends StatefulWidget {
  final String name;

  const MainCompanion({super.key, required this.name});

  @override
  State<MainCompanion> createState() => _MainCompanionState();
}

class _MainCompanionState extends State<MainCompanion> {
  int currentIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      CompanionHome(name: widget.name),

      ChatListPatient(),
      UploadXRay(),
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



