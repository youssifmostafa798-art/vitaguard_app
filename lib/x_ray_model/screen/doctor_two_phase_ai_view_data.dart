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
    required this.probPneuDouble,
    required this.probNormDouble,
    required this.isNormal,
    required this.diagnosisTitle,
    this.isError = false,
    this.friendlyErrorAdvice,
  });

  final String confidencePercentText;
  final String severityLabel;
  final List<String> labels;
  final String summary;
  final bool isError;
  final String? friendlyErrorAdvice;

  // New fields for the UI overhaul
  final double probPneuDouble;
  final double probNormDouble;
  final bool isNormal;
  final String diagnosisTitle;

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
        probPneuDouble: 0.0,
        probNormDouble: 0.0,
        isNormal: false,
        diagnosisTitle: 'ERROR',
        isError: true,
      );
    }

    final conf = result.confidence ?? 0;
    final confidenceText = result.confidence != null
        ? '${(conf * 100).clamp(0, 99.9).toStringAsFixed(1)}%'
        : 'N/A';
    
    final reportText = result.reportText ?? '';
    final pred = (result.prediction ?? 'UNKNOWN').toUpperCase();
    final isPneumonia = pred.contains('PNEUMONIA');
    final isIndeterminate = pred.contains('INDETERMINATE');
    final isTechError = reportText.startsWith('TECH_ERROR:');

    if (isIndeterminate || isTechError) {
      return AiReviewViewData(
        confidencePercentText: 'N/A',
        severityLabel: 'UNSTABLE',
        labels: const [],
        summary: isTechError 
            ? reportText.replaceFirst('TECH_ERROR:', '') 
            : reportText.isEmpty ? 'The AI engine encountered a processing delay. This study requires standard clinical correlation.' : reportText,
        friendlyErrorAdvice: isTechError 
            ? 'A technical engine error occurred. Please report this specific message to the engineering team.'
            : 'The image may be clear enough for a doctor, but the AI engine requires a retry.',
        useHeatmapPlaceholder: false,
        probPneuDouble: 0.0,
        probNormDouble: 0.0,
        isNormal: false,
        diagnosisTitle: 'INDETERMINATE',
        isError: true,
      );
    }

    final severity = !isPneumonia
        ? 'Low'
        : conf >= 0.85
        ? 'High'
        : conf >= 0.6
        ? 'Moderate'
        : 'Low';

    final labels = <String>[
      if (isPneumonia) 'Consistent with infectious / inflammatory pattern'
      else 'No strong pneumonia pattern detected',
      if (!isPneumonia) 'Lung fields appear clear bilaterally',
    ];

    // Ensure probabilities sum to 1.0 (or close to it)
    double pPneu = result.probPneumonia ?? (isPneumonia ? conf : (1.0 - conf));
    double pNorm = result.probNormal ?? (!isPneumonia ? conf : (1.0 - conf));

    // Normalize if they don't exactly sum to 1.0, to prevent UI glitches
    final sum = pPneu + pNorm;
    if (sum > 0.0) {
      pPneu = pPneu / sum;
      pNorm = pNorm / sum;
    }

    final summary =
        result.reportText ??
        (isPneumonia
            ? 'AI suggests findings consistent with pneumonia (confidence: ${(conf * 100).toStringAsFixed(1)}%). Clinical correlation advised.'
            : 'No significant radiological findings consistent with pneumonia (confidence: ${(conf * 100).toStringAsFixed(1)}%). Clinical correlation advised.');

    return AiReviewViewData(
      confidencePercentText: confidenceText,
      severityLabel: severity,
      labels: labels,
      summary: summary,
      useHeatmapPlaceholder: isPneumonia, // Only show heatmap if it's pneumonia as requested
      probPneuDouble: pPneu,
      probNormDouble: pNorm,
      isNormal: !isPneumonia,
      diagnosisTitle: !isPneumonia ? 'Normal' : 'Pneumonia',
      isError: false,
    );
  }
}
