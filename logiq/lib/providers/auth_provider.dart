import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../core/storage/secure_storage.dart';
import '../core/network/dio_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DioClient _dioClient = DioClient();

  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String? get role => _user?.role;
  bool get isTransport => _user?.role == 'transport';
  bool get isIndustry => _user?.role == 'industry';

  /// Restores the session from persisted token on app startup.
  /// Returns true if a valid session was restored.
  Future<bool> checkAuth() async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      _isInitialized = true;
      notifyListeners();
      return false;
    }

    try {
      _user = await _authService.getMe();
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      await _clearSession();
      _isInitialized = true;
      notifyListeners();
      return false;
    }
  }

  /// Authenticates the user and persists the access token.
  /// Returns true on success; error details available via [error].
  Future<bool> login(String email, String password) async {
    _setLoading();

    try {
      final data = await _authService.login(email, password);
      await SecureStorage.saveToken(data['access_token'] as String);
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      return _handleFailure(_dioClient.getErrorMessage(e));
    } catch (e) {
      return _handleFailure('An unexpected error occurred. Please try again.');
    }
  }

  /// Registers a new user account.
  /// Returns null on success, or an error message on failure.
  Future<String?> register({
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
    _setLoading();

    try {
      await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        companyName: companyName,
        companyEmail: companyEmail,
        whatsappPhone: whatsappPhone,
        gstNumber: gstNumber,
        transportId: transportId,
      );
      _error = null;
      _isLoading = false;
      notifyListeners();
      return null;
    } on DioException catch (e) {
      final msg = _dioClient.getErrorMessage(e);
      _handleFailure(msg);
      return msg;
    } catch (e) {
      const msg = 'An unexpected error occurred. Please try again.';
      _handleFailure(msg);
      return msg;
    }
  }

  /// Clears the session and signs the user out.
  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  /// Clears any transient error message.
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _setLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  bool _handleFailure(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> _clearSession() async {
    await SecureStorage.deleteToken();
    _user = null;
    _error = null;
  }
}