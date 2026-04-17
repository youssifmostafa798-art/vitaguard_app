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
    this.onRetry,
  });

  final File imageFile;
  final XRayResult result;
  final Future<void> Function()? onRetry;

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

    final isError = widget.result.isValid == false;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: 'AI Analysis Assistant',
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
                          const AiAnalysisAssistantBadge(),
                          Gap(16.h),
                          if (aiData.isError)
                            AiErrorDisplay(
                              message: aiData.summary,
                              advice: aiData.friendlyErrorAdvice ?? '',
                              onRetry: () {
                                if (widget.onRetry != null) {
                                  widget.onRetry!();
                                }
                              },
                              onUploadNew: () => Navigator.pop(context),
                            )
                          else ...[
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
                          ],
                          Gap(16.h),
                          // Subtle disclaimer
                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: (aiData.isError ? Colors.amber : AppColors.error)
                                      .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: (aiData.isError ? Colors.amber : AppColors.error)
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      aiData.isError ? Icons.info_outline : Icons.warning_amber_rounded,
                                      size: 18.sp,
                                      color: aiData.isError ? Colors.amber.shade700 : AppColors.error,
                                    ),
                                    Gap(8.w),
                                    Expanded(
                                      child: Text(
                                        aiData.isError
                                            ? 'The report is currently incomplete. Clinical judgment is required.'
                                            : 'PRELIMINARY REPORT: Clinical correlation required. Not a final diagnosis.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: aiData.isError
                                                  ? Colors.amber.shade900
                                                  : AppColors.error,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (aiData.isError) ...[
                                Gap(12.h),
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Error reported. Thank you for your feedback.')),
                                    );
                                  },
                                  child: Text(
                                    'Report an issue with this analysis',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
              if (!isError)
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
