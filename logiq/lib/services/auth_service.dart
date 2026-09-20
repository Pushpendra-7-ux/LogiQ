import 'package:logiq/core/database/database_helper.dart';
import 'package:logiq/core/database/database_seed.dart';
import 'package:logiq/data/local/local_user_data_source.dart';
import 'package:logiq/models/transporter.dart';
import 'package:logiq/models/user.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthPendingException extends AuthException {
  const AuthPendingException([
    super.message = 'Your registration is still pending admin approval.',
  ]);
}

class AuthRejectedException extends AuthException {
  final String? rejectionReason;
  AuthRejectedException({String? reason})
      : rejectionReason = reason,
        super(reason != null && reason.isNotEmpty
            ? 'Your registration request was rejected: $reason\nPlease contact the administrator.'
            : 'Your registration request was rejected. Please contact the administrator.');
}

/// Service layer abstraction for Authentication and User management.
/// Providers communicate with this service instead of LocalUserDataSource directly.
/// When REST APIs arrive, only this service will be updated to use DioClient.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final LocalUserDataSource _userDataSource = LocalUserDataSource.instance;

  Future<void> seedDatabase() async {
    final db = await DatabaseHelper.instance.database;
    await DatabaseSeed.ensureSeeded(db);
  }

  Future<AppUser?> login(
    String email,
    String password, {
    String? expectedRole,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await seedDatabase();

    final user = await _userDataSource.findByEmail(cleanEmail);
    if (user == null || user.password != password) {
      return null;
    }

    // Role check if an expected role was specified
    if (expectedRole != null) {
      final normUserRole =
          user.role == 'shipper' ? AppUser.roleUser : user.role;
      final normExpectedRole =
          expectedRole == 'shipper' ? AppUser.roleUser : expectedRole;
      if (normUserRole != normExpectedRole) {
        throw AuthException(
          'This account is registered as a ${user.displayRole}. Please sign in using the ${user.displayRole} Sign In portal.',
        );
      }
    }

    // Check account status
    if (user.status == AppUser.statusPending) {
      throw const AuthPendingException();
    }
    if (user.status == AppUser.statusRejected) {
      throw AuthRejectedException(reason: user.rejectionReason);
    }
    if (!user.isApproved && !user.isAdmin) {
      throw const AuthPendingException();
    }

    return user;
  }

  Future<AppUser> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    String companyName = '',
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await seedDatabase();

    final existing = await _userDataSource.findByEmail(cleanEmail);
    if (existing != null) {
      throw const AuthException('An account with this email already exists.');
    }

    final newUser = AppUser(
      name: name.trim(),
      companyName: companyName.trim(),
      email: cleanEmail,
      password: password,
      role: AppUser.roleUser,
      phone: phone.trim(),
      status: AppUser.statusPending,
      createdAt: DateTime.now(),
    );

    final id = await _userDataSource.insertUser(newUser);
    return newUser.copyWith(id: id);
  }

  // Alias for backward compatibility
  Future<AppUser> registerShipper({
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

  Future<AppUser> registerTransporter({
    required String companyName,
    required String email,
    required String phone,
    required String password,
    String? gstin,
    String? transportId,
    String? name,
    String? vehicleInfo,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    await seedDatabase();

    final existing = await _userDataSource.findByEmail(cleanEmail);
    if (existing != null) {
      throw const AuthException('An account with this email already exists.');
    }

    final effectiveName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : companyName.trim();

    final newUser = AppUser(
      name: effectiveName,
      companyName: companyName.trim(),
      email: cleanEmail,
      password: password,
      role: AppUser.roleTransporter,
      phone: phone.trim(),
      status: AppUser.statusPending,
      createdAt: DateTime.now(),
    );

    final id = await _userDataSource.insertUser(newUser);

    // Also register transporter company row with GSTIN and Transport ID
    final effectiveVahanId = (transportId != null && transportId.trim().isNotEmpty)
        ? transportId.trim()
        : (vehicleInfo?.trim() ?? '');

    await _userDataSource.insertTransporterCompany(
      userId: id,
      companyName: companyName.trim(),
      gstin: gstin?.trim() ?? '',
      vahanTransportId: effectiveVahanId,
      isApproved: false,
    );

    return newUser.copyWith(id: id);
  }

  Future<Transporter?> getTransporterProfile(int userId) async {
    return await _userDataSource.byUserId(userId);
  }

  Future<AppUser?> getUserById(int userId) async {
    return await _userDataSource.findById(userId);
  }
}
