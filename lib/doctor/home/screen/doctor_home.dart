import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/doctor/home/widget/category_grid_dr.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/patient/home/widget/home_search.dart';
import 'package:vitaguard_app/auth/ui/screens/role_screen.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/doctor/home/widget/alert_banner.dart';

class DoctorHomes extends ConsumerStatefulWidget {
  final String name;
  const DoctorHomes({super.key, required this.name});

  @override
  ConsumerState<DoctorHomes> createState() => _DoctorHomesState();
}

class _DoctorHomesState extends ConsumerState<DoctorHomes> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorProvider).fetchAssignedPatients();
      ref.read(doctorProvider).fetchVerificationStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctor = ref.watch(doctorProvider);

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
                if (doctor.activeAlerts.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 15.h),
                    child: Column(
                      children: doctor.activeAlerts.map((alert) {
                        return AlertBanner(
                          alert: alert,
                          onDismiss: () => doctor.dismissAlert(alert.id),
                        );
                      }).toList(),
                    ),
                  ),
                if (doctor.verificationStatus != 'approved')
                  Container(
                    margin: EdgeInsets.only(top: 10.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: doctor.verificationStatus == 'pending'
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: doctor.verificationStatus == 'pending'
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          doctor.verificationStatus == 'pending'
                              ? Icons.hourglass_empty
                              : Icons.error_outline,
                          size: 24.r,
                          color: doctor.verificationStatus == 'pending'
                              ? Colors.orange
                              : Colors.red,
                        ),
                        Gap(12.w),
                        Expanded(
                          child: Text(
                            doctor.verificationStatus == 'pending'
                                ? "Your identity verification is pending. Some features may be restricted."
                                : "Your identity verification was rejected. Please contact support.",
                            style: TextStyle(
                              color: doctor.verificationStatus == 'pending'
                                  ? Colors.orange[900]
                                  : Colors.red[900],
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Gap(20.h),
                const HomeSearch(),

                Gap(30.h),
                CategoryGridDr(drName: widget.name),
                Gap(10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
