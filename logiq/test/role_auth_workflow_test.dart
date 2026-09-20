import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logiq/core/database/database_helper.dart';
import 'package:logiq/core/database/database_seed.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/admin_provider.dart';
import 'package:logiq/models/user.dart';
import 'package:logiq/core/constants/demo_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AuthProvider authProvider;
  late AdminProvider adminProvider;

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await DatabaseSeed.ensureSeeded(db);

    authProvider = AuthProvider();
    adminProvider = AdminProvider();
    await authProvider.initApp();
    await adminProvider.loadDashboard();
  });

  tearDown(() {
    authProvider.dispose();
    adminProvider.dispose();
  });

  group('Role-Based Authentication & Isolation Tests', () {
    test('Successful role-specific login for Shipper, Transporter, and Admin', () async {
      // 1. Shipper Demo Login
      final shipperOk = await authProvider.login(
        DemoConstants.shipperDemoEmail,
        DemoConstants.shipperDemoPassword,
        expectedRole: AppUser.roleUser,
      );
      expect(shipperOk, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.isUser, isTrue);
      expect(authProvider.currentUser?.role, equals(AppUser.roleUser));
      expect(authProvider.currentUser?.email, equals(DemoConstants.shipperDemoEmail));

      // 2. Transporter Demo Login
      final transporterOk = await authProvider.login(
        DemoConstants.transporterDemoEmail,
        DemoConstants.transporterDemoPassword,
        expectedRole: AppUser.roleTransporter,
      );
      expect(transporterOk, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.isTransporter, isTrue);
      expect(authProvider.currentUser?.role, equals(AppUser.roleTransporter));
      expect(authProvider.currentTransporter, isNotNull);

      // 3. Admin Demo Login
      final adminOk = await authProvider.login(
        DemoConstants.adminDemoEmail,
        DemoConstants.adminDemoPassword,
        expectedRole: AppUser.roleAdmin,
      );
      expect(adminOk, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.isAdmin, isTrue);
      expect(authProvider.currentUser?.role, equals(AppUser.roleAdmin));
    });

    test('Role mismatch blocks login with clear prompt and preserves isolation', () async {
      // Attempting to log in a Shipper into the Admin portal -> informs user it's a Shipper account
      final adminAttempt = await authProvider.login(
        DemoConstants.shipperDemoEmail,
        DemoConstants.shipperDemoPassword,
        expectedRole: AppUser.roleAdmin,
      );
      expect(adminAttempt, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.errorMessage, contains('User'));

      // Attempting to log in a User into the Transporter portal -> informs user it's a User account
      final transporterAttempt = await authProvider.login(
        DemoConstants.shipperDemoEmail,
        DemoConstants.shipperDemoPassword,
        expectedRole: AppUser.roleTransporter,
      );
      expect(transporterAttempt, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.errorMessage, contains('User'));

      // Attempting to log in an Admin into the User portal -> informs user it's an Admin account
      final userAttempt = await authProvider.login(
        DemoConstants.adminDemoEmail,
        DemoConstants.adminDemoPassword,
        expectedRole: AppUser.roleUser,
      );
      expect(userAttempt, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.errorMessage, contains('Admin'));
    });
  });

  group('Registration & Admin Approval Workflow Tests', () {
    test('User registration creates pending user and login is blocked with isPending == true', () async {
      final uniqueEmail = 'user_${DateTime.now().millisecondsSinceEpoch}@test.com';

      final registered = await authProvider.registerUser(
        name: 'Jane Doe',
        email: uniqueEmail,
        phone: '9876543210',
        password: 'Password@123',
      );
      expect(registered, isTrue);

      // Attempting to login should fail because status is pending
      final loginOk = await authProvider.login(
        uniqueEmail,
        'Password@123',
        expectedRole: AppUser.roleUser,
      );

      expect(loginOk, isFalse);
      expect(authProvider.isPending, isTrue);
      expect(authProvider.isRejected, isFalse);
      expect(authProvider.errorMessage, contains('pending admin approval'));
      expect(authProvider.currentUser, isNull);
    });

    test('Transporter registration creates pending user with GST and Transport ID; login is blocked', () async {
      final uniqueEmail = 'transporter_${DateTime.now().millisecondsSinceEpoch}@test.com';

      final registered = await authProvider.registerTransporter(
        companyName: 'Express Fleet Solutions',
        gstin: '27AAAAA0000A1Z5',
        transportId: 'TR-MH-8842',
        email: uniqueEmail,
        phone: '9123456780',
        password: 'Password@123',
      );
      expect(registered, isTrue);

      // Attempting to login should fail because status is pending
      final loginOk = await authProvider.login(
        uniqueEmail,
        'Password@123',
        expectedRole: AppUser.roleTransporter,
      );

      expect(loginOk, isFalse);
      expect(authProvider.isPending, isTrue);
      expect(authProvider.errorMessage, contains('pending admin approval'));
      expect(authProvider.currentUser, isNull);
    });

    test('Admin approval transitions status to approved; user can now login successfully', () async {
      final uniqueEmail = 'approve_test_${DateTime.now().millisecondsSinceEpoch}@test.com';

      // Register new shipper
      await authProvider.registerShipper(
        name: 'Rohan Gupta',
        companyName: 'Gupta Enterprises',
        email: uniqueEmail,
        phone: '9988776655',
        password: 'Password@123',
      );

      // Find user in admin registration requests
      await adminProvider.loadDashboard();
      final targetUser = adminProvider.registrationRequests.firstWhere(
        (u) => u.email == uniqueEmail,
      );
      expect(targetUser.status, equals(AppUser.statusPending));
      expect(targetUser.id, isNotNull);

      // Admin approves the user
      await adminProvider.approveRegistration(targetUser.id!);

      // Verify in dashboard
      await adminProvider.loadDashboard();
      final approvedUser = adminProvider.approvedUsers.firstWhere(
        (u) => u.id == targetUser.id,
      );
      expect(approvedUser.status, equals(AppUser.statusApproved));

      // Now user logs in successfully
      final loginOk = await authProvider.login(
        uniqueEmail,
        'Password@123',
        expectedRole: AppUser.roleUser,
      );

      expect(loginOk, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.currentUser?.companyName, equals('Gupta Enterprises'));
    });

    test('Admin rejection retains user with status rejected & reason; login is blocked with reason', () async {
      final uniqueEmail = 'reject_test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      const rejectReason = 'Invalid GSTIN and incomplete company registration documentation';

      // Register new shipper
      await authProvider.registerShipper(
        name: 'Invalid Applicant',
        companyName: 'Bogus Cargo Co',
        email: uniqueEmail,
        phone: '9111222333',
        password: 'Password@123',
      );

      // Find user in admin requests
      await adminProvider.loadDashboard();
      final targetUser = adminProvider.registrationRequests.firstWhere(
        (u) => u.email == uniqueEmail,
      );
      expect(targetUser.id, isNotNull);

      // Admin rejects with reason
      await adminProvider.rejectRegistration(targetUser.id!, reason: rejectReason);

      // Verify user is NOT deleted from DB, but status is rejected
      await adminProvider.loadDashboard();
      final rejected = adminProvider.rejectedUsers.firstWhere(
        (u) => u.id == targetUser.id,
      );
      expect(rejected.status, equals(AppUser.statusRejected));
      expect(rejected.rejectionReason, equals(rejectReason));

      // Attempt to login with rejected account
      final loginOk = await authProvider.login(
        uniqueEmail,
        'Password@123',
        expectedRole: AppUser.roleUser,
      );

      expect(loginOk, isFalse);
      expect(authProvider.isRejected, isTrue);
      expect(authProvider.rejectionReason, equals(rejectReason));
      expect(authProvider.errorMessage, contains(rejectReason));
      expect(authProvider.currentUser, isNull);
    });

    test('Pre-seeded mock pending and rejected accounts behave correctly', () async {
      // Test mock pending account
      final pendingLogin = await authProvider.login(
        'priya@logiq.com',
        DemoConstants.demoPassword,
        expectedRole: AppUser.roleUser,
      );
      expect(pendingLogin, isFalse);
      expect(authProvider.isPending, isTrue);

      // Test mock rejected account
      final rejectedLogin = await authProvider.login(
        'rejected.shipper@logiq.demo',
        DemoConstants.demoPassword,
        expectedRole: AppUser.roleUser,
      );
      expect(rejectedLogin, isFalse);
      expect(authProvider.isRejected, isTrue);
      expect(authProvider.errorMessage, contains('rejected'));
    });
  });
}
