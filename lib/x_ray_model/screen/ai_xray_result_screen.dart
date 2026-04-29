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
import '../widgets/clinical_popup.dart';
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
  final ClinicalPopupController _clinicalPopupController =
      ClinicalPopupController();

  @override
  void dispose() {
    _transformationController.dispose();
    _clinicalPopupController.dispose();
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
      body: ClinicalPopupHost(
        controller: _clinicalPopupController,
        child: SafeArea(
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
                          onPressed: _reportIssueFeedback,
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
      ),
    );
  }

  void _reportIssueFeedback() {
    _showClinicalPopup(
      message: 'Error reported. Thank you for your feedback.',
      icon: Icons.report_gmailerrorred_outlined,
      type: PopupType.flag,
      anchor: ClinicalPopupAnchor.bottomRight,
    );
  }

  Future<void> _addToReport(AiReviewViewData aiData) async {
    final report = _buildReportText(aiData);
    await Clipboard.setData(ClipboardData(text: report));

    if (!mounted) return;
    setState(() => _addedToReport = true);
    _showClinicalPopup(
      message: 'AI report summary copied and marked for report inclusion.',
      icon: Icons.note_add_outlined,
      type: PopupType.addToReport,
      anchor: ClinicalPopupAnchor.bottomCenter,
    );
  }

  void _flagForReview() {
    setState(() => _flaggedForReview = true);
    _showClinicalPopup(
      message: 'Analysis flagged for clinician review.',
      icon: Icons.flag_outlined,
      type: PopupType.flag,
      anchor: ClinicalPopupAnchor.bottomRight,
    );
  }

  void _markReviewed() {
    setState(() => _reviewed = true);
    _showClinicalPopup(
      message: 'Analysis marked as reviewed.',
      icon: Icons.verified_outlined,
      type: PopupType.reviewed,
      anchor: ClinicalPopupAnchor.bottomRight,
    );
  }

  Future<void> _overrideAnalysis() async {
    final controller = TextEditingController(text: _overrideNote ?? '');
    final override = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Override AI analysis',
      transitionDuration: const Duration(milliseconds: 190),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        String? validationMessage;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                    decoration: InputDecoration(
                      labelText: 'Override note',
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                      errorText: validationMessage,
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
                      setDialogState(() {
                        validationMessage = 'Override note is required.';
                      });
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
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    controller.dispose();
    if (override == null || !mounted) return;

    setState(() {
      _overrideNote = override;
      _reviewed = true;
    });
    _showClinicalPopup(
      message: 'Override saved and analysis marked reviewed.',
      icon: Icons.edit_note_outlined,
      type: PopupType.override,
      anchor: ClinicalPopupAnchor.center,
    );
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

  void _showClinicalPopup({
    required String message,
    required IconData icon,
    required PopupType type,
    ClinicalPopupAnchor anchor = ClinicalPopupAnchor.bottomRight,
  }) {
    _clinicalPopupController.showClinicalPopup(
      message: message,
      color: ClinicalPopupPalette.forType(type),
      icon: icon,
      type: type,
      anchor: anchor,
    );
  }
}
