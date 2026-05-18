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
    text = _stripOrchestrationText(text);
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
    final patterns = <RegExp>[
      // Existing pattern
      RegExp(
        r'^The user (said|asked|wrote|typed)\s+[^\n]+\n?',
        caseSensitive: false,
        multiLine: true,
      ),
      // NEW: Additional user echo patterns
      RegExp(r'^User says:[^\n]*\n?', caseSensitive: false, multiLine: true),
      RegExp(r'^User wrote:[^\n]*\n?', caseSensitive: false, multiLine: true),
      RegExp(r'^User asked:[^\n]*\n?', caseSensitive: false, multiLine: true),
      RegExp(r'^User typed:[^\n]*\n?', caseSensitive: false, multiLine: true),
      RegExp(r'^The user is initiating[^\n]*\n?', caseSensitive: false, multiLine: true),
    ];
    String result = text;
    for (final pattern in patterns) {
      result = result.replaceAll(pattern, '');
    }
    return result;
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
      // Existing patterns — these exactly mirror system prompt phrasing
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
      // Structural prompt markers (rare in natural medical text)
      RegExp(r'^User says:[^\n]*\n?', caseSensitive: false, multiLine: true),
      RegExp(
        r'^\s*Role:\s*(assistant|system|user)\b[^\n]*\n?',
        caseSensitive: false,
        multiLine: true,
      ),
      RegExp(
        r'^\s*Constraint:[^\n]*\n?',
        caseSensitive: false,
        multiLine: true,
      ),
      RegExp(r'System prompt:[^\n]*\n?', caseSensitive: false),
      RegExp(r'Example response:[^\n]*\n?', caseSensitive: false),
      RegExp(r'Developer message:[^\n]*\n?', caseSensitive: false),
      RegExp(r'Hidden instructions:[^\n]*\n?', caseSensitive: false),
      RegExp(r'Internal prompt:[^\n]*\n?', caseSensitive: false),
      RegExp(r'Chain of thought:[^\n]*\n?', caseSensitive: false),
    ];
    String result = text;
    for (final pattern in patterns) {
      result = result.replaceAll(pattern, '');
    }
    return result;
  }

  // ── Internal annotations ───────────────────────────────────────────

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

  // ── Orchestration text (Drafting, Refining, etc.) ─────────────────

  static String _stripOrchestrationText(String text) {
    final patterns = <RegExp>[
      // Drafting/Refining patterns
      RegExp(r'^\s*Drafting[^\n]*\n?', caseSensitive: false, multiLine: true),
      RegExp(r'^\s*Refining[^\n]*\n?', caseSensitive: false, multiLine: true),
      RegExp(r'^\s*Drafting response[^\n]*\n?', caseSensitive: false, multiLine: true),
      RegExp(r'^\s*Refining response[^\n]*\n?', caseSensitive: false, multiLine: true),
      RegExp(r'^\s*Refining for[^\n]*\n?', caseSensitive: false, multiLine: true),
      // Multi-line orchestration blocks
      RegExp(
        r'Drafting response\.\.\.[^\n]*\n?',
        caseSensitive: false,
        multiLine: true,
      ),
      RegExp(
        r'Refining for (professional|clinical) tone[^\n]*\n?',
        caseSensitive: false,
        multiLine: true,
      ),
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

  // ── Prompt leak detection ─────────────────────────────────────────

  /// Returns true if the response contains leaked prompt content.
  /// Use this to validate responses before displaying to users.
  ///
  /// IMPORTANT: Only include patterns that are unambiguously structural
  /// prompt leakage. Do NOT include common medical terms like
  /// 'Instructions:', 'Guidelines:', 'Rules:', 'Reasoning:' — these appear
  /// constantly in legitimate clinical responses and cause false positives.
  static bool containsPromptLeak(String text) {
    if (text.trim().isEmpty) return false;

    final leakPatterns = <RegExp>[
      RegExp(r'User says:', caseSensitive: false),
      RegExp(r'Role:\s*(assistant|system|user)', caseSensitive: false),
      RegExp(r'Constraint:', caseSensitive: false),
      RegExp(r'Goal:\s*(respond|provide|help)', caseSensitive: false),
      RegExp(r'Formatting:\s*(use|apply)', caseSensitive: false),
      RegExp(r'System prompt', caseSensitive: false),
      RegExp(r'Example response', caseSensitive: false),
      RegExp(r'Developer message', caseSensitive: false),
      RegExp(r'Hidden instructions', caseSensitive: false),
      RegExp(r'Internal prompt', caseSensitive: false),
      RegExp(r'Chain of thought', caseSensitive: false),
      RegExp(r'As an AI', caseSensitive: false),
      RegExp(r'I am an AI', caseSensitive: false),
      RegExp(r'The user is initiating', caseSensitive: false),
    ];

    return leakPatterns.any((pattern) => pattern.hasMatch(text));
  }
}