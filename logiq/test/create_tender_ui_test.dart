import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logiq/core/theme/app_theme.dart';
import 'package:logiq/screens/user/create_tender_screen.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/navigation_provider.dart';
import 'package:logiq/providers/auction_provider.dart';
import 'package:logiq/providers/bid_provider.dart';
import 'package:logiq/providers/admin_provider.dart';
import 'package:logiq/providers/draft_timer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => TenderProvider()),
        ChangeNotifierProvider(create: (_) => AuctionProvider()),
        ChangeNotifierProvider(create: (_) => BidProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => DraftTimerProvider()),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const CreateTenderScreen(),
      ),
    );
  }

  testWidgets('CreateTenderScreen renders form with bidding duration and rules', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Create Tender'), findsWidgets);
    expect(find.text('Spot reverse auction'), findsOneWidget);
    expect(find.text('ROUTE & SCHEDULE'), findsOneWidget);
    expect(find.text('MATERIAL & WEIGHT'), findsOneWidget);
    expect(find.text('PRICING CAP & BID RULES'), findsOneWidget);
    expect(find.text('STARTING DATE & TIME'), findsOneWidget);
    expect(find.text('Now (Immediate)'), findsOneWidget);
    expect(find.text('Schedule Date/Time'), findsOneWidget);
    expect(find.text('ENDING DATE & TIME'), findsOneWidget);
    expect(find.text('Closes At'), findsOneWidget);
    expect(find.text('Pick Date/Time'), findsOneWidget);

    await tester.tap(find.text('Schedule Date/Time'));
    await tester.pumpAndSettle();
    expect(find.text('SCHEDULED'), findsOneWidget);

    await tester.tap(find.text('Now (Immediate)'));
    await tester.pumpAndSettle();
    expect(find.text('STARTS NOW'), findsOneWidget);
  });
}
