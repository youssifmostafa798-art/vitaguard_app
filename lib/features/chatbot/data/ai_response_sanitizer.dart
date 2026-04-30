class AiResponseSanitizer {
  static const fallbackMessage =
      "I'm sorry, I could not generate a useful response. Please try rephrasing your question.";

  static final List<RegExp> _blockedInstructionLines = [
    RegExp(r'^\s*(Goal|Tone|Formatting)\s*:', caseSensitive: false),
    RegExp(r'^\s*STRICT\s+FORMATTING\s+RULES\s*:?', caseSensitive: false),
    RegExp(r'^\s*You are a clinical AI assistant', caseSensitive: false),
  ];

  static String sanitize(
    String raw, {
    String? userPrompt,
    bool useFallbackWhenEmpty = false,
  }) {
    var cleaned = raw
        .replaceAll(RegExp(r'<thought>[\s\S]*?<\/thought>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<thought>[\s\S]*$', caseSensitive: false), '')
        .replaceAllMapped(
          RegExp(r'\*\*\s+(.*?)\s+\*\*'),
          (match) => '**${match.group(1)}**',
        )
        .trim();

    cleaned = cleaned
        .split('\n')
        .where((line) => !_blockedInstructionLines.any((rule) => rule.hasMatch(line)))
        .join('\n')
        .trim();

    final prompt = userPrompt?.trim() ?? '';
    if (prompt.isNotEmpty && cleaned.isNotEmpty) {
      cleaned = _removeLeadingPromptEcho(cleaned, prompt).trim();
    }

    if (cleaned.isEmpty && useFallbackWhenEmpty) {
      return fallbackMessage;
    }
    return cleaned;
  }

  static String _removeLeadingPromptEcho(String value, String prompt) {
    var cleaned = value;
    final escapedPrompt = RegExp.escape(prompt);

    final userPrefixPattern = RegExp(
      '(?:user|patient)\\s*:?\\s*$escapedPrompt',
      caseSensitive: false,
    );
    cleaned = cleaned.replaceAll(userPrefixPattern, '').trim();

    final repeatedPrompt = RegExp(
      '^(?:$escapedPrompt){2,}\\s*',
      caseSensitive: false,
    );
    cleaned = cleaned.replaceFirst(repeatedPrompt, '').trimLeft();

    final patterns = [
      RegExp(
        '^(user\\s*:?\\s*)?$escapedPrompt(?:\\s+|\\s*[-:]\\s+)',
        caseSensitive: false,
      ),
      RegExp("^[\"']$escapedPrompt[\"']\\s*[-:]*\\s*", caseSensitive: false),
      RegExp("^$escapedPrompt\\s*", caseSensitive: false),
    ];

    var changed = true;
    while (changed && cleaned.isNotEmpty) {
      changed = false;
      for (final pattern in patterns) {
        final next = cleaned.replaceFirst(pattern, '').trimLeft();
        if (next != cleaned) {
          cleaned = next;
          changed = true;
        }
      }
    }

    return cleaned;
  }
}
