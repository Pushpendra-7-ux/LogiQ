import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  late final Dio dio;

  DioClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      dio.put(path, data: data);

  Future<Response> delete(String path) =>
      dio.delete(path);

  String getErrorMessage(DioException e) {
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}