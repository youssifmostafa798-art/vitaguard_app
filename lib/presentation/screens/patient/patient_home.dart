import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/presentation/screens/auth/role_screen.dart';
import 'package:vitaguard_app/presentation/screens/vitals/hardware_screen.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/presentation/widgets/patient/category_grid_patient.dart';
import 'package:vitaguard_app/presentation/widgets/patient/home_search.dart';
import 'package:vitaguard_app/presentation/screens/patient/chat_list_patient.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';
import 'package:vitaguard_app/presentation/controllers/patient/patient_provider.dart';
import 'package:vitaguard_app/data/repositories/vitals/vitals_repository.dart';
import 'package:vitaguard_app/data/models/vitals/vitals_model.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/custem_text.dart';

class PatientHome extends ConsumerStatefulWidget {
  final String name;

  const PatientHome({super.key, required this.name});

  @override
  ConsumerState<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends ConsumerState<PatientHome> {
  String _searchQuery = '';
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
      appBar: HomeHeader(
        name_: widget.name,
        onExit: () {
          ref.read(authControllerProvider.notifier).logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RoleScreen()),
            (route) => false,
          );
        },
      ),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ListView(
              children: [
                Gap(20.h),
                HomeSearch(
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),

                if (_searchQuery.isEmpty) ...[
                  Gap(20.h),
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
                  Gap(24.h),
                  _buildAvailableDoctorsList(),
                ],

                Gap(30.h),
                CategoryGridPatient(
                  patientName: widget.name,
                  searchQuery: _searchQuery,
                ),
                Gap(10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableDoctorsList() {
    final patientRepo = ref.read(patientControllerProvider.notifier).repository;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustemText(
          text: "Suggested Doctors",
          size: 22,
          spacing: 3,
          color: const Color(0xff003F6B),
          weight: FontWeight.bold,
        ),
        Gap(15.h),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: patientRepo.getAvailableDoctors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 160.h,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Center(
                  child: Text(
                    "Unable to load doctors at the moment.",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              );
            }

            final doctors = snapshot.data ?? [];
            if (doctors.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: 40.r,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      Gap(8.h),
                      Text(
                        "No doctors available",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 172.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doc = doctors[index];
                  return _DoctorSuggestionCard(
                    name: doc['name']?.toString() ?? 'Doctor',
                    specialization:
                        doc['specialization']?.toString() ??
                        'General Practitioner',
                    verificationStatus:
                        doc['verification_status']?.toString() ?? 'pending',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // detels
                          builder: (_) => const ChatListPatient(),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Latest vitals card ────────────────────────────────────────────────────────

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

// ─── Doctor suggestion card ───────────────────────────────────────────────────

class _DoctorSuggestionCard extends StatelessWidget {
  const _DoctorSuggestionCard({
    required this.name,
    required this.specialization,
    required this.verificationStatus,
    required this.onTap,
  });

  final String name;
  final String specialization;
  final String verificationStatus;
  final VoidCallback onTap;

  bool get isVerified => verificationStatus == 'approved';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140.w,
        margin: EdgeInsets.only(right: 14.w),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isVerified
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 32.r,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 32.r,
                  ),
                ),
                if (isVerified)
                  Container(
                    padding: EdgeInsets.all(2.r),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                      size: 18.r,
                    ),
                  ),
              ],
            ),
            Gap(10.h),
            Text(
              name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Gap(3.h),
            Text(
              specialization,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Gap(6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: isVerified
                    ? AppColors.pairedChipBg
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                isVerified ? 'Verified' : 'Pending',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: isVerified
                      ? AppColors.pairedChipText
                      : const Color(0xFFE65100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
