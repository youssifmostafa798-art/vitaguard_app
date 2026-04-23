import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/auth/ui/screens/role_screen.dart';
import 'package:vitaguard_app/companion/home/widget/category_grid_companion.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/patient/home/widget/home_search.dart';

class CompanionHome extends ConsumerStatefulWidget {
  final String name;

  const CompanionHome({super.key, required this.name});

  @override
  ConsumerState<CompanionHome> createState() => _CompanionHomeState();
}

class _CompanionHomeState extends ConsumerState<CompanionHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(companionProvider).fetchPatientStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeHeader(
        name_: widget.name,

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

                Gap(30.h),
                const CategoryGridCompanion(),
                Gap(10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
