import 'package:flutter/foundation.dart';
import 'package:logiq/models/user.dart';
import 'package:logiq/models/transporter.dart';
import 'package:logiq/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  AppUser? currentUser;
  Transporter? currentTransporter;
  bool isLoading = false;
  String? errorMessage;
  bool isPending = false;
  bool isRejected = false;
  String? rejectionReason;

  AuthProvider();

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.role == AppUser.roleAdmin;
  bool get isUser => currentUser?.isUser ?? false;
  bool get isShipper => currentUser?.isShipper ?? false;
  bool get isTransporter => currentUser?.role == AppUser.roleTransporter;
  String get userName => currentUser?.name ?? '';
  String get userRole => currentUser?.role ?? '';

  Future<void> initApp() async {
    try {
      await _authService.seedDatabase();
    } catch (e, st) {
      debugPrint('initApp error: $e\n$st');
    }
  }

  Future<bool> login(
    String email,
    String password, {
    String? expectedRole,
  }) async {
    isLoading = true;
    errorMessage = null;
    isPending = false;
    isRejected = false;
    rejectionReason = null;
    notifyListeners();

    try {
      final user = await _authService.login(
        email,
        password,
        expectedRole: expectedRole,
      );

      if (user != null) {
        currentUser = user;

        if (user.role == AppUser.roleTransporter && user.id != null) {
          currentTransporter =
              await _authService.ensureTransporterProfile(user);
        }

        return true;
      }
      errorMessage = 'Invalid email or password.';
      return false;
    } on AuthPendingException catch (e) {
      isPending = true;
      errorMessage = e.message;
      return false;
    } on AuthRejectedException catch (e) {
      isRejected = true;
      rejectionReason = e.rejectionReason;
      errorMessage = e.message;
      return false;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e, st) {
      debugPrint('Login error: $e\n$st');
      errorMessage = 'An error occurred during login. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    String companyName = '',
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerUser(
        name: name,
        companyName: companyName,
        email: email,
        phone: phone,
        password: password,
      );
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerShipper({
    required String name,
    required String email,
    required String phone,
    required String password,
    String companyName = '',
  }) =>
      registerUser(
        name: name,
        companyName: companyName,
        email: email,
        phone: phone,
        password: password,
      );

  Future<bool> registerTransporter({
    required String companyName,
    required String email,
    required String phone,
    required String password,
    required String gstin,
    required String transportId,
    String? name,
    String? vehicleInfo,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.registerTransporter(
        companyName: companyName,
        email: email,
        phone: phone,
        password: password,
        gstin: gstin,
        transportId: transportId,
        name: name,
        vehicleInfo: vehicleInfo,
      );
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    currentUser = null;
    currentTransporter = null;
    errorMessage = null;
    isPending = false;
    isRejected = false;
    notifyListeners();
  }
}
