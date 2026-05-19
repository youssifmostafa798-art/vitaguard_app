import 'package:flutter_test/flutter_test.dart';
import 'package:vitaguard_app/features/chatbot/data/ai_response_sanitizer.dart';

void main() {
  group('AiResponseSanitizer', () {
    test('adds space before bold span attached to previous word', () {
      final result = AiResponseSanitizer.sanitize(
        'Check your recent**vital signs** before exercise.',
      );

      expect(result.text, 'Check your recent **vital signs** before exercise.');
      expect(result.isValid, isTrue);
    });

    test('does not add space before normal punctuation after bold span', () {
      final result = AiResponseSanitizer.sanitize(
        'This is an **alert**. Check oxygen saturation.',
      );

      expect(result.text, 'This is an **alert**. Check oxygen saturation.');
      expect(result.isValid, isTrue);
    });

    test('extracts response tags and fixes bold spacing inside them', () {
      final result = AiResponseSanitizer.sanitize(
        '<response>Your recent**vital signs** look stable.</response>',
      );

      expect(result.text, 'Your recent **vital signs** look stable.');
      expect(result.isValid, isTrue);
    });

    test('strips structural prompt leakage while preserving medical text', () {
      final result = AiResponseSanitizer.sanitize(
        'User asks: Check vitals\n'
        'Your **oxygen saturation** is within the expected range.',
        userPrompt: 'Check vitals',
      );

      expect(
        result.text,
        'Your **oxygen saturation** is within the expected range.',
      );
      expect(result.isValid, isTrue);
    });
  });
}
