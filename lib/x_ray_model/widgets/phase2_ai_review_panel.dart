import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';

import '../screen/doctor_two_phase_ai_view_data.dart';
import 'ai_diagnosis_display_widgets.dart';

class Phase2AiReviewPanel extends StatelessWidget {
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
          body: phase1Summary,
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
          imageFile: imageFile,
          showHeatmapOverlay: aiData.useHeatmapPlaceholder,
        ),
        SizedBox(height: 14.h),
        AiDiagnosisMetricRow(
          confidencePercentText: aiData.confidencePercentText,
          severityLabel: aiData.severityLabel,
        ),
        SizedBox(height: 12.h),
        AiDiagnosisFindingsSection(labels: aiData.labels),
        SizedBox(height: 12.h),
        AiDiagnosisSummaryCard(title: 'AI summary', body: aiData.summary),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: decisionBusy ? null : onOverrideAi,
                child: const Text('Override AI'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: FilledButton(
                onPressed: decisionBusy ? null : onConfirmAi,
                child: const Text('Confirm AI'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
