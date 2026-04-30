import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/features/xray/data/doctor_two_phase_ai_view_data.dart';
import 'package:vitaguard_app/presentation/widgets/xray/ai_diagnosis_display_widgets.dart';

class Phase2AiReviewPanel extends StatefulWidget {
  const Phase2AiReviewPanel({
    super.key,
    required this.imageFile,
    required this.aiData,
    required this.phase1Summary,
    required this.onConfirmAi,
    required this.onOverrideAi,
    required this.decisionBusy,
  });

  final File imageFile;
  final AiReviewViewData aiData;
  final String phase1Summary;
  final VoidCallback onConfirmAi;
  final VoidCallback onOverrideAi;
  final bool decisionBusy;

  @override
  State<Phase2AiReviewPanel> createState() => _Phase2AiReviewPanelState();
}

class _Phase2AiReviewPanelState extends State<Phase2AiReviewPanel> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compare & decide',
          style: textTheme.titleMedium?.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 14.h),
        AiDiagnosisSummaryCard(
          title: 'Phase 1 — your review',
          body: widget.phase1Summary,
        ),
        SizedBox(height: 12.h),
        Text(
          'AI-assisted review',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 10.h),
        XRayImageWithOptionalHeatmap(
          imageFile: widget.imageFile,
          showHeatmapOverlay: widget.aiData.useHeatmapPlaceholder,
          wlMode: 0,
          transformationController: _transformationController,
          heatmapEmphasis: widget.aiData.heatmapEmphasis,
          heatmapLabel: widget.aiData.heatmapLabel,
        ),
        SizedBox(height: 14.h),
        AiDiagnosisMetricRow(
          confidencePercentText: widget.aiData.confidencePercentText,
          severityLabel: widget.aiData.severityLabel,
        ),
        SizedBox(height: 12.h),
        AiDiagnosisFindingsSection(labels: widget.aiData.labels),
        SizedBox(height: 12.h),
        AiDiagnosisSummaryCard(title: 'AI summary', body: widget.aiData.summary),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.decisionBusy ? null : widget.onOverrideAi,
                child: const Text('Override AI'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: FilledButton(
                onPressed: widget.decisionBusy ? null : widget.onConfirmAi,
                child: const Text('Confirm AI'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}