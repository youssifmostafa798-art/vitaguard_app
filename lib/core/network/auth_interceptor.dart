import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final _storage = SecureStorageService();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add Bearer token to all requests except public auth endpoints
    final publicPaths = ['/auth/login', '/auth/register'];
    final isPublic = publicPaths.any((path) => options.path.contains(path));

    final token = await _storage.getAccessToken();
    if (token != null && !isPublic) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Systematic handling of 401 Unauthorized
    if (err.response?.statusCode == 401) {
      // Potentially trigger logout or token refresh
      // For now, we propagate the error to the calling repository
    }
    return handler.next(err);
  }
}
