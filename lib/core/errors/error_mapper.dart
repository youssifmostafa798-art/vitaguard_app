import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorMapper {
  static String map(Object error) {
    if (error is AuthException) {
      final message = error.message;
      switch (error.statusCode) {
        case '400':
          return message.isNotEmpty ? message : 'Authentication failed.';
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

    if (error is FunctionsException) {
      return error.message.isNotEmpty
          ? error.message
          : 'Function error (${error.status}).';
    }

    return error.toString();
  }
}
