import 'package:flutter/material.dart';
import 'package:vitaguard_app/presentation/screens/facility/chat_list_facility.dart';
import 'package:vitaguard_app/features/facility/report/reports.dart';
import 'package:vitaguard_app/features/facility/offer/current_offers.dart';

import '../../core/utils/special_bottom_nav.dart';

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
    screens = [ChatListFacility(name: widget.name), Reports(), CurrentOffers()];
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
