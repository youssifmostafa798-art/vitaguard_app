import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/core/feedback/clinical_feedback.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/data/models/patient/patient_models.dart';
import 'package:vitaguard_app/presentation/widgets/xray/phase1_diagnosis_panel.dart';
import 'package:vitaguard_app/presentation/widgets/xray/phase2_ai_review_panel.dart';
import 'package:vitaguard_app/presentation/widgets/xray/raw_xray_viewer.dart';
import 'package:vitaguard_app/presentation/widgets/xray/review_progress_header.dart';
import 'package:vitaguard_app/features/xray/data/doctor_two_phase_ai_view_data.dart';
import 'package:vitaguard_app/data/models/xray/doctor_two_phase_models.dart';
import 'package:vitaguard_app/presentation/controllers/patient/patient_provider.dart';

/// Mandatory two-phase X-ray review: manual first (AI locked), then AI unlocks.
///
/// REASON: Clinical decision-support rule — no AI output before the doctor records
/// an initial independent assessment.
class DoctorTwoPhaseReviewScreen extends ConsumerStatefulWidget {
  const DoctorTwoPhaseReviewScreen({
    super.key,
    required this.xRayFile,
    this.onReviewFinished,
    this.onDecisionRecorded,
  });

  final File xRayFile;

  /// Called after a final decision is saved so the host can reset (e.g. pick another image).
  final VoidCallback? onReviewFinished;

  /// Optional hook for persistence / analytics (record includes phase 1 + AI snapshot + outcome).
  final void Function(TwoPhaseReviewRecord record)? onDecisionRecorded;

  @override
  ConsumerState<DoctorTwoPhaseReviewScreen> createState() =>
      _DoctorTwoPhaseReviewScreenState();
}

class _DoctorTwoPhaseReviewScreenState
    extends ConsumerState<DoctorTwoPhaseReviewScreen> {
  ReviewPhase _phase = ReviewPhase.manual;
  final Set<String> _selectedIds = {};
  final TextEditingController _notesController = TextEditingController();

  bool _aiLoading = false;
  String? _aiError;
  XRayResult? _aiResult;
  AiReviewViewData? _aiViewData;

  bool _decisionBusy = false;

  /// In-memory final record for audit / future persistence.
  TwoPhaseReviewRecord? _record;

  @override
  void initState() {
    super.initState();
    _notesController.addListener(() {
      if (_phase == ReviewPhase.manual) setState(() {});
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _phase1Valid =>
      _selectedIds.isNotEmpty || _notesController.text.trim().isNotEmpty;

  String get _phase1Summary {
    final labels = DiagnosisChecklistOption.standardOptions
        .where((o) => _selectedIds.contains(o.id))
        .map((o) => o.label)
        .toList();
    final notes = _notesController.text.trim();
    final parts = <String>[];
    if (labels.isNotEmpty) {
      parts.add('Findings: ${labels.join(', ')}');
    }
    if (notes.isNotEmpty) {
      parts.add('Notes: $notes');
    }
    return parts.isEmpty ? '(empty)' : parts.join('\n');
  }

  Future<void> _runAiAnalysis() async {
    // NOTE: This is the only allowed entry point for AI — never call from Phase 1.
    setState(() {
      _aiLoading = true;
      _aiError = null;
      _aiResult = null;
      _aiViewData = null;
    });

    final ok = await ref
        .read(patientControllerProvider.notifier)
        .analyzeXRay(widget.xRayFile);

    if (!mounted) return;

    if (!ok) {
      final mapped = ErrorMapper.mapForUser(
        ref.read(patientControllerProvider).error ?? 'Analysis failed',
        const ClinicalErrorContext(area: ClinicalErrorArea.xrayAi),
      );
      setState(() {
        _aiLoading = false;
        _aiError = mapped.message;
      });
      return;
    }

    final result = ref.read(patientControllerProvider).lastXRayResult;
    setState(() {
      _aiLoading = false;
      _aiResult = result;
      _aiViewData = result != null
          ? AiReviewViewData.fromXRayResult(result)
          : null;
    });
  }

  void _onContinueToAi() {
    if (!_phase1Valid) {
      showClinicalPopup(
        context,
        type: ClinicalPopupType.warning,
        title: 'Clinical Review Needed',
        message:
            'Select at least one finding or enter clinical notes before continuing.',
      );
      return;
    }
    setState(() => _phase = ReviewPhase.ai);
    _runAiAnalysis();
  }

  Future<void> _onConfirmAi() async {
    setState(() => _decisionBusy = true);
    final snapshot = TwoPhaseReviewRecord.snapshotFromXRay(_aiResult);
    _record = TwoPhaseReviewRecord(
      phase1SelectedIds: _selectedIds.toList()..sort(),
      phase1Notes: _notesController.text.trim(),
      aiResultSnapshot: snapshot,
      finalStatus: FinalReviewStatus.confirmed,
      overrideFinalDiagnosis: null,
      completedAt: DateTime.now(),
    );
    if (!mounted) return;
    setState(() => _decisionBusy = false);
    showClinicalPopup(
      context,
      type: ClinicalPopupType.success,
      title: 'Decision Saved',
      message: 'Final decision saved: confirmed AI.',
    );
    widget.onDecisionRecorded?.call(_record!);
    widget.onReviewFinished?.call();
  }

  Future<void> _onOverrideAi() async {
    final reasonCtrl = TextEditingController();
    final overrideText = await showClinicalActionDialog<String>(
      context: context,
      type: ClinicalPopupType.warning,
      title: 'Override AI',
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Provide the final diagnosis and clinical reason. This is required to override.',
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: reasonCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Final diagnosis / reason',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          );
        },
      ),
      primaryLabel: 'Save override',
      onPrimary: () {
        final t = reasonCtrl.text.trim();
        if (t.isEmpty) {
          showClinicalPopup(
            context,
            type: ClinicalPopupType.warning,
            title: 'Override Reason Required',
            message: 'Enter a clinical reason before saving the override.',
          );
          return;
        }
        Navigator.pop(context, t);
      },
    );

    reasonCtrl.dispose();

    if (overrideText == null || !mounted) return;

    setState(() => _decisionBusy = true);
    final snapshot = TwoPhaseReviewRecord.snapshotFromXRay(_aiResult);
    _record = TwoPhaseReviewRecord(
      phase1SelectedIds: _selectedIds.toList()..sort(),
      phase1Notes: _notesController.text.trim(),
      aiResultSnapshot: snapshot,
      finalStatus: FinalReviewStatus.overridden,
      overrideFinalDiagnosis: overrideText,
      completedAt: DateTime.now(),
    );
    if (!mounted) return;
    setState(() => _decisionBusy = false);
    showClinicalPopup(
      context,
      type: ClinicalPopupType.success,
      title: 'Override Saved',
      message: 'Final decision saved: overridden.',
    );
    widget.onDecisionRecorded?.call(_record!);
    widget.onReviewFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final step = _phase == ReviewPhase.manual ? 1 : 2;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReviewProgressHeader(
            currentStep: step,
            totalSteps: 2,
            subtitle: _phase == ReviewPhase.manual
                ? 'AI is disabled until initial review is completed.'
                : null,
          ),
          Gap(20.h),
          if (_phase == ReviewPhase.manual) ...[
            RawXRayViewer(imageFile: widget.xRayFile),
            Gap(22.h),
            Phase1DiagnosisPanel(
              selectedIds: _selectedIds,
              onSelectionChanged: (next) => setState(() {
                _selectedIds
                  ..clear()
                  ..addAll(next);
              }),
              notesController: _notesController,
              canContinue: _phase1Valid,
              onContinue: _onContinueToAi,
            ),
          ] else ...[
            if (_aiLoading) ...[
              const Center(child: CircularProgressIndicator()),
              Gap(16.h),
              Text(
                'Running AI analysis…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ] else if (_aiError != null) ...[
              ClinicalFeedbackPanel(
                type: ClinicalPopupType.error,
                title: 'AI Analysis Failed',
                message: _aiError!,
                actionLabel: 'Retry AI analysis',
                onAction: _runAiAnalysis,
              ),
              Gap(16.h),
              FilledButton.tonal(
                onPressed: _runAiAnalysis,
                child: const Text('Retry AI analysis'),
              ),
            ] else if (_aiViewData != null) ...[
              Phase2AiReviewPanel(
                imageFile: widget.xRayFile,
                aiData: _aiViewData!,
                phase1Summary: _phase1Summary,
                onConfirmAi: _onConfirmAi,
                onOverrideAi: _onOverrideAi,
                decisionBusy: _decisionBusy,
              ),
            ],
          ],
          Gap(32.h),
        ],
      ),
    );
  }
}
