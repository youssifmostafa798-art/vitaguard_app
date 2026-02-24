import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio _dio;
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(),
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
}



