import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_endpoints.dart';

class AdminProvider extends ChangeNotifier {
  final DioClient _dio = DioClient();

  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _pendingTransporters = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get pendingUsers => _pendingUsers;
  List<Map<String, dynamic>> get pendingTransporters => _pendingTransporters;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchPending() async {
    _setLoading(true);
    try {
      final response = await _dio.get(ApiEndpoints.pendingUsers);
      final data = response.data as Map<String, dynamic>? ?? {};
      _pendingUsers = _toMapList(data['pending_users']);
      _pendingTransporters = _toMapList(data['pending_transporters']);
      _error = null;
    } on DioException catch (e) {
      _error = _dio.getErrorMessage(e);
    } catch (e) {
      _error = 'Failed to load pending approvals.';
      debugPrint('fetchPending error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveUser(int userId) async {
    return _moderateUser(
      endpoint: '${ApiEndpoints.approve}/$userId',
      userId: userId,
    );
  }

  Future<bool> rejectUser(int userId) async {
    return _moderateUser(
      endpoint: '${ApiEndpoints.reject}/$userId',
      userId: userId,
    );
  }

  Future<bool> _moderateUser({
    required String endpoint,
    required int userId,
  }) async {
    try {
      await _dio.post(endpoint);
      _pendingUsers.removeWhere((user) => user['id'] == userId);
      _pendingTransporters.removeWhere((user) => user['id'] == userId);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _dio.getErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('moderateUser error: $e');
      return false;
    }
  }

  Future<void> fetchDashboard() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminDashboard);
      _stats = response.data as Map<String, dynamic>? ?? {};
      _error = null;
    } on DioException catch (e) {
      _error = _dio.getErrorMessage(e);
    } catch (e) {
      debugPrint('fetchDashboard error: $e');
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _toMapList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}