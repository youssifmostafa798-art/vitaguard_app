import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/presentation/screens/vitals/hardware_screen.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/data/repositories/vitals/vitals_repository.dart';
import 'package:vitaguard_app/data/models/vitals/vitals_model.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';
import '../../../core/utils/custem_text.dart';
import '../../../core/utils/custem_background.dart';

class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  PatientLiveVitals? _latestVitals;
  StreamSubscription? _vitalsSubscription;
  bool _isLoadingVitals = true;

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  @override
  void dispose() {
    _vitalsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadVitals() async {
    final uid = ref.read(authControllerProvider.notifier).currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _isLoadingVitals = false);
      return;
    }

    try {
      final vitals = await ref
          .read(vitalsRepositoryProvider)
          .getLatestVitals(uid);
      if (mounted) {
        setState(() {
          _latestVitals = vitals;
          _isLoadingVitals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVitals = false);
    }

    _vitalsSubscription = ref
        .read(vitalsRepositoryProvider)
        .subscribeToVitals(uid)
        .listen((vitals) {
          if (mounted) setState(() => _latestVitals = vitals);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(title: "Daily Report"),
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(20),

                      CustemText(
                        text: "Latest Vitals",
                        size: 22,
                        spacing: 3,
                        color: const Color(0xff003F6B),
                        weight: FontWeight.bold,
                      ),
                      const Gap(15),

                      _LatestVitalsCard(
                        vitals: _latestVitals,
                        isLoading: _isLoadingVitals,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HardwareScreen(),
                            ),
                          );
                        },
                      ),

                      Gap(30),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LatestVitalsCard extends StatelessWidget {
  const _LatestVitalsCard({
    required this.vitals,
    required this.isLoading,
    required this.onTap,
  });

  final PatientLiveVitals? vitals;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasData = vitals != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasData
                  ? [const Color(0xFF003F6B), const Color(0xFF1A5F8B)]
                  : [const Color(0xFF5A6B7D), const Color(0xFF7A8B9D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: hasData
                          ? const Color(0xFF4ADE80)
                          : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Gap(8.w),
                  Text(
                    hasData ? 'BRACELET LIVE' : 'BRACELET OFFLINE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (isLoading)
                    SizedBox(
                      width: 14.r,
                      height: 14.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white54,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white54,
                      size: 22.r,
                    ),
                ],
              ),
              Gap(16.h),
              Row(
                children: [
                  Expanded(
                    child: _VitalMetric(
                      icon: Icons.favorite_rounded,
                      iconColor: const Color(0xFFFF6B6B),
                      value: hasData ? '${vitals!.bpm}' : '--',
                      unit: 'BPM',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40.h,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  Expanded(
                    child: _VitalMetric(
                      icon: Icons.water_drop_rounded,
                      iconColor: const Color(0xFF4ADE80),
                      value: hasData ? '${vitals!.spo2}' : '--',
                      unit: 'SpO2%',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40.h,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  Expanded(
                    child: _VitalMetric(
                      icon: Icons.device_thermostat_rounded,
                      iconColor: const Color(0xFF60A5FA),
                      value: hasData
                          ? vitals!.temperature.toStringAsFixed(1)
                          : '--',
                      unit: '°C',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalMetric extends StatelessWidget {
  const _VitalMetric({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 18.r),
        Gap(6.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        Gap(2.h),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
