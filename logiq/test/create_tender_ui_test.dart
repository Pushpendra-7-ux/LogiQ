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
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const CreateTenderScreen(),
      ),
    );
  }

  testWidgets('CreateTenderScreen renders initial wizard step with Stitch branding', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('LOGIQ Reverse Auction'), findsOneWidget);
    expect(find.text('TND-2024-0982'), findsOneWidget);
    expect(find.text('Continue to Review'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
  });

  testWidgets('CreateTenderScreen navigation between wizard and review steps', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap Continue to Review to navigate to Step 4 Review & Publish
    await tester.tap(find.text('Continue to Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review & Publish Tender'), findsOneWidget);
    expect(find.text('PUBLISH TENDER'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    // Tap Edit to navigate back to wizard
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIQ Reverse Auction'), findsOneWidget);
  });
}
