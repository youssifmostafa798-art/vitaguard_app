/// Sanitizes raw AI responses to remove leaked prompts and reasoning.
library;

/// Cleans raw Gemma/Gemini output before displaying to the user.
class SanitizedResult {
  final String text;
  final bool isValid;

  const SanitizedResult({
    required this.text,
    required this.isValid,
  });
}

/// Cleans raw Gemma/Gemini output before displaying to the user.
/// Structured to be loss-aware and fail-safe.
class AiResponseSanitizer {
  AiResponseSanitizer._();

  /// Sanitize [raw] AI response text.
  /// Limited to ONLY structural recovery, no semantic removal.
  static SanitizedResult sanitize(String raw, {String? userPrompt}) {
    if (raw.trim().isEmpty) return const SanitizedResult(text: '', isValid: true);

    String text = raw;

    // Structural cleanup: fix bold spacing artefact
    text = text.replaceAllMapped(
      RegExp(r'\*\*\s+(.*?)\s+\*\*'),
      (match) => '**${match.group(1)}**'
    );
    
    // Structural cleanup: strip any stray <thought> blocks just in case the model
    // hallucinates them based on prior training/prompts.
    text = text.replaceAll(RegExp(r'<thought>[\s\S]*?</thought>', caseSensitive: false), '');

    return SanitizedResult(text: text.trim(), isValid: true);
  }
}