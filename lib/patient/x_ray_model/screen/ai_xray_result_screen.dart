import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/doctor_two_phase_ai_view_data.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/widgets/ai_diagnosis_display_widgets.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/widgets/ai_layer_toggle.dart';

/// AI X-Ray Diagnosis: raw image always visible; AI overlays and text only when the user enables **AI Layer**.
class AiXRayResultScreen extends ConsumerStatefulWidget {
  const AiXRayResultScreen({
    super.key,
    required this.imageFile,
    required this.result,
  });

  final File imageFile;
  final XRayResult result;

  @override
  ConsumerState<AiXRayResultScreen> createState() => _AiXRayResultScreenState();
}

class _AiXRayResultScreenState extends ConsumerState<AiXRayResultScreen> {
  /// Default ON — show summary and analysis immediately.
  bool _aiLayerOn = true;

  @override
  Widget build(BuildContext context) {
    // Build view data only when the AI layer is shown (decision-support data).
    final AiReviewViewData? aiData =
        _aiLayerOn ? AiReviewViewData.fromXRayResult(widget.result) : null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: 'AI X-Ray Diagnosis',
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: AppBackground(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 56.h, 20.w, 32.h),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        XRayImageWithOptionalHeatmap(
                          imageFile: widget.imageFile,
                          showHeatmapOverlay:
                              aiData != null && aiData.useHeatmapPlaceholder,
                        ),
                        if (aiData != null) ...[
                          Gap(8.h),
                          const _AiAssistantBadge(),
                          Gap(16.h),
                          AiDiagnosisMetricRow(
                            confidencePercentText: aiData.confidencePercentText,
                            severityLabel: aiData.severityLabel,
                          ),
                          Gap(12.h),
                          AiDiagnosisFindingsSection(labels: aiData.labels),
                          Gap(12.h),
                          AiDiagnosisSummaryCard(
                            title: 'AI Summary',
                            body: aiData.summary,
                          ),
                          Gap(12.h),
                          AiDiagnosisSummaryCard(
                            title: 'Differential Diagnosis',
                            body: aiData.differentialDiagnosis,
                          ),
                          Gap(12.h),
                          Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 18.sp, color: AppColors.error),
                                Gap(8.w),
                                Expanded(
                                  child: Text(
                                    'PRELIMINARY REPORT: Clinical correlation required. Not a final diagnosis.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8.h,
                right: 12.w,
                child: SafeArea(
                  child: AiLayerToggle(
                    aiLayerOn: _aiLayerOn,
                    onChanged: (v) => setState(() => _aiLayerOn = v),
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

class _AiAssistantBadge extends StatelessWidget {
  const _AiAssistantBadge();

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
              'AI PRELIMINARY ASSISTANT',
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
