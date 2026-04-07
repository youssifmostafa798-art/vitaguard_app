import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/auth/ui/screens/role_screen.dart';
import 'package:vitaguard_app/companion/home/widget/category_grid_companion.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/patient/home/widget/home_search.dart';
import 'package:vitaguard_app/patient/home/widget/info_slider.dart';
import 'package:vitaguard_app/core/providers.dart';

class CompanionHome extends ConsumerWidget {
  final String name;

  const CompanionHome({super.key, required this.name});

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
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ListView(
              children: [
                Gap(20.h),
                const HomeSearch(),
                Gap(25.h),
                InfoSlider(
                  images: [
                    'assets/PNG/2437635 1.png',
                    'assets/PNG/توعيه 1.png',
                    'assets/PNG/توعيه 2.png',
                    'assets/PNG/توعيه 3.png',
                  ],
                ),
                Gap(30.h),
                CategoryGridCompanion(companionName: name),
                Gap(10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
