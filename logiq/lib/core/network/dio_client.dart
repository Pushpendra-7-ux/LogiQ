import 'package:dio/dio.dart';

/// Dio client — intentionally prepared but NOT wired into any prototype flow.
///
/// When the company REST API is ready:
///   1. point [baseUrl] at the company gateway,
///   2. implement data/remote/api_service.dart methods with [_dio],
///   3. swap the local data sources injected inside services/ for remote ones.
/// Screens, providers, models and UI stay unchanged.
class DioClient {
  DioClient._() {
    _dio = Dio(
      BaseOptions(
        // Placeholder — company will provide the real base URL later.
        baseUrl: 'https://api.example-company.com/v1',
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Future: attach company auth token / api key here.
          handler.next(options);
        },
        onError: (error, handler) {
          // Future: map DioException -> human readable AppError.
          handler.next(error);
        },
      ),
    );
  }

  static final DioClient instance = DioClient._();

  late final Dio _dio;

  Dio get dio => _dio;
}
