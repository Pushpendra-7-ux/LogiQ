import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logiq/core/database/database_helper.dart';
import 'package:logiq/core/database/database_seed.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/core/constants/demo_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AuthProvider authProvider;

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await DatabaseSeed.ensureSeeded(db);

    authProvider = AuthProvider();
    await authProvider.initApp();
  });

  tearDown(() {
    authProvider.dispose();
  });

  group('AuthProvider.login', () {
    test('logs in the demo user with the user role', () async {
      final result = await authProvider.login(
        DemoConstants.demoUserEmail,
        DemoConstants.demoPassword,
      );

      expect(result, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.isUser, isTrue);
      expect(authProvider.isTransporter, isFalse);
      expect(authProvider.isAdmin, isFalse);
      expect(authProvider.userName, equals('Rahul Sharma'));
    });

    test('logs in the demo transporter with the transporter role', () async {
      final result = await authProvider.login(
        DemoConstants.demoTransporterEmail,
        DemoConstants.demoPassword,
      );

      expect(result, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.isUser, isFalse);
      expect(authProvider.isTransporter, isTrue);
      expect(authProvider.isAdmin, isFalse);
      expect(authProvider.currentTransporter, isNotNull);
      expect(authProvider.currentTransporter!.companyName, equals('Bharat Logistics'));
    });

    test('logs in the demo admin with the admin role', () async {
      final result = await authProvider.login(
        DemoConstants.demoAdminEmail,
        DemoConstants.demoPassword,
      );

      expect(result, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.isUser, isFalse);
      expect(authProvider.isTransporter, isFalse);
      expect(authProvider.isAdmin, isTrue);
      expect(authProvider.userName, equals('Anil Verma'));
    });

    test('fails login with invalid password', () async {
      final result = await authProvider.login(
        DemoConstants.demoUserEmail,
        'wrongpassword',
      );

      expect(result, isFalse);
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.currentUser, isNull);
    });
  });
}
