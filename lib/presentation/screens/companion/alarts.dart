import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/core/alerts/widgets/alert_card.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/core/alerts/alert_center_provider.dart';

class Alarts extends ConsumerWidget {
  const Alarts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertCenter = ref.watch(alertControllerProvider);
    final alerts = ref.read(alertControllerProvider).alerts;

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
                  activeAlerts: ref.read(alertControllerProvider).activeAlerts.length,
                ),
                SizedBox(height: 18.h),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (ref.read(alertControllerProvider).isLoading && alerts.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (alerts.isEmpty) {
                        return _EmptyAlertState(error: ref.read(alertControllerProvider).error?.toString());
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
                                    ref.read(alertControllerProvider.notifier).acknowledgeAlert(alert.id);
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
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HeaderMetric(
              label: 'Active now',
              value: '$activeAlerts',
              valueColor: const Color(0xFFD84315),
            ),
          ),
          Container(
            width: 1,
            height: 42.h,
            color: AppColors.border.withValues(alpha: 0.8),
          ),
          Expanded(
            child: _HeaderMetric(
              label: 'Recent alerts',
              value: '$totalAlerts',
              valueColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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