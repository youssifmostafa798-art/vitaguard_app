import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/presentation/screens/vitals/hardware_screen.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/presentation/controllers/doctor/doctor_provider.dart';

import '../../../core/utils/custem_background.dart';

enum DailyReportStatus { normal, warning, critical }

class DailyReportModel {
  final String id;
  final String patientName;
  final String date;
  final int pulse;
  final int ppm;
  final String temperature;
  final String motionStatus;
  final DailyReportStatus status;
  final String notes;

  const DailyReportModel({
    required this.id,
    required this.patientName,
    required this.date,
    required this.pulse,
    required this.ppm,
    required this.temperature,
    required this.motionStatus,
    required this.status,
    required this.notes,
  });
}

class DailyReports extends ConsumerStatefulWidget {
  const DailyReports({super.key});

  @override
  ConsumerState<DailyReports> createState() => _DailyReportsState();
}

class _DailyReportsState extends ConsumerState<DailyReports> {
  final TextEditingController _searchController = TextEditingController();
  DailyReportStatus? _statusFilter;
  bool _showDemoData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorControllerProvider.notifier).fetchAllDailyReports().then((
        _,
      ) {
        ref.read(doctorControllerProvider.notifier).listenToLiveVitals();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DailyReportModel> _convertToReportModels(
    List<Map<String, dynamic>> reports,
  ) {
    return reports.map((e) {
      final statusStr = e['status']?.toString().toLowerCase() ?? 'normal';
      DailyReportStatus status;
      if (statusStr == 'critical') {
        status = DailyReportStatus.critical;
      } else if (statusStr == 'warning') {
        status = DailyReportStatus.warning;
      } else {
        status = DailyReportStatus.normal;
      }

      return DailyReportModel(
        id: e['id']?.toString() ?? '',
        patientName: e['patientName']?.toString() ?? 'Unknown',
        date: e['date']?.toString() ?? '',
        pulse: (e['pulse'] as num?)?.toInt() ?? 0,
        ppm: (e['ppm'] as num?)?.toInt() ?? 0,
        temperature: e['temperature']?.toString() ?? '--',
        motionStatus: e['motionStatus']?.toString() ?? 'N/A',
        status: status,
        notes: e['notes']?.toString() ?? '',
      );
    }).toList();
  }

  List<DailyReportModel> _getFilteredReports(List<DailyReportModel> reports) {
    final q = _searchController.text.trim().toLowerCase();

    var list = reports;

    Iterable<DailyReportModel> filtered = list;
    if (q.isNotEmpty) {
      filtered = filtered.where((e) => e.patientName.toLowerCase().contains(q));
    }
    if (_statusFilter != null) {
      filtered = filtered.where((e) => e.status == _statusFilter);
    }

    // Sort by status priority: critical first, then warning, then normal
    final sorted = filtered.toList();
    sorted.sort((a, b) {
      final statusOrder = {
        DailyReportStatus.critical: 0,
        DailyReportStatus.warning: 1,
        DailyReportStatus.normal: 2,
      };
      return (statusOrder[a.status] ?? 3).compareTo(statusOrder[b.status] ?? 3);
    });
    return sorted;
  }

  int _getCriticalCount(List<DailyReportModel> reports) {
    return reports.where((r) => r.status == DailyReportStatus.critical).length;
  }

  int _getWarningCount(List<DailyReportModel> reports) {
    return reports.where((r) => r.status == DailyReportStatus.warning).length;
  }

  @override
  Widget build(BuildContext context) {
    final rawReports = ref.watch(doctorControllerProvider).dailyReports;
    final reports = _convertToReportModels(rawReports);
    final filtered = _getFilteredReports(reports);
    final textTheme = Theme.of(context).textTheme;
    final criticalCount = _getCriticalCount(reports);
    final warningCount = _getWarningCount(reports);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const SimpleHeader(title: "Daily Reports"),
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Gap(20.h),
                      // Quick Stats Section
                      _buildQuickStatsSection(
                        textTheme: textTheme,
                        totalReports: reports.length,
                        criticalCount: criticalCount,
                        warningCount: warningCount,
                      ),
                      Gap(24.h),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 15.sp,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search patient or ID...',
                          hintStyle: textTheme.bodyMedium?.copyWith(
                            fontSize: 15.sp,
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: 22.r,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.8),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1.2.w,
                            ),
                          ),
                        ),
                      ),
                      Gap(16.h),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All',
                              selected: _statusFilter == null,
                              onSelected: () =>
                                  setState(() => _statusFilter = null),
                            ),
                            Gap(8.w),
                            _buildFilterChip(
                              label: 'Normal',
                              selected:
                                  _statusFilter == DailyReportStatus.normal,
                              onSelected: () => setState(
                                () => _statusFilter = DailyReportStatus.normal,
                              ),
                            ),
                            Gap(8.w),
                            _buildFilterChip(
                              label: 'Warning',
                              selected:
                                  _statusFilter == DailyReportStatus.warning,
                              onSelected: () => setState(
                                () => _statusFilter = DailyReportStatus.warning,
                              ),
                            ),
                            Gap(8.w),
                            _buildFilterChip(
                              label: 'Critical',
                              selected:
                                  _statusFilter == DailyReportStatus.critical,
                              onSelected: () => setState(
                                () =>
                                    _statusFilter = DailyReportStatus.critical,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap(20.h),
                      // Reports Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Patient Reports',
                            style: textTheme.titleLarge?.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (filtered.isNotEmpty)
                            Text(
                              '${filtered.length}',
                              style: textTheme.labelMedium?.copyWith(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      Gap(12.h),
                      if (filtered.isEmpty)
                        _buildEmptyState(textTheme)
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final patient = filtered[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: _DailyReportCard(
                                model: patient,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => HardwareScreen(
                                        patientId: patient.id,
                                        patientName: patient.patientName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      Gap(24.h),
                      // Demo Data Section with Collapsible Header
                      _buildDemoSectionHeader(textTheme),
                      Gap(12.h),
                      if (_showDemoData) _buildDemoSection(textTheme),
                      Gap(20.h),
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

  //
  Widget _buildQuickStatsSection({
    required TextTheme textTheme,
    required int totalReports,
    required int criticalCount,
    required int warningCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: textTheme.labelSmall?.copyWith(
            fontSize: 11.sp,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Total Reports',
                value: totalReports.toString(),
                backgroundColor: const Color(0xFFF5F5F5),
                valueColor: AppColors.textPrimary,
                icon: Icons.assessment_outlined,
                textTheme: textTheme,
              ),
            ),
            Gap(10.w),
            Expanded(
              child: _buildStatCard(
                label: 'Critical',
                value: criticalCount.toString(),
                backgroundColor: const Color(0xFFFFEAEA),
                valueColor: const Color(0xFFC62828),
                icon: Icons.priority_high_rounded,
                textTheme: textTheme,
              ),
            ),
            Gap(10.w),
            Expanded(
              child: _buildStatCard(
                label: 'Warning',
                value: warningCount.toString(),
                backgroundColor: const Color(0xFFFFF3E0),
                valueColor: const Color(0xFFE65100),
                icon: Icons.warning_rounded,
                textTheme: textTheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color backgroundColor,
    required Color valueColor,
    required IconData icon,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.r, color: valueColor),
          Gap(8.h),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          Gap(4.h),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 10.sp,
              letterSpacing: 0.5,
              color: valueColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoSectionHeader(TextTheme textTheme) {
    return InkWell(
      onTap: () => setState(() => _showDemoData = !_showDemoData),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.science_outlined, color: AppColors.primary, size: 20.r),
            Gap(10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Data (For Demo)',
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                  Gap(2.h),
                  Text(
                    'Mock reports to demonstrate features',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _showDemoData
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: AppColors.primary,
              size: 22.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: const Color(0xFFF5F5F5),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56.r,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            Gap(16.h),
            Text(
              'No reports match your search',
              style: textTheme.titleMedium?.copyWith(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(8.h),
            Text(
              'Try a different name or filter',
              style: textTheme.bodySmall?.copyWith(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSection(TextTheme textTheme) {
    final List<DailyReportModel> mockReports = [
      const DailyReportModel(
        id: 'demo-1',
        patientName: 'Sara Ahmed',
        date: 'May 05, 2026',
        pulse: 72,
        ppm: 16,
        temperature: '98.4',
        motionStatus: 'Low',
        status: DailyReportStatus.normal,
        notes: 'Patient condition is stable. Vitals are within normal ranges.',
      ),
      const DailyReportModel(
        id: 'demo-2',
        patientName: 'Mohmmed Youssif',
        date: 'May 05, 2026',
        pulse: 110,
        ppm: 24,
        temperature: '101.8',
        motionStatus: 'High',
        status: DailyReportStatus.critical,
        notes:
            'Elevated temperature and heart rate. Needs immediate attention.',
      ),
      const DailyReportModel(
        id: 'demo-3',
        patientName: 'Eman Ali',
        date: 'May 05, 2026',
        pulse: 88,
        ppm: 18,
        temperature: '99.2',
        motionStatus: 'Moderate',
        status: DailyReportStatus.warning,
        notes: 'Improving, but keep monitoring mild fever.',
      ),
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mockReports.length,
      itemBuilder: (context, index) {
        final patient = mockReports[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _DailyReportCard(
            model: patient,
            isDemoData: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This is a demo report.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DailyReportCard extends StatelessWidget {
  const _DailyReportCard({
    required this.model,
    required this.onTap,
    this.isDemoData = false,
  });

  final DailyReportModel model;
  final VoidCallback onTap;
  final bool isDemoData;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Card(
          elevation: isDemoData ? 1 : 2,
          shadowColor: isDemoData ? Colors.black12 : Colors.black26,
          color: isDemoData
              ? AppColors.cardBackground.withValues(alpha: 0.7)
              : AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: isDemoData
                ? BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1.w,
                  )
                : BorderSide.none,
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.patientName,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Gap(6.h),
                          Text(
                            '${model.date} • ID ${model.id.toUpperCase()}',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 11.sp,
                              letterSpacing: 0.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: model.status),
                  ],
                ),
                Gap(12.h),
                Text(
                  model.notes,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(14.h),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.favorite_rounded,
                        label: 'PULSE',
                        value: model.pulse > 0 ? '${model.pulse}' : '--',
                        unit: model.pulse > 0 ? 'bpm' : '',
                        valueColor: AppColors.primary,
                      ),
                    ),
                    Gap(10.w),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.blur_on_rounded,
                        label: 'PPM',
                        value: model.ppm > 0 ? '${model.ppm}' : '--',
                        unit: '',
                        valueColor: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Gap(10.h),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.device_thermostat_rounded,
                        label: 'TEMP',
                        value: model.temperature.replaceAll('°F', ''),
                        unit: '°F',
                        valueColor: AppColors.textPrimary,
                      ),
                    ),
                    Gap(10.w),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.directions_walk_rounded,
                        label: 'MOTION',
                        value: model.motionStatus,
                        unit: '',
                        valueColor: _motionColor(model.motionStatus),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _motionColor(String motion) {
    final m = motion.toLowerCase();
    if (m == 'high') return const Color(0xFFB8860B);
    if (m == 'moderate') return AppColors.primary;
    return AppColors.textPrimary;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DailyReportStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (status) {
      case DailyReportStatus.normal:
        label = 'NORMAL';
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case DailyReportStatus.warning:
        label = 'WARNING';
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        break;
      case DailyReportStatus.critical:
        label = 'CRITICAL';
        bg = const Color(0xFFFFEAEA);
        fg = const Color(0xFFC62828);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: fg,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.r, color: AppColors.textSecondary),
              Gap(6.w),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10.sp,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Gap(8.h),
          RichText(
            text: TextSpan(
              style: textTheme.titleMedium?.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
              children: [
                TextSpan(text: value),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: valueColor.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
