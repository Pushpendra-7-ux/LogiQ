import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:logiq/core/theme/app_theme.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/user.dart';
import 'package:logiq/models/transporter.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/auction_provider.dart';
import 'package:logiq/providers/bid_provider.dart';
import 'package:logiq/providers/navigation_provider.dart';
import 'package:logiq/screens/auth/login_screen.dart';
import 'package:logiq/screens/user/user_home_screen.dart';
import 'package:logiq/screens/transporter/transporter_home_screen.dart';
import 'package:logiq/screens/transporter/stage2_live_screen.dart';
import 'package:logiq/screens/transporter/bid_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  Widget buildTestApp(Widget child, {
    AuthProvider? auth,
    TenderProvider? tender,
    AuctionProvider? auction,
    BidProvider? bid,
    NavigationProvider? nav,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth ?? AuthProvider()),
        ChangeNotifierProvider<TenderProvider>.value(value: tender ?? TenderProvider()),
        ChangeNotifierProvider<AuctionProvider>.value(value: auction ?? AuctionProvider()),
        ChangeNotifierProvider<BidProvider>.value(value: bid ?? BidProvider()),
        ChangeNotifierProvider<NavigationProvider>.value(value: nav ?? NavigationProvider()),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: child,
      ),
    );
  }

  group('Google Stitch UI & State Management Verification', () {
    testWidgets('LoginScreen displays enterprise Stitch branding and demo role accounts', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      await tester.pump();

      expect(find.text('LOGIQ'), findsOneWidget);
      expect(find.text('Enterprise Reverse Auction Platform'), findsOneWidget);
      expect(find.text('User'), findsWidgets);
      expect(find.text('Transporter'), findsWidgets);
      expect(find.text('Admin'), findsWidgets);
      expect(find.text('Sign in as User'), findsOneWidget);
      expect(find.text('Sign In as User'), findsOneWidget);
      expect(find.text('Use User Demo Account'), findsOneWidget);
    });

    testWidgets('UserHomeScreen displays USER badge and statistics', (tester) async {
      final auth = AuthProvider();
      auth.currentUser = AppUser(
        id: 1,
        name: 'SteelCorp Logistics',
        email: 'user@logiq.com',
        password: 'password',
        createdAt: DateTime.now(),
        role: AppUser.roleUser,
      );

      await tester.pumpWidget(buildTestApp(const UserHomeScreen(), auth: auth));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('USER'), findsOneWidget);
      expect(find.text('LIVE PROCUREMENT PORTAL'), findsOneWidget);
      expect(find.text('SteelCorp Logistics'), findsOneWidget);
      expect(find.text('Procure New Corridor'), findsOneWidget);
      expect(find.text('ACTIVE TENDERS'), findsOneWidget);
      expect(find.text('TOTAL SAVINGS'), findsOneWidget);
      expect(find.text('LOADS DISPATCHED'), findsOneWidget);
      expect(find.text('CARRIERS / TENDER'), findsOneWidget);
    });

    testWidgets('TransporterHomeScreen displays CARRIER badge and stats', (tester) async {
      final auth = AuthProvider();
      auth.currentUser = AppUser(
        id: 2,
        name: 'QuickTrans Logistics',
        email: 'transporter1@logiq.com',
        password: 'password',
        createdAt: DateTime.now(),
        role: AppUser.roleTransporter,
      );
      auth.currentTransporter = Transporter(
        id: 1,
        userId: 2,
        companyName: 'QuickTrans Logistics',
        gstin: '07AAAAA0000A1Z5',
        vahanId: 'VH-1001',
        isApproved: true,
      );

      await tester.pumpWidget(buildTestApp(const TransporterHomeScreen(), auth: auth));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('CARRIER'), findsOneWidget);
      expect(find.text('ACTIVE BIDS'), findsOneWidget);
      expect(find.text('WON TODAY'), findsOneWidget);
      expect(find.text('L1 WIN RATE'), findsOneWidget);
    });

    testWidgets('Stage2LiveScreen displays blind auction controls and quick bid decrement chips', (tester) async {
      final auth = AuthProvider();
      auth.currentUser = AppUser(
        id: 2,
        name: 'Transporter Demo',
        email: 'transporter1@logiq.com',
        password: 'password',
        createdAt: DateTime.now(),
        role: AppUser.roleTransporter,
      );
      auth.currentTransporter = Transporter(
        id: 1,
        userId: 2,
        companyName: 'Transporter Demo',
        gstin: '07AAAAA0000A1Z5',
        vahanId: 'VH-1001',
        isApproved: true,
      );

      final tender = TenderProvider();
      tender.addTenderForTesting(
        Tender(
          id: 101,
          title: '685 KM Direct Steel Transit Corridor',
          createdBy: 1,
          pickup: 'Gwalior',
          drop: 'Raipur',
          deliveryStart: DateTime.now().add(const Duration(days: 2)),
          deliveryEnd: DateTime.now().add(const Duration(days: 5)),
          closingDate: DateTime.now().add(const Duration(days: 1)),
          biddingStart: DateTime.now().subtract(const Duration(minutes: 5)),
          softEnd: DateTime.now().add(const Duration(minutes: 5)),
          hardStop: DateTime.now().add(const Duration(minutes: 15)),
          priceDifference: 25.0,
          status: TenderStatus.stage1,
          createdAt: DateTime.now(),
        ),
      );

      final auction = AuctionProvider();
      await tester.pumpWidget(buildTestApp(const Stage2LiveScreen(tenderId: 101), auth: auth, tender: tender, auction: auction));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('YOUR BID'), findsOneWidget);
      expect(find.text('-₹25'), findsOneWidget);
      expect(find.text('-₹50'), findsOneWidget);
      expect(find.text('-₹100'), findsOneWidget);
      expect(find.text('SUBMIT BID'), findsOneWidget);

      // Tap stage toggle to test Stage 2 Blind Bid transition
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Stage 2'), findsWidgets);
      expect(find.text('-₹500'), findsOneWidget);
      expect(find.text('-₹1k'), findsOneWidget);
      expect(find.textContaining('All-inclusive'), findsOneWidget);

      auction.dispose();
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('BidResultScreen displays Stitch contract outcome states', (tester) async {
      final auth = AuthProvider();
      auth.currentUser = AppUser(
        id: 2,
        name: 'Winner Transporter',
        email: 'transporter1@logiq.com',
        password: 'password',
        createdAt: DateTime.now(),
        role: AppUser.roleTransporter,
      );
      auth.currentTransporter = Transporter(
        id: 1,
        userId: 2,
        companyName: 'Winner Transporter',
        gstin: '07AAAAA0000A1Z5',
        vahanId: 'VH-1001',
        isApproved: true,
      );

      final tender = TenderProvider();
      tender.addTenderForTesting(
        Tender(
          id: 101,
          title: '685 KM Direct Steel Transit Corridor',
          createdBy: 1,
          pickup: 'Gwalior',
          drop: 'Raipur',
          deliveryStart: DateTime.now().add(const Duration(days: 2)),
          deliveryEnd: DateTime.now().add(const Duration(days: 5)),
          closingDate: DateTime.now().add(const Duration(days: 1)),
          biddingStart: DateTime.now().subtract(const Duration(minutes: 20)),
          softEnd: DateTime.now().subtract(const Duration(minutes: 5)),
          hardStop: DateTime.now(),
          priceDifference: 25.0,
          status: TenderStatus.completed,
          createdAt: DateTime.now(),
        ),
      );

      final auction = AuctionProvider();
      auction.winnerTransporterId = 1;
      auction.winningBid = 51200.0;
      auction.winnerName = 'Winner Transporter';
      auction.isFinalized = true;

      await tester.pumpWidget(buildTestApp(const BidResultScreen(tenderId: 101), auth: auth, tender: tender, auction: auction));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('LOAD AWARDED!'), findsOneWidget);
      expect(find.text('FINAL WINNING RATE'), findsOneWidget);
      expect(find.text('ASSIGN TRUCK & DRIVER'), findsOneWidget);
    });
  });
}
