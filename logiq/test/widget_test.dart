import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:logiq/app.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/navigation_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/auction_provider.dart';
import 'package:logiq/providers/bid_provider.dart';
import 'package:logiq/providers/admin_provider.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(create: (_) => TenderProvider()),
          ChangeNotifierProvider(create: (_) => AuctionProvider()),
          ChangeNotifierProvider(create: (_) => BidProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: const LogiQApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.byType(LogiQApp), findsOneWidget);
  });
}
