import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';

class ReviewProgressHeader extends StatelessWidget {
  const ReviewProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.subtitle,
  });

  final int currentStep;
  final int totalSteps;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = currentStep / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $currentStep of $totalSteps',
          style: textTheme.titleSmall?.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4.h,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 10.h),
          Text(
            subtitle!,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
