import 'package:vitaguard_app/patient/data/patient_models.dart';

/// Presentation model for Phase 2 AI UI.
///
/// REASON: [XRayResult] has no heatmap, severity, or structured labels from the API.
/// This DTO derives human-readable fields for clinical decision-support layout until
/// the model/backend exposes saliency maps and structured findings.
class AiReviewViewData {
  const AiReviewViewData({
    required this.confidencePercentText,
    required this.severityLabel,
    required this.labels,
    required this.summary,
    required this.useHeatmapPlaceholder,
  });

  final String confidencePercentText;
  final String severityLabel;
  final List<String> labels;
  final String summary;

  /// When true, UI shows a synthetic overlay; replace with real tensor when available.
  final bool useHeatmapPlaceholder;

  static AiReviewViewData fromXRayResult(XRayResult result) {
    final confidenceText = result.confidence != null
        ? '${(result.confidence! * 100).clamp(0, 100).toStringAsFixed(1)}%'
        : 'N/A';

    if (!result.isValid) {
      return AiReviewViewData(
        confidencePercentText: confidenceText,
        severityLabel: 'Indeterminate',
        labels: const ['Invalid or unreadable study'],
        summary:
            result.reportText ??
            'The image could not be analyzed as a valid chest X-ray.',
        useHeatmapPlaceholder: false,
      );
    }

    final pred = (result.prediction ?? 'UNKNOWN').toUpperCase();
    final isPneumonia = pred.contains('PNEUMONIA');
    final conf = result.confidence ?? 0;

    final severity = !isPneumonia
        ? 'Low'
        : conf >= 0.85
        ? 'High'
        : conf >= 0.6
        ? 'Moderate'
        : 'Low';

    final labels = <String>[
      'Primary prediction: $pred',
      if (isPneumonia) 'Consistent with infectious / inflammatory pattern',
      if (!isPneumonia) 'No strong pneumonia pattern detected',
    ];

    final summary =
        result.reportText ??
        (isPneumonia
            ? 'AI suggests findings that may be consistent with pneumonia. Clinical correlation is required.'
            : 'AI suggests lung fields without a strong pneumonia signal. Clinical correlation is required.');

    return AiReviewViewData(
      confidencePercentText: confidenceText,
      severityLabel: severity,
      labels: labels,
      summary: summary,
      useHeatmapPlaceholder: true,
    );
  }
}
