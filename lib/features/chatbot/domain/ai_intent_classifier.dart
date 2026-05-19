import 'models/chat_message_model.dart';

/// Deterministic intent classifier for VitaGuard Chatbot.
/// Avoids fuzzy NLP or probabilistic inference. Relies entirely on explicit, 
/// constrained rule matching to ensure medical safety and UI consistency.
class AiIntentClassifier {
  AiIntentClassifier._();

  static MessageIntent classify(String text) {
    if (text.trim().isEmpty) return MessageIntent.normal;

    final normalized = text.toLowerCase();

    // 1. EMERGENCY rules (Immediate threat to life, 911, ER)
    if (_matchesAny(normalized, [
      'seek emergency care',
      'call 911',
      'go to the nearest emergency room',
      'immediate medical attention',
      'call emergency services',
      'go to the emergency room',
    ])) {
      return MessageIntent.emergency;
    }

    // 2. WARNING rules (Consultation required, concerning symptoms)
    if (_matchesAny(normalized, [
      'consult a doctor',
      'see a healthcare professional',
      'schedule an appointment with your doctor',
      'seek medical advice',
      'please contact your doctor',
      'speak with a physician',
      'concerning symptom',
    ])) {
      return MessageIntent.warning;
    }

    // 3. TIP rules (General wellness, lifestyle, preventative)
    if (_matchesAny(normalized, [
      'wellness tip',
      'health tip',
      'lifestyle recommendation',
      'for better sleep',
      'stay hydrated',
      'maintain a balanced diet',
      'regular exercise',
    ])) {
      return MessageIntent.tip;
    }

    // 4. QUESTION rules (Probing for more clinical context)
    if (_matchesAny(normalized, [
      'can you describe',
      'could you tell me more',
      'how long have you been experiencing',
      'what other symptoms',
      'have you noticed any',
    ])) {
      return MessageIntent.question;
    }

    // Default fallback
    return MessageIntent.normal;
  }

  static bool _matchesAny(String text, List<String> exactPhrases) {
    for (final phrase in exactPhrases) {
      if (text.contains(phrase.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
