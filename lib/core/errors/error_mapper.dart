import 'package:firebase_auth/firebase_auth.dart';

class ErrorMapper {
  static String map(Object error) {
    if (error is FirebaseAuthException) {
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
        default:
          return error.message ?? 'Authentication error.';
      }
    }

    if (error is FirebaseException) {
      return error.message ?? 'Firebase error.';
    }

    return error.toString();
  }
}
