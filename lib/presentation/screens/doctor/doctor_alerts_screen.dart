import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/core/alerts/widgets/alert_card.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/core/alerts/alert_center_provider.dart';

/// Doctor-facing alert center — shows only critical alerts (severity routing
/// is enforced on the backend; this screen simply renders what the shared
/// [AlertCenterProvider] has already fetched for the doctor role).
class DoctorAlertsScreen extends ConsumerWidget {
  const DoctorAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertCenter = ref.watch(alertControllerProvider);
    final alerts = ref.read(alertControllerProvider).alerts; // already severity-filtered to critical for doctor

    return Scaffold(
      appBar: const SimpleHeader(title: 'Critical Alerts'),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 24.h),
                _DoctorAlertHeader(
                  activeCount: ref.read(alertControllerProvider).criticalActiveAlerts.length,
                  totalCount: alerts.length,
                ),
                SizedBox(height: 18.h),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (ref.read(alertControllerProvider).isLoading && alerts.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (alerts.isEmpty) {
                        return _EmptyDoctorAlerts(error: ref.read(alertControllerProvider).error?.toString());
                      }

                      return ListView.separated(
                        itemCount: alerts.length,
                        separatorBuilder: (_, _) => SizedBox(height: 14.h),
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return AlertCard(
                            alert: alert,
                            showPatientName: true,
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

// ── Header summary strip ──────────────────────────────────────────────────────

class _DoctorAlertHeader extends StatelessWidget {
  const _DoctorAlertHeader({
    required this.activeCount,
    required this.totalCount,
  });

  final int activeCount;
  final int totalCount;

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
              value: '$activeCount',
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
              label: 'Last 24 h',
              value: '$totalCount',
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyDoctorAlerts extends StatelessWidget {
  const _EmptyDoctorAlerts({this.error});

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
                  : Icons.shield_outlined,
              size: 60.r,
              color: hasError
                  ? const Color(0xFFD84315)
                  : AppColors.textSecondary.withValues(alpha: 0.65),
            ),
            SizedBox(height: 16.h),
            Text(
              hasError
                  ? 'Alert sync is temporarily unavailable'
                  : 'No critical alerts',
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
                  : 'Critical patient events will appear here in real time. Only severity-critical alerts are routed to the doctor role.',
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