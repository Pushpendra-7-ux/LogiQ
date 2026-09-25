import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logiq/core/database/database_helper.dart';
import 'package:logiq/core/database/database_seed.dart';
import 'package:logiq/models/material.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/user.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/models/bid.dart';
import 'package:logiq/services/auth_service.dart';
import 'package:logiq/services/tender_service.dart';
import 'package:logiq/services/auction_service.dart';
import 'package:logiq/services/admin_service.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/auction_provider.dart';

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

      final updatedTender = fetched.copyWith(status: TenderStatus.draft);
      await TenderService.instance.updateDraft(
        tenderId: tenderId,
        tender: updatedTender,
        materials: [material],
        transporterIds: [1, 2, 3],
      );

      final pCount = await TenderService.instance.getParticipantCount(tenderId);
      expect(pCount, 3);

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

    test('Leaderboard ranks L1 through L5 and resolves company names', () async {
      final auctions = await AuctionService.instance.getAllAuctions();
      expect(auctions, isNotEmpty);
      final auction = auctions.first;

      await AuctionService.instance.insertBid(
        auctionId: auction.id!,
        tenderId: auction.tenderId,
        transporterId: 1,
        amount: 45000,
        stage: 1,
      );
      await AuctionService.instance.insertBid(
        auctionId: auction.id!,
        tenderId: auction.tenderId,
        transporterId: 2,
        amount: 46000,
        stage: 1,
      );
      await AuctionService.instance.insertBid(
        auctionId: auction.id!,
        tenderId: auction.tenderId,
        transporterId: 3,
        amount: 47000,
        stage: 1,
      );

      final validBids = await AuctionService.instance.getValidStageBids(auction.id!, 1);
      final seen = <int>{};
      final uniqueBids = <Bid>[];
      for (final b in validBids) {
        if (seen.add(b.transporterId)) {
          uniqueBids.add(b);
        }
      }

      expect(uniqueBids.length, greaterThanOrEqualTo(3));
      expect(uniqueBids[0].amount, lessThanOrEqualTo(uniqueBids[1].amount));
      expect(uniqueBids[1].amount, lessThanOrEqualTo(uniqueBids[2].amount));

      final names = await AuctionService.instance.getCompanyNames(
        uniqueBids.map((b) => b.transporterId).toList(),
      );
      expect(names[uniqueBids[0].transporterId], isNotNull);
    });

    test('startStage2ForTender transitions to stage 2 blind auction', () async {
      final auctions = await AuctionService.instance.getAllAuctions();
      expect(auctions, isNotEmpty);
      final auction = auctions.first;

      await AuctionService.instance.startStage2ForTender(tenderId: auction.tenderId);
      final updated = await AuctionService.instance.getAuctionByTenderId(auction.tenderId);
      expect(updated, isNotNull);
      expect(updated!.status, AuctionStatus.stage2Live);
      expect(updated.currentStage, 2);
    });
  });

  group('AdminService Tests', () {
    test('getDashboardStats returns valid counts', () async {
      final stats = await AdminService.instance.getDashboardStats();
      expect(stats.totalTransporters, isNonNegative);
      expect(stats.activeTenders, isNonNegative);
    });
  });

  group('3-Minute Draft Review & Scheduled Bidding Tests', () {
    test('createTenderAsDraft creates pendingPublish tender and publishDraft activates it', () async {
      final tenderProvider = TenderProvider();
      final now = DateTime.now();

      final tenderId = await tenderProvider.createTenderAsDraft(
        title: 'Draft Test Tender',
        pickup: 'Mumbai',
        drop: 'Delhi',
        deliveryStart: now.add(const Duration(days: 2)),
        deliveryEnd: now.add(const Duration(days: 5)),
        materials: const [
          MaterialItem(
            description: 'Steel Pipes',
            hsnCode: '7304',
            quantity: 10,
            unit: 'MT',
          ),
        ],
        transporterIds: [1, 2],
        ceilingBid: 50000,
        minDecrement: 500,
        createdBy: 1,
        startNow: true,
      );

      expect(tenderId, isNotNull);
      final draft = tenderProvider.tenderById(tenderId!);
      expect(draft, isNotNull);
      expect(draft!.status, TenderStatus.pendingPublish);
      expect(draft.publishAt, isNotNull);
      expect(tenderProvider.pendingPublishTenders.any((t) => t.id == tenderId), isTrue);
      expect(tenderProvider.activeTenders.any((t) => t.id == tenderId), isFalse);

      final published = await tenderProvider.publishDraft(tenderId: tenderId, userId: 1);
      expect(published, isTrue);

      final publishedTender = tenderProvider.tenderById(tenderId);
      expect(publishedTender!.status, TenderStatus.stage1);
      expect(tenderProvider.activeTenders.any((t) => t.id == tenderId), isTrue);
      expect(tenderProvider.pendingPublishTenders.any((t) => t.id == tenderId), isFalse);
    });

    test('AuctionProvider enforces bidding window and rejects out of bounds bids', () async {
      final auctionProvider = AuctionProvider();
      final tenderProvider = TenderProvider();
      final now = DateTime.now();

      final scheduledStart = now.add(const Duration(hours: 1));
      final scheduledEnd = now.add(const Duration(hours: 3));

      final tenderId = await tenderProvider.createTenderAsDraft(
        title: 'Scheduled Tender Test',
        pickup: 'Pune',
        drop: 'Goa',
        deliveryStart: now.add(const Duration(days: 2)),
        deliveryEnd: now.add(const Duration(days: 5)),
        materials: const [
          MaterialItem(
            description: 'Electronics',
            hsnCode: '8517',
            quantity: 5,
            unit: 'Boxes',
          ),
        ],
        transporterIds: [1, 2],
        ceilingBid: 60000,
        minDecrement: 500,
        createdBy: 1,
        startNow: false,
        biddingStart: scheduledStart,
        biddingEnd: scheduledEnd,
      );

      expect(tenderId, isNotNull);
      await tenderProvider.publishDraft(tenderId: tenderId!, userId: 1);

      final publishedTender = tenderProvider.tenderById(tenderId);
      expect(publishedTender!.status, TenderStatus.scheduled);

      final bidResult = await auctionProvider.placeBid(
        1,
        55000,
        1,
        tenderId: tenderId,
      );
      expect(bidResult, isFalse);
    });

    test('checkAutoPublish with admin role retains all tenders and active tenders for admin', () async {
      final tenderProvider = TenderProvider();
      await tenderProvider.loadAllTenders();
      final initialCount = tenderProvider.allTenders.length;
      expect(initialCount, isPositive);

      await tenderProvider.checkAutoPublish(5, 'admin', null);
      expect(tenderProvider.allTenders.length, equals(initialCount));
      expect(tenderProvider.activeTenders, isNotEmpty);
    });
  });
}
