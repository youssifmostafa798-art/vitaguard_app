import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:vitaguard_app/Hardware/screen/hardware_screen.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';

// ---------------------------------------------------------------------------
// Model & Status
// ---------------------------------------------------------------------------

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

  /// Builds a [DailyReportModel] from a Supabase row produced by
  /// [DoctorRepository.getAllAssignedPatientsDailyReports].
  factory DailyReportModel.fromMap(Map<String, dynamic> map) {
    DailyReportStatus status;
    switch ((map['status'] as String? ?? 'normal').toLowerCase()) {
      case 'critical':
        status = DailyReportStatus.critical;
        break;
      case 'warning':
        status = DailyReportStatus.warning;
        break;
      default:
        status = DailyReportStatus.normal;
    }

    return DailyReportModel(
      id: map['id']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? 'Unknown',
      date: map['date']?.toString() ?? '—',
      pulse: (map['pulse'] as num?)?.toInt() ?? 0,
      ppm: (map['ppm'] as num?)?.toInt() ?? 0,
      temperature: map['temperature']?.toString() ?? '—',
      motionStatus: map['motionStatus']?.toString() ?? 'N/A',
      status: status,
      notes: map['notes']?.toString() ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DailyReports extends ConsumerStatefulWidget {
  const DailyReports({super.key});

  @override
  ConsumerState<DailyReports> createState() => _DailyReportsState();
}

class _DailyReportsState extends ConsumerState<DailyReports> {
  final TextEditingController _searchController = TextEditingController();
  DailyReportStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorProvider).fetchAllDailyReports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DailyReportModel> _filtered(List<Map<String, dynamic>> raw) {
    final q = _searchController.text.trim().toLowerCase();
    Iterable<DailyReportModel> list = raw.map(DailyReportModel.fromMap);

    if (q.isNotEmpty) {
      list = list.where(
        (e) =>
            e.patientName.toLowerCase().contains(q) ||
            e.id.toLowerCase().contains(q),
      );
    }
    if (_statusFilter != null) {
      list = list.where((e) => e.status == _statusFilter);
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = ref.watch(doctorProvider);
    final filtered = _filtered(doctor.dailyReports);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const SimpleHeader(title: 'Daily Reports'),
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: () => ref.read(doctorProvider).fetchAllDailyReports(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Gap(30.h),

                        // ── Search field ────────────────────────────────────
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

                        // ── Filter chips ────────────────────────────────────
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
                                  () =>
                                      _statusFilter = DailyReportStatus.warning,
                                ),
                              ),
                              Gap(8.w),
                              _buildFilterChip(
                                label: 'Critical',
                                selected:
                                    _statusFilter == DailyReportStatus.critical,
                                onSelected: () => setState(
                                  () => _statusFilter =
                                      DailyReportStatus.critical,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Gap(20.h),

                        // ── Content ─────────────────────────────────────────
                        if (doctor.isLoading)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 48.h),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (doctor.error != null)
                          _buildErrorState(doctor.error!, textTheme)
                        else if (filtered.isEmpty)
                          _buildEmptyState(textTheme)
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final report = filtered[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: _DailyReportCard(
                                  model: report,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => HardwareScreen(
                                          patientId: report.id,
                                          patientName: report.patientName,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),

                        Gap(20.h),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
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

  Widget _buildErrorState(String error, TextTheme textTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56.r,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            Gap(16.h),
            Text(
              'Failed to load reports',
              style: textTheme.titleMedium?.copyWith(
                fontSize: 16.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(8.h),
            Text(
              error,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(20.h),
            TextButton.icon(
              onPressed: () => ref.read(doctorProvider).fetchAllDailyReports(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------

class _DailyReportCard extends StatelessWidget {
  const _DailyReportCard({
    required this.model,
    required this.onTap,
  });

  final DailyReportModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Card(
          elevation: 2,
          shadowColor: Colors.black26,
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
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
                        label: 'HEART RATE',
                        value: '${model.pulse}',
                        unit: 'bpm',
                        valueColor: AppColors.primary,
                      ),
                    ),
                    Gap(10.w),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.blur_on_rounded,
                        label: 'OXYGEN',
                        value: '${model.ppm}',
                        unit: '%',
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
                        value: model.temperature.replaceAll('°C', ''),
                        unit: '°C',
                        valueColor: AppColors.textPrimary,
                      ),
                    ),
                    Gap(10.w),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.directions_walk_rounded,
                        label: 'ACTIVITY',
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

// ---------------------------------------------------------------------------
// Sub-widgets (unchanged from original)
// ---------------------------------------------------------------------------

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
