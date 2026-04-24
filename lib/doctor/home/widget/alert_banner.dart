import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/doctor/data/vital_alert_model.dart';

class AlertBanner extends StatelessWidget {
  final VitalAlert alert;
  final VoidCallback onDismiss;

  const AlertBanner({
    super.key,
    required this.alert,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = VitalThresholds.getSeverityColor(alert.severity);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(alert.severity),
            color: color,
            size: 24.r,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  _getTimeAgo(alert.timestamp),
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close, color: color, size: 20.r),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.warning_rounded;
      case AlertSeverity.warning:
        return Icons.info_outline_rounded;
      case AlertSeverity.sensorError:
        return Icons.sensors_off_rounded;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return "Just now";
    return "${diff.inMinutes}m ago";
  }
}
