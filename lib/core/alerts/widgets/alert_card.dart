import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:vitaguard_app/core/alerts/alert_model.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    this.onAcknowledge,
    this.showPatientName = true,
    this.compact = false,
  });

  final AppAlert alert;
  final VoidCallback? onAcknowledge;
  final bool showPatientName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(alert);
    final textTheme = Theme.of(context).textTheme;
    final isActionable = alert.isActive && onAcknowledge != null;

    return Container(
      padding: EdgeInsets.all(compact ? 14.w : 18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.base.withValues(alpha: 0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: palette.base.withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.base.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                  color: palette.base.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  alert.isCritical ? Icons.warning_amber_rounded : Icons.info,
                  color: palette.base,
                  size: compact ? 22.sp : 24.sp,
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
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          alert.metricLabel,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: compact ? 15.sp : 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF17324D),
                          ),
                        ),
                        _SeverityChip(alert: alert, color: palette.base),
                      ],
                    ),
                    if (showPatientName) ...[
                      SizedBox(height: 4.h),
                      Text(
                        alert.patientName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: compact ? 12.sp : 13.sp,
                          color: const Color(0xFF536579),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                DateFormat('MMM d • h:mm a').format(alert.occurredAt),
                style: textTheme.labelMedium?.copyWith(
                  fontSize: compact ? 10.sp : 11.sp,
                  color: const Color(0xFF5E7287),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10.h : 12.h),
          Text(
            alert.message,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: compact ? 13.sp : 14.sp,
              color: const Color(0xFF26415A),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compact ? 12.h : 14.h),
          Row(
            children: [
              _StatePill(alert: alert, color: palette.base),
              const Spacer(),
              if (isActionable)
                FilledButton(
                  onPressed: onAcknowledge,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.base,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Acknowledge',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Text(
                  alert.isAcknowledged ? 'Acknowledged' : 'Resolved',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 12.sp,
                    color: palette.base,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  _AlertPalette _paletteFor(AppAlert alert) {
    if (alert.isCritical) {
      return const _AlertPalette(
        base: Color(0xFFC13A27),
        soft: Color(0xFFFFECE8),
      );
    }

    return const _AlertPalette(
      base: Color(0xFFB66A10),
      soft: Color(0xFFFFF4E2),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.alert, required this.color});

  final AppAlert alert;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        alert.isCritical ? 'CRITICAL' : 'WARNING',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.alert, required this.color});

  final AppAlert alert;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = alert.isActive
        ? (alert.isAcknowledged ? 'ACKNOWLEDGED' : 'ACTIVE')
        : 'RESOLVED';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: alert.isActive
            ? color.withValues(alpha: 0.10)
            : const Color(0xFFEFF3F7),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: alert.isActive ? color : const Color(0xFF6A7A8A),
        ),
      ),
    );
  }
}

class _AlertPalette {
  const _AlertPalette({required this.base, required this.soft});

  final Color base;
  final Color soft;
}
