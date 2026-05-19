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

  static const _fallback =
      "I'm sorry, I could not generate a response. Please try rephrasing your question.";

  static final List<RegExp> _blockedLinePatterns = [
    RegExp(
      r'^\s*(?:[*-]\s*)?(?:User Input|User input|User says|Context|Role|Goal|Task|Plan|Guidelines?|Instructions?|Safety|Constraint|System prompt|Internal prompt|Chain of thought)\s*:',
      caseSensitive: false,
    ),
    RegExp(
      r'^\s*(?:[*-]\s*)?The user is (?:asking|initiating)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'^\s*(?:[*-]\s*)?As a clinical AI assistant\b',
      caseSensitive: false,
    ),
    RegExp(
      r'^\s*(?:[*-]\s*)?(?:I need to|I should|I must)\b',
      caseSensitive: false,
    ),
  ];

  static bool _isBlockedLine(String line) {
    return _blockedLinePatterns.any((pattern) => pattern.hasMatch(line));
  }

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

    text = text
        .split('\n')
        .where((line) => !_isBlockedLine(line))
        .join('\n');

    final prompt = userPrompt?.trim();
    if (prompt != null && prompt.length >= 4) {
      final escaped = RegExp.escape(prompt);
      text = text.replaceAll(
        RegExp(
          '(?:The user (?:said|asked|wrote|typed)\\s+["\\\']$escaped["\\\']|user\\s*:?\\s*$escaped)',
          caseSensitive: false,
        ),
        '',
      );
      text = text.trimLeft().replaceFirst(
            RegExp('^["\\\']?$escaped["\\\']?\\s*[-:]+\\s*',
                caseSensitive: false),
            '',
          );
    }

    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    if (text.isEmpty && raw.trim().isNotEmpty) {
      return const SanitizedResult(text: _fallback, isValid: true);
    }

    return SanitizedResult(text: text.trim(), isValid: true);
  }
}
