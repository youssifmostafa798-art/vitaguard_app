/// Sanitizes raw AI responses to remove leaked prompts and reasoning.
library;

/// Cleans raw Gemma/Gemini output before displaying to the user.
class AiResponseSanitizer {
  AiResponseSanitizer._();

  /// Sanitize [raw] AI response text.
  ///
  /// Optionally pass [userPrompt] to also strip leading echoes
  /// of the user's own message from the response.
  static String sanitize(String raw, {String? userPrompt}) {
    if (raw.trim().isEmpty) return raw;

    String text = raw;
    text = _stripPlanBlock(text);
    text = _stripUserEchoPreamble(text);
    text = _stripSystemPromptLeakage(text);
    text = _stripInternalAnnotations(text);
    if (userPrompt != null && userPrompt.trim().isNotEmpty) {
      text = _stripLeadingEcho(text, userPrompt.trim());
    }
    text = _collapseBlankLines(text);
    return text.trim();
  }

  // ── Plan block ──────────────────────────────────────────────────

  static String _stripPlanBlock(String text) {
    final planBlock = RegExp(
      r'Plan:\s*\n(?:\s*\d+\.\s+[^\n]+\n?)+',
      caseSensitive: false,
      multiLine: true,
    );
    final inlinePlan = RegExp(r'Plan:\s*[^\n]+\n?', caseSensitive: false);
    String result = text.replaceAll(planBlock, '');
    result = result.replaceAll(inlinePlan, '');
    return result;
  }

  // ── User echo preamble ───────────────────────────────────────────

  static String _stripUserEchoPreamble(String text) {
    final echo = RegExp(
      r'^The user (said|asked|wrote|typed)\s+[^\n]+\n?',
      caseSensitive: false,
      multiLine: true,
    );
    return text.replaceAll(echo, '');
  }

  // ── Leading echo of specific user prompt ─────────────────────────

  static String _stripLeadingEcho(String text, String prompt) {
    if (prompt.length < 4) return text;
    final escaped = RegExp.escape(prompt);
    final patterns = <RegExp>[
      RegExp('^$escaped\\s+', caseSensitive: false, multiLine: false),
      RegExp(
        '(?:The user (?:said|asked|wrote|typed)\\s+["\']\\s*)$escaped',
        caseSensitive: false,
      ),
    ];
    String result = text.trimLeft();
    for (final pattern in patterns) {
      result = result.replaceFirst(pattern, '').trimLeft();
    }
    return result;
  }

  // ── System prompt leakage ────────────────────────────────────────

  static String _stripSystemPromptLeakage(String text) {
    final patterns = <RegExp>[
      RegExp(
        r'Clinical A[Ii] assistant for VitaGuard\.?[^\n]*\n?',
        caseSensitive: false,
      ),
      RegExp(
        r'Provide expert healthcare answers[^\n]*\n?',
        caseSensitive: false,
      ),
      RegExp(
        r'Concise,?\s*professional,?\s*expert\.?[^\n]*\n?',
        caseSensitive: false,
      ),
      RegExp(r'No repeating input[^\n]*\n?', caseSensitive: false),
      RegExp(r'use standard markdown[^\n]*\n?', caseSensitive: false),
      RegExp(r'use \* for bullets[^\n]*\n?', caseSensitive: false),
      RegExp(r'STRICT RULES[^\n]*\n?', caseSensitive: false),
      RegExp(r'NEVER VIOLATE[^\n]*\n?', caseSensitive: false),
      RegExp(
        r'Respond ONLY with your final answer[^\n]*\n?',
        caseSensitive: false,
      ),
      RegExp(r'Never repeat or echo[^\n]*\n?', caseSensitive: false),
      RegExp(r'No space inside bold markers[^\n]*\n?', caseSensitive: false),
    ];
    String result = text;
    for (final pattern in patterns) {
      result = result.replaceAll(pattern, '');
    }
    return result;
  }

  // ── Internal annotations ─────────────────────────────────────────

  static String _stripInternalAnnotations(String text) {
    final patterns = <RegExp>[
      RegExp(
        r'^\s*Step\s+\d+:\s*[^\n]*\n?',
        caseSensitive: false,
        multiLine: true,
      ),
      RegExp(
        r'^\s*Note:\s*(internal|hidden|private)[^\n]*\n?',
        caseSensitive: false,
        multiLine: true,
      ),
      RegExp(r'\[internal\][^\n]*\n?', caseSensitive: false),
      RegExp(r'\[thinking\][^\n]*\n?', caseSensitive: false),
    ];
    String result = text;
    for (final pattern in patterns) {
      result = result.replaceAll(pattern, '');
    }
    return result;
  }

  // ── Blank lines ──────────────────────────────────────────────────

  static String _collapseBlankLines(String text) {
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }
}
