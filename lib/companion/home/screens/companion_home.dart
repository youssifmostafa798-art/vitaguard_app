import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/auth/ui/screens/role_screen.dart';
import 'package:vitaguard_app/companion/home/screens/alarts.dart';
import 'package:vitaguard_app/companion/home/widget/category_grid_companion.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/alerts/alert_model.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/patient/home/widget/home_search.dart';

class CompanionHome extends ConsumerWidget {
  final String name;

  const CompanionHome({super.key, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertCenter = ref.watch(alertCenterProvider);
    final criticalAlerts = alertCenter.criticalActiveAlerts;

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
                if (criticalAlerts.isNotEmpty) ...[
                  Gap(18.h),
                  _CompanionCriticalStrip(
                    primaryAlert: criticalAlerts.first,
                    additionalCount: criticalAlerts.length - 1,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const Alarts()),
                      );
                    },
                  ),
                ],
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

class _CompanionCriticalStrip extends StatelessWidget {
  const _CompanionCriticalStrip({
    required this.primaryAlert,
    required this.additionalCount,
    required this.onTap,
  });

  final AppAlert primaryAlert;
  final int additionalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFBE9E7), Color(0xFFFFF3F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFD84315), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD84315).withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFD84315).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: const Color(0xFFD84315),
                  size: 30.r,
                ),
              ),
              Gap(14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Immediate attention required',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(4.h),
                    Text(
                      primaryAlert.metricLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFD84315),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Gap(4.h),
                    Text(
                      primaryAlert.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.sp,
                        height: 1.35,
                      ),
                    ),
                    if (additionalCount > 0) ...[
                      Gap(8.h),
                      Text(
                        '+$additionalCount more active critical alert${additionalCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Gap(8.w),
              Icon(
                Icons.chevron_right_rounded,
                size: 28.r,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
