import '../core/network/dio_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/user.dart';

class AuthService {
  final DioClient _dio = DioClient();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String role,
    String? companyName,
    String? companyEmail,
    String? whatsappPhone,
    String? gstNumber,
    String? transportId,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'company_name': companyName,
      'company_email': companyEmail,
      'whatsapp_phone': whatsappPhone,
      'gst_number': gstNumber,
      'transport_id': transportId,
    };

    data.removeWhere((key, value) => value == null);

    final response = await _dio.post(
      ApiEndpoints.register,
      data: data,
    );

    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  Future<User> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}