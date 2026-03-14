import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorMapper {
  static String map(Object error) {
    if (error is AuthException) {
      final message = error.message;
      switch (error.statusCode) {
        case '400':
          return message.isNotEmpty ? message : 'Authentication failed.';
        case '429':
          return 'Rate limit exceeded. Please wait a few minutes before trying again or use a different email.';
        default:
          return message.isNotEmpty ? message : 'Authentication error.';
      }
    }

    if (error is PostgrestException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Database error (${error.code}).';
    }

    if (error is StorageException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Storage error (${error.statusCode}).';
    }

    if (error is FunctionException) {
      if (error.reasonPhrase == 'Bad Request' || error.status == 400) {
        return 'Server error: The request was invalid or data was missing.';
      }
      return error.reasonPhrase ?? 'Function error (${error.status}).';
    }

    if (error is StateError) {
      return error.message;
    }

    final errorStr = error.toString();
    if (errorStr.contains('Bad Request')) {
      return 'Bad Request: The server could not process the scan. Check your internet or try a different image.';
    }

    return errorStr;
  }
}
