import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';

/// Vital metric card with an optional animated status-color border.
///
/// Pass [statusColor] to highlight the card's border when the metric is
/// in a warning or critical state. Omit it (or pass null) for the normal
/// neutral border.
class MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String value;
  final String label;

  /// When non-null, the card border animates to this color (300 ms).
  /// Normal state: pass null → uses theme outline variant.
  final Color? statusColor;

  const MetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.value,
    required this.label,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    final borderColor = statusColor ??
        colorScheme.outlineVariant.withValues(alpha: 0.28);

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve:    Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color:        AppColors.cardBackground.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: borderColor,
            width: statusColor != null ? 2.0 : 1.0,
          ),
          boxShadow: statusColor != null
              ? [
                  BoxShadow(
                    color:      statusColor!.withValues(alpha: 0.18),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width:  40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
            SizedBox(height: 18.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: (textTheme.headlineSmall ?? const TextStyle()).copyWith(
                fontSize:   32.sp,
                fontWeight: FontWeight.w700,
                color:      statusColor ?? AppColors.textPrimary,
              ),
              child: Text(value),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontSize:    12.sp,
                fontWeight:  FontWeight.w500,
                letterSpacing: 0.3,
                color:       AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
