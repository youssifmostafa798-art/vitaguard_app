import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/doctor_two_phase_ai_view_data.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/doctor_two_phase_models.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/widgets/phase1_diagnosis_panel.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/widgets/phase2_ai_review_panel.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/widgets/raw_xray_viewer.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/widgets/review_progress_header.dart';

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

    final ok = await ref.read(patientProvider).analyzeXRay(widget.xRayFile);

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _aiLoading = false;
        _aiError = ref.read(patientProvider).error ?? 'Analysis failed';
      });
      return;
    }

    final result = ref.read(patientProvider).lastXRayResult;
    setState(() {
      _aiLoading = false;
      _aiResult = result;
      _aiViewData = result != null ? AiReviewViewData.fromXRayResult(result) : null;
    });
  }

  void _onContinueToAi() {
    if (!_phase1Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one finding or enter clinical notes before continuing.',
          ),
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Final decision saved: Confirmed AI')),
    );
    widget.onDecisionRecorded?.call(_record!);
    widget.onReviewFinished?.call();
  }

  Future<void> _onOverrideAi() async {
    final reasonCtrl = TextEditingController();
    final overrideText = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Override AI'),
          content: Column(
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final t = reasonCtrl.text.trim();
                if (t.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Reason is required to override.')),
                  );
                  return;
                }
                Navigator.pop(ctx, t);
              },
              child: const Text('Save override'),
            ),
          ],
        );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Final decision saved: Overridden')),
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
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 40.sp),
              Gap(8.h),
              Text(
                _aiError!,
                style: Theme.of(context).textTheme.bodyMedium,
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
