import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/alerts/widgets/alert_card.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/core/alerts/alert_center_provider.dart';

import '../../../core/utils/custem_background.dart';

class Alarts extends ConsumerWidget {
  const Alarts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertCenter = ref.watch(alertControllerProvider);
    final alerts = alertCenter.alerts;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const SimpleHeader(title: 'Alerts'),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 24.h),
                _AlertScreenHeader(
                  totalAlerts: alerts.length,
                  activeAlerts: ref
                      .read(alertControllerProvider)
                      .activeAlerts
                      .length,
                ),
                SizedBox(height: 18.h),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (ref.read(alertControllerProvider).isLoading &&
                          alerts.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (alerts.isEmpty) {
                        return _EmptyAlertState(
                          error: ref
                              .read(alertControllerProvider)
                              .error
                              ?.toString(),
                        );
                      }

                      return ListView.separated(
                        itemCount: alerts.length,
                        separatorBuilder: (_, _) => SizedBox(height: 14.h),
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return AlertCard(
                            alert: alert,
                            showPatientName: false,
                            onAcknowledge: alert.isActive
                                ? () {
                                    ref
                                        .read(alertControllerProvider.notifier)
                                        .acknowledgeAlert(alert.id);
                                  }
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertScreenHeader extends StatelessWidget {
  const _AlertScreenHeader({
    required this.totalAlerts,
    required this.activeAlerts,
  });

  final int totalAlerts;
  final int activeAlerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFF6F8FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
              size: 22.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$activeAlerts active',
                  style: TextStyle(
                    color: activeAlerts > 0
                        ? const Color(0xFFD84315)
                        : AppColors.textSecondary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$totalAlerts recent alerts',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _EmptyAlertState extends StatelessWidget {
  const _EmptyAlertState({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasError
                  ? Icons.wifi_off_rounded
                  : Icons.notifications_none_rounded,
              size: 60.r,
              color: hasError
                  ? const Color(0xFFD84315)
                  : AppColors.textSecondary.withValues(alpha: 0.65),
            ),
            SizedBox(height: 16.h),
            Text(
              hasError
                  ? 'Alert sync is temporarily unavailable'
                  : 'No alerts yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              hasError
                  ? error!
                  : 'Hardware and clinical alerts will appear here as soon as the backend publishes them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
