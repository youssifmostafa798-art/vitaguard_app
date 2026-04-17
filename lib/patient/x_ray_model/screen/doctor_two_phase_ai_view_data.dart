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
    required this.differentialDiagnosis,
    required this.useHeatmapPlaceholder,
    this.isError = false,
    this.friendlyErrorAdvice,
  });

  final String confidencePercentText;
  final String severityLabel;
  final List<String> labels;
  final String summary;
  final String differentialDiagnosis;
  final bool isError;
  final String? friendlyErrorAdvice;

  /// When true, UI shows a synthetic overlay; replace with real tensor when available.
  final bool useHeatmapPlaceholder;

  static AiReviewViewData fromXRayResult(XRayResult result) {
    if (!result.isValid) {
      final technicalError = result.reportText ?? '';
      String friendlyMessage = 'Sorry, we couldn\'t process this X-ray.';
      String? advice = 'Try re-uploading or taking a new photo.';

      if (technicalError.contains('401') || technicalError.contains('Unauthorized')) {
        friendlyMessage = 'Authentication issue detected.';
        advice = 'Please try logging in again to reset your session.';
      } else if (technicalError.contains('WASM') || technicalError.contains('FunctionException') || technicalError.contains('normalize')) {
        friendlyMessage = 'Analysis temporarily unavailable.';
        advice = 'Our AI engine is busy or updating. Please try again in 30 seconds.';
      } else if (technicalError.contains('too blurry') || technicalError.contains('resolution')) {
        friendlyMessage = 'Image quality is too low.';
        advice = 'Please ensure the X-ray is clear and high-resolution.';
      } else if (technicalError.contains('format')) {
        friendlyMessage = 'File format not supported.';
        advice = 'Please use a high-quality JPG or PNG file.';
      }

      return AiReviewViewData(
        confidencePercentText: 'N/A',
        severityLabel: 'Indeterminate',
        labels: const ['Analysis Incomplete'],
        summary: friendlyMessage,
        friendlyErrorAdvice: advice,
        useHeatmapPlaceholder: false,
        differentialDiagnosis: 'Differential diagnosis unavailable.',
        isError: true,
      );
    }

    final confidenceText = result.confidence != null
        ? '${(result.confidence! * 100).clamp(0, 99.9).toStringAsFixed(1)}%'
        : 'N/A';

    final pred = (result.prediction ?? 'UNKNOWN').toUpperCase();
    final isPneumonia = pred.contains('PNEUMONIA');
    final isIndeterminate = pred.contains('INDETERMINATE');
    final isTechError = summaryContent.startsWith('TECH_ERROR:');

    if (isIndeterminate || isTechError) {
      return AiReviewViewData(
        confidencePercentText: 'N/A',
        severityLabel: 'UNSTABLE',
        labels: const [],
        summary: isTechError 
            ? summaryContent.replaceFirst('TECH_ERROR:', '') 
            : summaryContent.isEmpty ? 'The AI engine encountered a processing delay. This study requires standard clinical correlation.' : summaryContent,
        friendlyErrorAdvice: isTechError 
            ? 'A technical engine error occurred. Please report this specific message to the engineering team.'
            : 'The image may be clear enough for a doctor, but the AI engine requires a retry.',
        useHeatmapPlaceholder: false,
        differentialDiagnosis: 'Incomplete study. Please correlate with clinical findings and laboratory data.',
        isError: true,
      );
    }

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

    final probPneu = result.probPneumonia != null 
        ? (result.probPneumonia! * 100).toStringAsFixed(1) 
        : (isPneumonia ? (conf * 100).toStringAsFixed(1) : '0.0');
    final probNorm = result.probNormal != null 
        ? (result.probNormal! * 100).toStringAsFixed(1) 
        : (!isPneumonia ? (conf * 100).toStringAsFixed(1) : '0.0');

    final differential = 'Pneumonia: $probPneu% | Normal: $probNorm%';

    final summary =
        result.reportText ??
        (isPneumonia
            ? 'AI suggests findings consistent with pneumonia ($probPneu% probability). Clinical correlation is required.'
            : 'AI suggests lung fields without a strong pneumonia signal ($probNorm% probability of normal study).');

    return AiReviewViewData(
      confidencePercentText: confidenceText,
      severityLabel: severity,
      labels: labels,
      summary: summary,
      useHeatmapPlaceholder: true,
      differentialDiagnosis: differential,
      isError: false,
    );
  }
}
