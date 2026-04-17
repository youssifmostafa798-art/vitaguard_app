import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
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

/// Professional, calm error display using Amber tones. 
/// Replaces scary technical boxes with actionable guidance.
class AiErrorDisplay extends StatelessWidget {
  const AiErrorDisplay({
    super.key,
    required this.message,
    required this.advice,
    required this.onRetry,
    required this.onUploadNew,
  });

  final String message;
  final String advice;
  final VoidCallback onRetry;
  final VoidCallback onUploadNew;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const amberBase = Color(0xFFF39C12);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: amberBase.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: amberBase.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 48.sp, color: amberBase),
          Gap(16.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Gap(8.h),
          Text(
            advice,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          Gap(24.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUploadNew,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('New Upload'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AiAnalysisAssistantBadge extends StatelessWidget {
  const AiAnalysisAssistantBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14.sp, color: AppColors.primary),
            Gap(6.w),
            Text(
              'AI ANALYSIS ASSISTANT',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  }
}
