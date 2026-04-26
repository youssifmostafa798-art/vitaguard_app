import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:vitaguard_app/core/alerts/alert_model.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';

class AppAlertCard extends StatelessWidget {
  const AppAlertCard({
    super.key,
    required this.alert,
    this.onAcknowledge,
    this.showPatientName = false,
    this.compact = false,
  });

  final AppAlert alert;
  final VoidCallback? onAcknowledge;
  final bool showPatientName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final severityColor = alert.isCritical
        ? const Color(0xFFD84315)
        : const Color(0xFFEF6C00);
    final surfaceColor = alert.isCritical
        ? const Color(0xFFFFF1ED)
        : const Color(0xFFFFF8E1);
    final timestampLabel = DateFormat(
      compact ? 'MMM d, HH:mm' : 'MMM d, yyyy - hh:mm a',
    ).format(alert.occurredAt);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14.w : 16.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: severityColor.withValues(alpha: alert.isActive ? 0.7 : 0.35),
          width: alert.isActive ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: severityColor.withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 42.w : 48.w,
                height: compact ? 42.w : 48.w,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  alert.isCritical
                      ? Icons.warning_rounded
                      : Icons.notifications_active_rounded,
                  color: severityColor,
                  size: compact ? 24.r : 28.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _AlertPill(
                          label: alert.isCritical ? 'CRITICAL' : 'WARNING',
                          textColor: severityColor,
                          backgroundColor: severityColor.withValues(
                            alpha: 0.12,
                          ),
                        ),
                        _AlertPill(
                          label: alert.isActive ? 'ACTIVE' : 'ACKNOWLEDGED',
                          textColor: alert.isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          backgroundColor: alert.isActive
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      alert.metricLabel,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: compact ? 15.sp : 16.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (showPatientName) ...[
                      SizedBox(height: 5.h),
                      Text(
                        alert.patientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    SizedBox(height: 6.h),
                    Text(
                      timestampLabel,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            alert.message,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: compact ? 13.sp : 14.sp,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onAcknowledge != null && alert.isActive) ...[
            SizedBox(height: 14.h),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onAcknowledge,
                icon: Icon(Icons.check_circle_outline_rounded, size: 18.r),
                label: const Text('Acknowledge'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: severityColor,
                  side: BorderSide(color: severityColor.withValues(alpha: 0.7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertPill extends StatelessWidget {
  const _AlertPill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
