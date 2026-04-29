import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/patient/models/patient_models.dart';

import '../widgets/ai_diagnosis_display_widgets.dart';
import '../data/doctor_two_phase_ai_view_data.dart';

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
  int _wlMode = 0;
  bool _addedToReport = false;
  bool _flaggedForReview = false;
  bool _reviewed = false;
  String? _overrideNote;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Compute view data regardless of toggle — the report should always be visible.
    final AiReviewViewData aiData = AiReviewViewData.fromXRayResult(
      widget.result,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: 'AI Analysis Assistant',
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: AppBackground(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 56.h, 20.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    XRayImageWithOptionalHeatmap(
                      imageFile: widget.imageFile,
                      showHeatmapOverlay:
                          _aiLayerOn && aiData.useHeatmapPlaceholder,
                      wlMode: _wlMode,
                      transformationController: _transformationController,
                      heatmapEmphasis: aiData.heatmapEmphasis,
                      heatmapLabel: aiData.heatmapLabel,
                    ),
                    Gap(16.h),
                    Center(
                      child: ClinicalToolbar(
                        aiLayerOn: _aiLayerOn,
                        onAiLayerChanged: (v) => setState(() => _aiLayerOn = v),
                        wlMode: _wlMode,
                        onWlToggled: () =>
                            setState(() => _wlMode = (_wlMode + 1) % 3),
                        onZoomReset: () {
                          _transformationController.value = Matrix4.identity();
                        },
                      ),
                    ),
                    Gap(24.h),

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
                      DiagnosisBannerCard(
                        isNormal: aiData.isNormal,
                        title: aiData.diagnosisTitle,
                      ),
                      Gap(12.h),
                      AiDiagnosisMetricRow(
                        confidencePercentText: aiData.confidencePercentText,
                        severityLabel: aiData.severityLabel,
                      ),
                      Gap(12.h),
                      ProbabilityBarChart(
                        probNormal: aiData.probNormDouble,
                        probPneumonia: aiData.probPneuDouble,
                      ),
                      Gap(12.h),
                      AiDiagnosisFindingsSection(labels: aiData.labels),
                      Gap(12.h),
                      AiDiagnosisSummaryCard(
                        title: _overrideNote == null
                            ? 'AI Summary'
                            : 'Clinician Override',
                        body: _overrideNote ?? aiData.summary,
                      ),
                      Gap(24.h),
                      ActionCTARow(
                        onAddToReport: () => _addToReport(aiData),
                        onFlagForReview: _flagForReview,
                        onMarkReviewed: _markReviewed,
                        onOverride: _overrideAnalysis,
                        isAddedToReport: _addedToReport,
                        isFlaggedForReview: _flaggedForReview,
                        isReviewed: _reviewed,
                        hasOverride: _overrideNote != null,
                      ),
                    ],

                    Gap(24.h),

                    // The disclaimer and report issue link are ALWAYS at the bottom
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: (aiData.isError ? Colors.amber : AppColors.error)
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color:
                              (aiData.isError ? Colors.amber : AppColors.error)
                                  .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            aiData.isError
                                ? Icons.info_outline
                                : Icons.warning_amber_rounded,
                            size: 18.sp,
                            color: aiData.isError
                                ? Colors.amber.shade700
                                : AppColors.error,
                          ),
                          Gap(8.w),
                          Expanded(
                            child: Text(
                              aiData.isError
                                  ? 'The report is currently incomplete. Clinical judgment is required.'
                                  : 'PRELIMINARY REPORT: Clinical correlation required. Not a final diagnosis.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
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
                      Center(
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error reported. Thank you for your feedback.',
                                ),
                              ),
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
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToReport(AiReviewViewData aiData) async {
    final report = _buildReportText(aiData);
    await Clipboard.setData(ClipboardData(text: report));

    if (!mounted) return;
    setState(() => _addedToReport = true);
    _showSnackBar('AI report summary copied and marked for report inclusion.');
  }

  void _flagForReview() {
    setState(() => _flaggedForReview = true);
    _showSnackBar('Analysis flagged for clinician review.');
  }

  void _markReviewed() {
    setState(() => _reviewed = true);
    _showSnackBar('Analysis marked as reviewed.');
  }

  Future<void> _overrideAnalysis() async {
    final controller = TextEditingController(text: _overrideNote ?? '');
    final override = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Override AI analysis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the corrected clinical impression or reason for override.',
              ),
              Gap(12.h),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Override note',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Override note is required.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, text);
              },
              child: const Text('Save override'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (override == null || !mounted) return;

    setState(() {
      _overrideNote = override;
      _reviewed = true;
    });
    _showSnackBar('Override saved and analysis marked reviewed.');
  }

  String _buildReportText(AiReviewViewData aiData) {
    final buffer = StringBuffer()
      ..writeln('VitaGuard AI X-Ray Analysis')
      ..writeln('Diagnosis: ${aiData.diagnosisTitle}')
      ..writeln('Confidence: ${aiData.confidencePercentText}')
      ..writeln('Severity: ${aiData.severityLabel}')
      ..writeln('Summary: ${_overrideNote ?? aiData.summary}');

    if (aiData.labels.isNotEmpty) {
      buffer.writeln('Findings: ${aiData.labels.join(', ')}');
    }

    if (_flaggedForReview) {
      buffer.writeln('Review flag: Clinician review requested.');
    }

    return buffer.toString().trim();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
