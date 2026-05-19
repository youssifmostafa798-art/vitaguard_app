/// Sanitizes raw AI responses to remove leaked prompts and reasoning.
library;

/// Cleans raw Gemma/Gemini output before displaying to the user.
class SanitizedResult {
  final String text;
  final bool isValid;

  const SanitizedResult({required this.text, required this.isValid});
}

/// Cleans raw Gemma/Gemini output before displaying to the user.
/// Structured to be loss-aware and fail-safe.
class AiResponseSanitizer {
  AiResponseSanitizer._();

  static final List<RegExp> _blockedLinePatterns = [
    RegExp(
      r'^\s*(?:[*-]\s*)?(?:User Input|User input|User says|User asks|Context|Role|Goal|Task|Plan|Problem|Reasoning|Thoughts|Guidelines?|Instructions?|Safety|Constraint|System prompt|Internal prompt|Chain of thought)\s*:',
      caseSensitive: false,
    ),
    RegExp(
      r'^\s*(?:[*-]\s*)?Acknowledge(?:\s+the\s+request)?\.?\s*$',
      caseSensitive: false,
    ),
    RegExp(
      r'^\s*(?:[*-]\s*)?The user is (?:asking|initiating)\b',
      caseSensitive: false,
    ),
  ];

  static bool _isBlockedLine(String line) {
    return _blockedLinePatterns.any((pattern) => pattern.hasMatch(line));
  }

  static String _removeBlockedLines(String input) {
    return input.split('\n').where((line) => !_isBlockedLine(line)).join('\n');
  }

  static bool _isWordCharacter(String char) {
    return RegExp(r'[A-Za-z0-9_]').hasMatch(char);
  }

  static String _fixBoldMarkerSpacing(String input) {
    final source = input.replaceAllMapped(
      RegExp(r'\*\*\s+([^*\n]+?)\s+\*\*'),
      (match) => '**${match.group(1)?.trim() ?? ''}**',
    );

    return source.replaceAllMapped(RegExp(r'\*\*([^*\n]+?)\*\*'), (match) {
      final inner = match.group(1)?.trim() ?? '';
      if (inner.isEmpty) return match.group(0) ?? '';

      final previous = match.start > 0 ? source[match.start - 1] : '';
      final next = match.end < source.length ? source[match.end] : '';
      final leadingSpace = previous.isNotEmpty && _isWordCharacter(previous);
      final trailingSpace = next.isNotEmpty && _isWordCharacter(next);

      return '${leadingSpace ? ' ' : ''}**$inner**${trailingSpace ? ' ' : ''}';
    });
  }

  /// Sanitize [raw] AI response text.
  /// Limited to ONLY structural recovery, no semantic removal.
  static SanitizedResult sanitize(String raw, {String? userPrompt}) {
    if (raw.trim().isEmpty) {
      return const SanitizedResult(text: '', isValid: true);
    }

    String text = raw;

    // Try to extract content inside <response>...</response> tags first
    final responseTagMatch = RegExp(
      r'<response>([\s\S]*?)(?:</response>|$)',
      caseSensitive: false,
    ).firstMatch(text);
    if (responseTagMatch != null) {
      String extracted = (responseTagMatch.group(1) ?? '').trim();
      extracted = _fixBoldMarkerSpacing(extracted);
      extracted = _removeBlockedLines(extracted).trim();
      if (extracted.isNotEmpty) {
        return SanitizedResult(text: extracted, isValid: true);
      }
    }

    // 1. Structural cleanup: strip any stray <thought> blocks
    text = text.replaceAll(
      RegExp(r'<thought>[\s\S]*?</thought>', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'<thought>[\s\S]*$', caseSensitive: false),
      '',
    );

    // 2. Identify if there's a "Final Polish/Response/Answer" block and extract it
    final finalBlockMatch = RegExp(
      r'(?:Final\s+Polish|Final\s+Response|Final\s+Answer|^Response\s*:)\s*\*?\*?:?\s*([\s\S]*)',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(text);

    if (finalBlockMatch != null) {
      text = finalBlockMatch.group(1) ?? '';
    } else {
      // If no explicit final block, but we have preamble sections, let's strip lines belonging to those sections
      final preamblePatterns = [
        RegExp(r'^\s*[-*•]?\s*Constraint\s+Checklist', caseSensitive: false),
        RegExp(r'^\s*[-*•]?\s*Confidence\s+Score', caseSensitive: false),
        RegExp(r'^\s*[-*•]?\s*Mental\s+Sandbox', caseSensitive: false),
        RegExp(r'^\s*[-*•]?\s*Decision\s*:', caseSensitive: false),
        RegExp(r'^\s*[-*•]?\s*Inline\s+backticks', caseSensitive: false),
        RegExp(r'^\s*[-*•]?\s*No\s+internal\s+thoughts', caseSensitive: false),
        RegExp(r'^\s*[-*•]?\s*N/A\b', caseSensitive: false),
      ];
      final lines = text.split('\n');
      final cleanedLines = <String>[];
      bool insidePreamble = false;
      for (final line in lines) {
        final isPreambleLine = preamblePatterns.any(
          (pattern) => pattern.hasMatch(line),
        );
        if (isPreambleLine) {
          insidePreamble = true;
          continue;
        }
        if (insidePreamble &&
            (RegExp(
                  r'^\s*(?:Option\s+\d+|Decision)\b',
                  caseSensitive: false,
                ).hasMatch(line) ||
                (RegExp(
                      r'^\s*["\x27`]?Hello',
                      caseSensitive: false,
                    ).hasMatch(line) &&
                    line.contains("clinical assistant")))) {
          continue;
        }
        cleanedLines.add(line);
      }
      text = cleanedLines.join('\n');
    }

    // 3. Clean up the extracted text (double quote duplicates, quotes, etc.)
    text = text.trim();
    final quoteMatch = RegExp(
      r'^["\x27]([\s\S]*?)["\x27]\s*([\s\S]*)$',
    ).firstMatch(text);
    if (quoteMatch != null) {
      final quoted = quoteMatch.group(1) ?? '';
      final remainder = quoteMatch.group(2) ?? '';
      if (remainder.trim().isNotEmpty) {
        text = remainder.trim();
      } else {
        text = quoted.trim();
      }
    }

    text = _fixBoldMarkerSpacing(text);

    text = _removeBlockedLines(text);

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
        RegExp('^["\\\']?$escaped["\\\']?\\s*[-:]+\\s*', caseSensitive: false),
        '',
      );
    }

    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    if (text.isEmpty && raw.trim().isNotEmpty) {
      // Preserve raw text instead of substituting a generic fallback
      return SanitizedResult(text: raw.trim(), isValid: true);
    }

    return SanitizedResult(
      text: text.trim().isNotEmpty ? text.trim() : raw.trim(),
      isValid: true,
    );
  }
}
