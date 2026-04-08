import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/Hardware/screen/metric_card.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';

class HardwareScreen extends StatelessWidget {
  const HardwareScreen({super.key});

  static const double _horizontalPadding = 24;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: AppBackground(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding.w,
                  vertical: 18.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEVICE LIVE STATUS',
                      style: textTheme.labelMedium?.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.primary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Container(
                          width: 11.w,
                          height: 11.w,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'VitaGuard Core',
                          style: textTheme.titleLarge?.copyWith(
                            fontSize: 38.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 34.h),
                    const _HeartRateRing(),
                    SizedBox(height: 24.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 18.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.26,
                          ),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: _StatusInfoItem(
                              title: 'Status',
                              value: 'Optimal',
                              valueColor: AppColors.success,
                            ),
                          ),
                          Expanded(
                            child: _StatusInfoItem(
                              title: 'Battery',
                              value: '88%',
                            ),
                          ),
                          Expanded(
                            child: _StatusInfoItem(
                              title: 'Signal',
                              value: 'Strong',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sensor Array',
                                style: textTheme.titleLarge?.copyWith(
                                  fontSize: 38.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Real-time peripheral metrics',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 18.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.wifi_tethering_rounded,
                          size: 30.sp,
                          color: AppColors.primary.withValues(alpha: 0.32),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        MetricCard(
                          icon: Icons.water_drop_rounded,
                          iconColor: const Color(0xFF0F766E),
                          iconBackgroundColor: const Color(0xFFD7F3EF),
                          value: '98%',
                          label: 'SPO2 (PPM)',
                        ),
                        SizedBox(width: 14.w),
                        MetricCard(
                          icon: Icons.device_thermostat_rounded,
                          iconColor: AppColors.primary,
                          iconBackgroundColor: const Color(0xFFE4EEFD),
                          value: '36.6\u00B0C',
                          label: 'BODY TEMP',
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartRateRing extends StatelessWidget {
  const _HeartRateRing();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Align(
      child: Container(
        width: 280.w,
        height: 280.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE6E8EE), width: 14.w),
        ),
        child: Center(
          child: Container(
            width: 214.w,
            height: 214.w,
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, color: AppColors.primary, size: 36.sp),
                SizedBox(height: 8.h),
                Text(
                  '72',
                  style: textTheme.displayMedium?.copyWith(
                    fontSize: 78.sp,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'BPM',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 22.sp,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
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

class _StatusInfoItem extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _StatusInfoItem({
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 18.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontSize: 24.sp,
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
