import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/core/feedback/clinical_feedback.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/data/models/patient/patient_models.dart';
import 'package:vitaguard_app/presentation/controllers/patient/patient_provider.dart';

import 'package:vitaguard_app/presentation/screens/vitals/hardware_screen.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/data/repositories/vitals/vitals_repository.dart';
import 'package:vitaguard_app/data/models/vitals/vitals_model.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';
import 'package:vitaguard_app/core/alerts/alert_model.dart';
import 'package:vitaguard_app/core/alerts/widgets/alert_card.dart';
import '../../../core/utils/custem_text.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/custem_bottom.dart';
import '../../../core/utils/custem_field.dart';

class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  final _heartRateCtrl = TextEditingController();
  final _oxygenCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();

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

  List<AppAlert> _getDemoAlerts() {
    return [
      AppAlert(
        id: 'demo-alert-1',
        patientId: 'patient-123',
        patientName: 'Ahmed Mahmoud',
        alertType: 'Elevated Heart Rate',
        message: 'Patient\'s heart rate has been > 100 bpm for 15 minutes.',
        severity: AlertSeverity.critical,
        occurredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        lastSeenAt: DateTime.now(),
        source: 'Bracelet Monitor',
        isAcknowledged: false,
        isResolved: false,
        metrics: const ['HR: 105 bpm'],
        payload: const {},
        recipientRole: 'companion',
      ),
      AppAlert(
        id: 'demo-alert-2',
        patientId: 'patient-123',
        patientName: 'Ahmed Mahmoud',
        alertType: 'SpO2 Warning',
        message: 'SpO2 level dropped below 92%.',
        severity: AlertSeverity.warning,
        occurredAt: DateTime.now().subtract(const Duration(minutes: 45)),
        lastSeenAt: DateTime.now(),
        source: 'Daily Report',
        isAcknowledged: true,
        isResolved: false,
        metrics: const ['SpO2: 91%'],
        payload: const {},
        recipientRole: 'companion',
      ),
    ];
  }

  void _handleSave() async {
    final report = DailyReport(
      heartRate: double.tryParse(_heartRateCtrl.text) ?? 0,
      oxygenLevel: double.tryParse(_oxygenCtrl.text) ?? 0,
      temperature: double.tryParse(_tempCtrl.text) ?? 0,
      bloodPressure: _bpCtrl.text.trim(),
    );

    final success = await ref
        .read(patientControllerProvider.notifier)
        .submitDailyReport(report);

    if (success) {
      if (!mounted) return;
      showClinicalPopup(
        context,
        type: ClinicalPopupType.success,
        title: 'Report Saved',
        message: 'Your daily report was saved successfully.',
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      final mapped = ErrorMapper.mapForUser(
        ref.read(patientControllerProvider).error ?? 'Failed to save report',
        const ClinicalErrorContext(area: ClinicalErrorArea.reports),
      );
      showClinicalPopup(
        context,
        type: ClinicalPopupType.error,
        title: 'Report Not Saved',
        message: mapped.message,
        developerDiagnostics: mapped.developerDiagnostics,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(patientControllerProvider).isLoading;

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

                      const Gap(30),

                      //Heart Rate (bpm)
                      CustemField(
                        title: "Heart Rate (bpm)",
                        hint: "e.g. 75",
                        controller: _heartRateCtrl,
                      ),

                      const Gap(20),

                      //Oxygen Level (%)
                      CustemField(
                        title: "Oxygen Level (%)",
                        hint: "e.g. 98",
                        controller: _oxygenCtrl,
                      ),

                      const Gap(20),

                      //Temperature (°C)
                      CustemField(
                        title: "Temperature (°C)",
                        hint: "e.g. 36.5",
                        controller: _tempCtrl,
                      ),

                      const Gap(20),

                      //Blood Pressure
                      CustemField(
                        title: "Blood Pressure",
                        hint: "e.g. 120/80",
                        controller: _bpCtrl,
                      ),

                      const Gap(40),

                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Button(title: "Save Report", onTap: _handleSave),

                      const Gap(40),

                      CustemText(
                        text: "Recent Alerts",
                        size: 22,
                        spacing: 3,
                        color: const Color(0xff003F6B),
                        weight: FontWeight.bold,
                      ),
                      const Gap(15),

                      // Demo Data indication for Companion logic fallback
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.h, left: 8.w),
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
                          return AlertCard(
                            alert: alert,
                            showPatientName: false,
                            onAcknowledge: null, // Read-only for Companion/Patient
                          );
                        },
                      ),

                      const Gap(30),
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
