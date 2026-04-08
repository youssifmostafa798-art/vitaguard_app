import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/widgets/heatmap_overlay_placeholder.dart';

/// Square clipped X-ray with optional heatmap overlay (no overlay widget when [showHeatmapOverlay] is false).
class XRayImageWithOptionalHeatmap extends StatelessWidget {
  const XRayImageWithOptionalHeatmap({
    super.key,
    required this.imageFile,
    required this.showHeatmapOverlay,
  });

  final File imageFile;
  final bool showHeatmapOverlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              imageFile,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: Colors.grey.shade300,
                child: Center(
                  child: Icon(Icons.broken_image_outlined, size: 48.sp),
                ),
              ),
            ),
            if (showHeatmapOverlay) const HeatmapOverlayPlaceholder(),
          ],
        ),
      ),
    );
  }
}

/// Confidence + severity (derived) tiles used in AI review layouts.
class AiDiagnosisMetricRow extends StatelessWidget {
  const AiDiagnosisMetricRow({
    super.key,
    required this.confidencePercentText,
    required this.severityLabel,
  });

  final String confidencePercentText;
  final String severityLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Confidence',
            value: confidencePercentText,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _MetricTile(
            label: 'Severity (derived)',
            value: severityLabel,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bulleted list of finding strings.
class AiDiagnosisFindingsSection extends StatelessWidget {
  const AiDiagnosisFindingsSection({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Findings',
          style: textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: 6.h),
        ...labels.map(
          (l) => Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: textTheme.bodyMedium),
                Expanded(child: Text(l, style: textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Neutral card for phase notes or AI summary text.
class AiDiagnosisSummaryCard extends StatelessWidget {
  const AiDiagnosisSummaryCard({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(body, style: textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}
