import 'package:firebase_auth/firebase_auth.dart';

class ErrorMapper {
  static String map(Object error) {
    if (error is FirebaseAuthException) {
      final message = error.message ?? '';
      if (message.contains('CONFIGURATION_NOT_FOUND')) {
        return 'Sign up blocked: app verification is not configured. '
            'Add your SHA-256 fingerprint in Firebase and use a Google Play device/emulator.';
      }
      switch (error.code) {
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'Email is already registered.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'internal-error':
          return message.isNotEmpty ? message : 'Authentication error.';
        default:
          return message.isNotEmpty ? message : 'Authentication error.';
      }
    }

    if (error is FirebaseException) {
      final message = error.message ?? '';
      if (message.contains('CONFIGURATION_NOT_FOUND')) {
        return 'Sign up blocked: app verification is not configured. '
            'Add your SHA-256 fingerprint in Firebase and use a Google Play device/emulator.';
      }
      return message.isNotEmpty ? message : 'Firebase error.';
    }

    return error.toString();
  }
}
