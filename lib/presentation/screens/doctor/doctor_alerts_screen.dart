import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/core/alerts/alert_model.dart';
import 'package:vitaguard_app/core/alerts/widgets/alert_card.dart';
import 'package:vitaguard_app/core/feedback/clinical_feedback.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/core/alerts/alert_center_provider.dart';

import '../../../core/utils/custem_background.dart';

/// Doctor-facing alert center — shows only critical alerts (severity routing
/// is enforced on the backend; this screen simply renders what the shared
/// [AlertCenterProvider] has already fetched for the doctor role).
class DoctorAlertsScreen extends ConsumerWidget {
  const DoctorAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertCenter = ref.watch(alertControllerProvider);
    final alerts =
        alertCenter.alerts; // already severity-filtered to critical for doctor

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
                  activeCount: alertCenter.criticalActiveAlerts.length,
                  totalCount: alerts.length,
                ),
                SizedBox(height: 18.h),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        if (alertCenter.isLoading && alerts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (alerts.isEmpty && !alertCenter.isLoading && alertCenter.error != null)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: _EmptyDoctorAlerts(
                              error: ErrorMapper.mapForUser(
                                alertCenter.error!,
                                const ClinicalErrorContext(
                                  area: ClinicalErrorArea.alerts,
                                ),
                              ).message,
                            ),
                          ),
                        if (alerts.isEmpty && !alertCenter.isLoading && alertCenter.error == null) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                            child: Row(
                              children: [
                                Icon(Icons.science_outlined, color: AppColors.primary, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'Sample Data (No active alerts)',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _getDemoAlerts().length,
                            separatorBuilder: (_, _) => SizedBox(height: 14.h),
                            itemBuilder: (context, index) {
                              final alert = _getDemoAlerts()[index];
                              return Stack(
                                children: [
                                  AlertCard(
                                    alert: alert,
                                    showPatientName: true,
                                    onAcknowledge:
                                        alert.isActive && !alert.isAcknowledged
                                        ? () {
                                            showClinicalPopup(
                                              context,
                                              type: ClinicalPopupType.success,
                                              title: 'Alert Acknowledged',
                                              message: 'Demo alert acknowledged.',
                                            );
                                          }
                                        : null,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                        if (alerts.isNotEmpty)
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: alerts.length,
                            separatorBuilder: (_, _) => SizedBox(height: 14.h),
                            itemBuilder: (context, index) {
                              final alert = alerts[index];
                              return AlertCard(
                                alert: alert,
                                showPatientName: true,
                                onAcknowledge: alert.isActive
                                    ? () {
                                        ref
                                            .read(
                                              alertControllerProvider.notifier,
                                            )
                                            .acknowledgeAlert(alert.id);
                                      }
                                    : null,
                              );
                            },
                          ),
                        SizedBox(height: 32.h),
                      ],
                    ),
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
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFFFF8F6),
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
              color: const Color(0xFFD84315).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.monitor_heart_rounded,
              color: const Color(0xFFD84315),
              size: 22.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$activeCount active',
                  style: TextStyle(
                    color: activeCount > 0
                        ? const Color(0xFFD84315)
                        : AppColors.textSecondary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$totalCount alerts in last 24h',
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
              hasError ? Icons.wifi_off_rounded : Icons.shield_outlined,
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

// ── Demo Data ─────────────────────────────────────────────────────────────────

List<AppAlert> _getDemoAlerts() {
  return [
    AppAlert(
      id: 'demo-1',
      patientId: 'p-1',
      patientName: 'Ahmed Mahmoud',
      alertType: 'Vitals Drop',
      severity: AlertSeverity.critical,
      metrics: const ['SpO2: 85%', 'HR: 110 bpm'],
      message:
          'Critical drop in oxygen saturation detected. Immediate attention required.',
      source: 'hardware',
      occurredAt: DateTime.now().subtract(const Duration(minutes: 2)),
      lastSeenAt: DateTime.now(),
      payload: const {},
      recipientRole: 'doctor',
      isAcknowledged: false,
      isResolved: false,
    ),
    AppAlert(
      id: 'demo-2',
      patientId: 'p-2',
      patientName: 'Sarah Samy',
      alertType: 'High Blood Pressure',
      severity: AlertSeverity.warning,
      metrics: const ['BP: 160/95 mmHg'],
      message:
          'Blood pressure is elevated above normal range. Monitor closely.',
      source: 'hardware',
      occurredAt: DateTime.now().subtract(const Duration(hours: 1)),
      lastSeenAt: DateTime.now(),
      payload: const {},
      recipientRole: 'doctor',
      isAcknowledged: true,
      isResolved: false,
      acknowledgedAt: DateTime.now().subtract(const Duration(minutes: 50)),
    ),
    AppAlert(
      id: 'demo-3',
      patientId: 'p-3',
      patientName: 'Mohamed Ali',
      alertType: 'Irregular Heartbeat',
      severity: AlertSeverity.critical,
      metrics: const ['Arrhythmia Detected'],
      message:
          'Multiple irregular heartbeat events detected in the last 30 minutes.',
      source: 'hardware',
      occurredAt: DateTime.now().subtract(const Duration(hours: 2)),
      lastSeenAt: DateTime.now(),
      payload: const {},
      recipientRole: 'doctor',
      isAcknowledged: false,
      isResolved: true,
      resolvedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];
}
