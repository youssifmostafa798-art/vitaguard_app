import 'package:flutter/material.dart';
import 'package:vitaguard_app/facility/home.chat/screens/facility_home.dart';
import 'package:vitaguard_app/facility/report/reports.dart';
import 'package:vitaguard_app/facility/offer/current_offers.dart';
import 'package:vitaguard_app/components/special_bottom_nav.dart';

//edit
class MainFacility extends StatefulWidget {
  final String name;

  const MainFacility({super.key, required this.name});

  @override
  State<MainFacility> createState() => _MainFacilityState();
}

class _MainFacilityState extends State<MainFacility> {
  int currentIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [FacilityHome(name: widget.name), Reports(), CurrentOffers()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: SpecialBottomNav(
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



