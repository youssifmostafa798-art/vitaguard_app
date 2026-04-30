import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/presentation/widgets/xray/heatmap_overlay_placeholder.dart';
import 'package:vitaguard_app/presentation/widgets/xray/ai_layer_toggle.dart';

class XRayImageWithOptionalHeatmap extends StatelessWidget {
  const XRayImageWithOptionalHeatmap({
    super.key,
    required this.imageFile,
    required this.showHeatmapOverlay,
    required this.wlMode,
    required this.transformationController,
    this.heatmapEmphasis = 0.8,
    this.heatmapLabel,
  });

  final File imageFile;
  final bool showHeatmapOverlay;
  final int wlMode;
  final TransformationController transformationController;
  final double heatmapEmphasis;
  final String? heatmapLabel;

  @override
  Widget build(BuildContext context) {
    ColorFilter filter;
    switch (wlMode) {
      case 1: // High Contrast
        filter = const ColorFilter.matrix([
          1.5,
          0,
          0,
          0,
          -50,
          0,
          1.5,
          0,
          0,
          -50,
          0,
          0,
          1.5,
          0,
          -50,
          0,
          0,
          0,
          1,
          0,
        ]);
        break;
      case 2: // Inverted
        filter = const ColorFilter.matrix([
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]);
        break;
      case 0:
      default:
        filter = const ColorFilter.matrix([
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: InteractiveViewer(
        transformationController: transformationController,
        minScale: 1.0,
        maxScale: 5.0,
        panEnabled: true,
        child: ColorFiltered(
          colorFilter: filter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.file(
                imageFile,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: Colors.grey.shade300,
                  child: Center(
                    child: Icon(Icons.broken_image_outlined, size: 48.sp),
                  ),
                ),
              ),
              if (showHeatmapOverlay)
                Positioned.fill(
                  child: HeatmapOverlayPlaceholder(emphasis: heatmapEmphasis),
                ),
              if (showHeatmapOverlay && (heatmapLabel ?? '').isNotEmpty)
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14.sp,
                          color: Colors.orangeAccent,
                        ),
                        Gap(6.w),
                        Text(
                          heatmapLabel!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClinicalToolbar extends StatelessWidget {
  const ClinicalToolbar({
    super.key,
    required this.aiLayerOn,
    required this.onAiLayerChanged,
    required this.onZoomReset,
    required this.onWlToggled,
    required this.wlMode,
  });

  final bool aiLayerOn;
  final ValueChanged<bool> onAiLayerChanged;
  final VoidCallback onZoomReset;
  final VoidCallback onWlToggled;
  final int wlMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarButton(
                icon: Icons.zoom_out_map,
                label: 'Reset',
                onTap: onZoomReset,
              ),
              _ToolbarButton(
                icon: Icons.contrast,
                label: wlMode == 0
                    ? 'W/L: Norm'
                    : (wlMode == 1 ? 'W/L: High' : 'W/L: Inv'),
                onTap: onWlToggled,
              ),
              _ToolbarButton(
                icon: Icons.straighten,
                label: 'Measure',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Measurement tool coming soon'),
                    ),
                  );
                },
              ),
              Gap(12.w),
              Container(width: 1, height: 24.h, color: Colors.grey.shade300),
              Gap(12.w),
              AiLayerToggle(aiLayerOn: aiLayerOn, onChanged: onAiLayerChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.sp, color: AppColors.textSecondary),
            Gap(2.h),
            Text(
              label,
              style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class DiagnosisBannerCard extends StatelessWidget {
  const DiagnosisBannerCard({
    super.key,
    required this.isNormal,
    required this.title,
  });

  final bool isNormal;
  final String title;

  @override
  Widget build(BuildContext context) {
    final color = isNormal ? Colors.green.shade600 : Colors.amber.shade700;
    final bgColor = isNormal ? Colors.green.shade50 : Colors.amber.shade50;
    final icon = isNormal ? Icons.check_circle : Icons.warning_rounded;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28.sp),
          Gap(12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRIMARY DIAGNOSIS',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              Gap(2.h),
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Gap(6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProbabilityBarChart extends StatelessWidget {
  const ProbabilityBarChart({
    super.key,
    required this.probNormal,
    required this.probPneumonia,
  });

  final double probNormal;
  final double probPneumonia;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Probability breakdown',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Gap(12.h),
          _BarRow(
            label: 'Normal',
            value: probNormal,
            color: Colors.green.shade500,
          ),
          Gap(8.h),
          _BarRow(
            label: 'Pneumonia',
            value: probPneumonia,
            color: Colors.amber.shade600,
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pctStr = '${(value * 100).toStringAsFixed(1)}%';
    return Row(
      children: [
        SizedBox(
          width: 70.w,
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                  Container(
                    height: 10.h,
                    width: constraints.maxWidth * value,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(width: 12.w),
        SizedBox(
          width: 45.w,
          child: Text(
            pctStr,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Confidence + severity tiles.
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
            subLabel: 'Typical range: 80-96%',
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _MetricTile(
            label: 'Severity (derived)',
            value: severityLabel,
            showInfoIcon: true,
            infoTooltip:
                'Severity is a derived metric based on model confidence.',
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.subLabel,
    this.showInfoIcon = false,
    this.infoTooltip,
  });

  final String label;
  final String value;
  final String? subLabel;
  final bool showInfoIcon;
  final String? infoTooltip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelColor = label.contains('Severity') && value == 'High'
        ? Colors.amber.shade700
        : (value == 'Low' ? Colors.green.shade600 : AppColors.textPrimary);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (showInfoIcon && infoTooltip != null) ...[
                Gap(4.w),
                Tooltip(
                  message: infoTooltip!,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(
                    Icons.info_outline,
                    size: 14.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
          if (subLabel != null) ...[
            SizedBox(height: 4.h),
            Text(
              subLabel!,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bulleted list of finding strings wrapped in a card.
class AiDiagnosisFindingsSection extends StatelessWidget {
  const AiDiagnosisFindingsSection({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Findings',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 10.h),
          ...labels.map(
            (l) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI summary text with clinical Indigo palette.
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.indigo.shade900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: Colors.indigo.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

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

class ActionCTARow extends StatelessWidget {
  const ActionCTARow({
    super.key,
    required this.onAddToReport,
    required this.onFlagForReview,
    required this.onMarkReviewed,
    required this.onOverride,
    this.isAddedToReport = false,
    this.isFlaggedForReview = false,
    this.isReviewed = false,
    this.hasOverride = false,
  });

  final VoidCallback onAddToReport;
  final VoidCallback onFlagForReview;
  final VoidCallback onMarkReviewed;
  final VoidCallback onOverride;
  final bool isAddedToReport;
  final bool isFlaggedForReview;
  final bool isReviewed;
  final bool hasOverride;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onAddToReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: Text(
                  isAddedToReport ? 'Added to report' : 'Add to report',
                ),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: OutlinedButton(
                onPressed: onFlagForReview,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  foregroundColor: isFlaggedForReview
                      ? Colors.orange.shade800
                      : AppColors.textSecondary,
                  side: BorderSide(
                    color: isFlaggedForReview
                        ? Colors.orange.shade300
                        : AppColors.border,
                  ),
                ),
                child: Text(isFlaggedForReview ? 'Flagged' : 'Flag for review'),
              ),
            ),
          ],
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onMarkReviewed,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade300),
                ),
                child: Text(isReviewed ? 'Reviewed' : 'Mark reviewed'),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: OutlinedButton(
                onPressed: onOverride,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
                child: Text(hasOverride ? 'Override saved' : 'Override'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
