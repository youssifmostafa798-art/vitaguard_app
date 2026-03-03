import 'package:dio/dio.dart';
import 'api_endpoints.dart';

class DioErrorMapper {
  static const String _androidHostHint =
      'If you use Android emulator, keep API at 10.0.2.2. '
      'If you use a physical Android device, set --dart-define=API_BASE_URL='
      'http://<your-pc-lan-ip>:8000/api/v1.';

  static String _networkHint() {
    return 'Current API URL: ${ApiEndpoints.baseUrl}. $_androidHostHint';
  }

  static String map(dynamic error) {
    if (error is! DioException) {
      if (error is Exception) {
        return error.toString().replaceAll('Exception: ', '');
      }
      return 'An unexpected error occurred';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. ${_networkHint()}';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to reach server. ${_networkHint()}';
    }

    final response = error.response;
    if (response == null) {
      return 'Network error: ${error.message ?? 'Unknown network failure'}';
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is List) {
        final messages = detail
            .map((entry) {
              if (entry is Map<String, dynamic> && entry['msg'] is String) {
                return entry['msg'] as String;
              }
              return null;
            })
            .whereType<String>()
            .toList();
        if (messages.isNotEmpty) {
          return messages.join(', ');
        }
      }
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
      if (data['message'] is String &&
          (data['message'] as String).trim().isNotEmpty) {
        return data['message'] as String;
      }
    }

    return 'Server error: ${response.statusCode ?? 'unknown'}';
  }
}
