import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  static const Duration _defaultTimeout = Duration(seconds: 60);
  static const int _maxRetries = 1;

  late final Dio _dio;
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: _defaultTimeout,
        receiveTimeout: _defaultTimeout,
        sendTimeout: _defaultTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(),
      InterceptorsWrapper(
        onError: (error, handler) async {
          final retries =
              (error.requestOptions.extra['retry_count'] as int?) ?? 0;
          final isRetryableMethod = _isIdempotentMethod(
            error.requestOptions.method,
          );
          final isRetryableError = error.type == DioExceptionType.connectionError;

          if (isRetryableMethod && isRetryableError && retries < _maxRetries) {
            final nextRetryCount = retries + 1;
            await Future<void>.delayed(
              Duration(milliseconds: 300 * nextRetryCount),
            );

            final updatedExtras = Map<String, dynamic>.from(
              error.requestOptions.extra,
            )..['retry_count'] = nextRetryCount;

            final requestOptions = error.requestOptions.copyWith(
              extra: updatedExtras,
            );

            try {
              final response = await _dio.fetch<dynamic>(requestOptions);
              return handler.resolve(response);
            } on DioException catch (_) {
              // Fall through and propagate the latest DioException.
            }
          }

          return handler.next(error);
        },
      ),
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => _logger.d(obj.toString()),
      ),
    ]);
  }

  Dio get dio => _dio;

  static bool _isIdempotentMethod(String method) {
    final normalizedMethod = method.toUpperCase();
    return normalizedMethod == 'GET' ||
        normalizedMethod == 'HEAD' ||
        normalizedMethod == 'OPTIONS';
  }
}
