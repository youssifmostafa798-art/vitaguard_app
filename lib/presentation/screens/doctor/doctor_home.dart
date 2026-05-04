import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/presentation/screens/auth/role_screen.dart';
import 'package:vitaguard_app/core/alerts/widgets/app_alert_card.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/presentation/widgets/doctor/category_grid_dr.dart';
import 'package:vitaguard_app/presentation/widgets/patient/home_search.dart';
import 'package:vitaguard_app/presentation/controllers/doctor/doctor_provider.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';
import 'package:vitaguard_app/core/alerts/alert_center_provider.dart';

import '../../../core/utils/custem_background.dart';

class DoctorHomes extends ConsumerWidget {
  final String name;

  const DoctorHomes({super.key, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctor = ref.watch(doctorControllerProvider);
    final alertCenter = ref.watch(alertControllerProvider);
    final criticalAlerts = alertCenter.criticalActiveAlerts;

    return Scaffold(
      appBar: HomeHeader(
        name_: name,
        onExit: () {
          ref.read(authControllerProvider.notifier).logout();
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
                if (criticalAlerts.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 15.h),
                    child: Column(
                      children: criticalAlerts.take(3).map((alert) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: AppAlertCard(
                            alert: alert,
                            showPatientName: true,
                            compact: true,
                            onAcknowledge: () {
                              ref
                                  .read(alertControllerProvider.notifier)
                                  .acknowledgeAlert(alert.id);
                            },
                          ),
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
                                ? 'Your identity verification is pending. Some features may be restricted.'
                                : 'Your identity verification was rejected. Please contact support.',
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
                CategoryGridDr(drName: name),
                Gap(10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
