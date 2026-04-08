import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';

/// Fixed-position control: **AI Layer: OFF / ON** (default OFF at screen level).
class AiLayerToggle extends StatelessWidget {
  const AiLayerToggle({
    super.key,
    required this.aiLayerOn,
    required this.onChanged,
  });

  final bool aiLayerOn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              aiLayerOn ? 'AI Layer: ON' : 'AI Layer: OFF',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 8.w),
            Switch(
              value: aiLayerOn,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
