import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logiq/core/database/database_helper.dart';
import 'package:logiq/core/database/database_seed.dart';
import 'package:logiq/models/material.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/user.dart';
import 'package:logiq/services/auth_service.dart';
import 'package:logiq/services/tender_service.dart';
import 'package:logiq/services/auction_service.dart';
import 'package:logiq/services/admin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await DatabaseSeed.ensureSeeded(db);
  });

  group('AuthService Tests', () {
    test('Login with valid user credentials returns AppUser', () async {
      final user = await AuthService.instance.login('user@logiq.com', '123456');
      expect(user, isNotNull);
      expect(user!.role, AppUser.roleUser);
    });

    test('Login with invalid password returns null', () async {
      final user = await AuthService.instance.login('user@logiq.com', 'wrong_pass');
      expect(user, isNull);
    });

    test('getTransporterProfile returns profile for valid transporter user', () async {
      final user = await AuthService.instance.login('transporter1@logiq.com', '123456');
      expect(user, isNotNull);
      final profile = await AuthService.instance.getTransporterProfile(user!.id!);
      expect(profile, isNotNull);
      expect(profile!.companyName, isNotEmpty);
    });
  });

  group('TenderService & Draft Lifecycle Tests', () {
    test('Create draft, update draft, and publish draft', () async {
      final now = DateTime.now();
      final draftTender = Tender(
        title: 'Steel Coils Express',
        createdBy: 1,
        pickup: 'Pune',
        drop: 'Nagpur',
        deliveryStart: now.add(const Duration(days: 2)),
        deliveryEnd: now.add(const Duration(days: 5)),
        closingDate: now.add(const Duration(days: 1)),
        biddingStart: now,
        softEnd: now.add(const Duration(minutes: 3)),
        hardStop: now.add(const Duration(minutes: 13)),
        priceDifference: 50.0,
        status: TenderStatus.draft,
        createdAt: now,
      );

      final material = const MaterialItem(
        description: 'Hot Rolled Steel Coils',
        hsnCode: '7208',
        quantity: 25.0,
        unit: 'MT',
        remarks: 'Handle with crane',
      );

      // 1. Create Draft
      final tenderId = await TenderService.instance.createTender(
        tender: draftTender,
        materials: [material],
        transporterIds: [1, 2],
      );
      expect(tenderId, isPositive);

      var fetched = await TenderService.instance.getTenderById(tenderId);
      expect(fetched, isNotNull);
      expect(fetched!.status, TenderStatus.draft);
      expect(fetched.title, 'Steel Coils Express');

      // 2. Update Draft
      final updatedTender = fetched.copyWith(status: TenderStatus.draft);
      await TenderService.instance.updateDraft(
        tenderId: tenderId,
        tender: updatedTender,
        materials: [material],
        transporterIds: [1, 2, 3],
      );

      final pCount = await TenderService.instance.getParticipantCount(tenderId);
      expect(pCount, 3);

      // 3. Publish Draft
      await TenderService.instance.setStatus(tenderId, TenderStatus.scheduled);
      fetched = await TenderService.instance.getTenderById(tenderId);
      expect(fetched!.status, TenderStatus.scheduled);
    });
  });

  group('AuctionService & Bidding Tests', () {
    test('Insert and fetch valid stage bids', () async {
      final auctions = await AuctionService.instance.getAllAuctions();
      expect(auctions, isNotEmpty);
      final auction = auctions.first;

      // Insert stage 1 bid
      final bid = await AuctionService.instance.insertBid(
        auctionId: auction.id!,
        tenderId: auction.tenderId,
        transporterId: 1,
        amount: 48000,
        stage: 1,
      );
      expect(bid.id, isNotNull);
      expect(bid.amount, 48000);

      final validBids = await AuctionService.instance.getValidStageBids(auction.id!, 1);
      expect(validBids, isNotEmpty);
      expect(validBids.any((b) => b.transporterId == 1 && b.amount == 48000), isTrue);
    });
  });

  group('AdminService Tests', () {
    test('getDashboardStats returns valid counts', () async {
      final stats = await AdminService.instance.getDashboardStats();
      expect(stats.totalTransporters, isNonNegative);
      expect(stats.activeTenders, isNonNegative);
    });
  });
}
