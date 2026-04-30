import 'package:vitaguard_app/data/models/patient/patient_models.dart';

/// Workflow step for UI gating (AI must not run until [manual] is completed).
enum ReviewPhase { manual, ai }

/// Outcome after the doctor compares Phase 1 vs AI in Phase 2.
enum FinalReviewStatus { none, confirmed, overridden }

/// Checklist options for Phase 1 — manual review only.
class DiagnosisChecklistOption {
  const DiagnosisChecklistOption({required this.id, required this.label});

  final String id;
  final String label;

  static const List<DiagnosisChecklistOption> standardOptions = [
    DiagnosisChecklistOption(id: 'fracture', label: 'Fracture'),
    DiagnosisChecklistOption(id: 'pneumonia', label: 'Pneumonia'),
    DiagnosisChecklistOption(id: 'opacity', label: 'Opacity'),
    DiagnosisChecklistOption(id: 'effusion', label: 'Pleural effusion'),
    DiagnosisChecklistOption(id: 'atelectasis', label: 'Atelectasis'),
    DiagnosisChecklistOption(id: 'nodule', label: 'Nodule / mass'),
    DiagnosisChecklistOption(id: 'normal', label: 'No acute findings'),
    DiagnosisChecklistOption(id: 'other', label: 'Other'),
  ];
}

/// Serializable record for audit / future backend persistence.
class TwoPhaseReviewRecord {
  TwoPhaseReviewRecord({
    required this.phase1SelectedIds,
    required this.phase1Notes,
    required this.aiResultSnapshot,
    required this.finalStatus,
    this.overrideFinalDiagnosis,
    this.completedAt,
  });

  final List<String> phase1SelectedIds;
  final String phase1Notes;
  final Map<String, dynamic>? aiResultSnapshot;
  final FinalReviewStatus finalStatus;
  final String? overrideFinalDiagnosis;
  final DateTime? completedAt;

  Map<String, dynamic> toMap() => {
    'phase1SelectedIds': phase1SelectedIds,
    'phase1Notes': phase1Notes,
    'aiResultSnapshot': aiResultSnapshot,
    'finalStatus': finalStatus.name,
    'overrideFinalDiagnosis': overrideFinalDiagnosis,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory TwoPhaseReviewRecord.fromMap(Map<String, dynamic> json) {
    final statusName = json['finalStatus'] as String? ?? 'none';
    return TwoPhaseReviewRecord(
      phase1SelectedIds: List<String>.from(json['phase1SelectedIds'] as List? ?? []),
      phase1Notes: json['phase1Notes'] as String? ?? '',
      aiResultSnapshot: json['aiResultSnapshot'] as Map<String, dynamic>?,
      finalStatus: FinalReviewStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => FinalReviewStatus.none,
      ),
      overrideFinalDiagnosis: json['overrideFinalDiagnosis'] as String?,
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
    );
  }

  static Map<String, dynamic>? snapshotFromXRay(XRayResult? r) =>
      r?.toMap();
}
