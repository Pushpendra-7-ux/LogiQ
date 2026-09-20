import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/demo_constants.dart';
import '../../models/bid.dart';
import '../../data/mock/mock_bids.dart';
import '../../data/mock/mock_materials.dart';
import '../../data/mock/mock_tenders.dart';
import '../../data/mock/mock_transporters.dart';
import '../../data/mock/mock_users.dart';
import 'database_tables.dart';

/// Seeds demo data exactly once (never duplicates on relaunch) and
/// re-arms the live demo auction when a previous run left it stale.
class DatabaseSeed {
  DatabaseSeed._();

  static const _demoTenderTitle = MockTenders.liveDemoTitle;

  static Future<void> ensureSeeded(Database db) async {
    await _ensureColumns(db);
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.users}')) ??
        0;
    if (count == 0) {
      await _seedAll(db);
    } else {
      await _seedDemoAccountsIfMissing(db);
    }
    await _refreshStaleDemo(db);
  }

  static Future<void> _ensureColumns(Database db) async {
    try {
      await db.execute(
          "ALTER TABLE ${DatabaseTables.users} ADD COLUMN company_name TEXT DEFAULT ''");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE ${DatabaseTables.users} ADD COLUMN status TEXT DEFAULT 'approved'");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE ${DatabaseTables.users} ADD COLUMN rejection_reason TEXT DEFAULT ''");
    } catch (_) {}
    // New tender columns for v2 features
    try {
      await db.execute(
          "ALTER TABLE ${DatabaseTables.tenders} ADD COLUMN ceiling_bid REAL DEFAULT 75000.0");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE ${DatabaseTables.tenders} ADD COLUMN min_decrement REAL DEFAULT 500.0");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE ${DatabaseTables.tenders} ADD COLUMN remarks TEXT DEFAULT ''");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE ${DatabaseTables.tenders} ADD COLUMN vehicle_type TEXT DEFAULT 'Truck'");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE ${DatabaseTables.tenders} ADD COLUMN publish_at TEXT");
    } catch (_) {}
  }

  static Future<void> _seedDemoAccountsIfMissing(Database db) async {
    final demos = [
      MockUsers.adminDemo,
      MockUsers.userDemo,
      MockUsers.shipperDemo,
      MockUsers.transporterDemo,
      MockUsers.pendingUser,
      MockUsers.pendingTransporter,
      MockUsers.rejectedUser,
      MockUsers.rejectedTransporter,
    ];
    for (final u in demos) {
      final rows = await db.query(DatabaseTables.users,
          where: 'email = ?', whereArgs: [u.email]);
      if (rows.isEmpty) {
        await db.insert(DatabaseTables.users, _stripId(u.toMap()));
      } else {
        final map = u.toMap();
        await db.update(
          DatabaseTables.users,
          {
            'status': map['status'],
            'rejection_reason': map['rejection_reason'],
            'company_name': map['company_name'],
            'password': map['password'],
            'is_approved': map['is_approved'],
          },
          where: 'email = ?',
          whereArgs: [u.email],
        );
      }
    }
    final transporterDemoUser = await db.query(DatabaseTables.users,
        where: 'email = ?', whereArgs: [DemoConstants.transporterDemoEmail]);
    if (transporterDemoUser.isNotEmpty) {
      final uid = transporterDemoUser.first['id'] as int;
      final tRow = await db.query(DatabaseTables.transporters,
          where: 'user_id = ?', whereArgs: [uid]);
      if (tRow.isEmpty) {
        await db.insert(DatabaseTables.transporters, {
          'user_id': uid,
          'company_name': MockUsers.transporterDemo.companyName,
          'gstin': '27ABCDE1234F1Z5',
          'vahan_transport_id': 'VAHAN-9999-DEMO',
          'is_approved': 1,
        });
      }
    }
  }

  static Future<void> _seedAll(Database db) async {
    await db.transaction((txn) async {
      // ---------- users ----------
      final userId = await txn.insert(
          DatabaseTables.users, _stripId(MockUsers.user.toMap()));
      await txn.insert(
          DatabaseTables.users, _stripId(MockUsers.shipperDemo.toMap()));
      for (final u in MockUsers.transporters()) {
        await txn.insert(DatabaseTables.users, _stripId(u.toMap()));
      }
      await txn.insert(
          DatabaseTables.users, _stripId(MockUsers.transporterDemo.toMap()));
      await txn.insert(
          DatabaseTables.users, _stripId(MockUsers.admin.toMap()));
      await txn.insert(
          DatabaseTables.users, _stripId(MockUsers.adminDemo.toMap()));
      await txn.insert(
          DatabaseTables.users, _stripId(MockUsers.pendingUser.toMap()));
      await txn.insert(DatabaseTables.users,
          _stripId(MockUsers.pendingTransporter.toMap()));
      await txn.insert(
          DatabaseTables.users, _stripId(MockUsers.rejectedUser.toMap()));
      await txn.insert(DatabaseTables.users,
          _stripId(MockUsers.rejectedTransporter.toMap()));

      // ---------- transporter companies (ids 1..7 approved, 8 pending) ----------
      for (var i = 0; i < MockTransporters.approved.length; i++) {
        final t = MockTransporters.approved[i];
        final userRow = await txn.query(DatabaseTables.users,
            columns: ['id'],
            where: 'email = ?',
            whereArgs: ['transporter${i + 1}@logiq.com']);
        await txn.insert(DatabaseTables.transporters, {
          'user_id': userRow.first['id'],
          'company_name': t.companyName,
          'gstin': t.gstin,
          'vahan_transport_id': t.vahanId,
          'is_approved': 1,
        });
      }
      final pendingRow = await txn.query(DatabaseTables.users,
          columns: ['id'],
          where: 'email = ?',
          whereArgs: ['transporter8@logiq.com']);
      final pt = MockTransporters.pending.first;
      await txn.insert(DatabaseTables.transporters, {
        'user_id': pendingRow.first['id'],
        'company_name': pt.companyName,
        'gstin': pt.gstin,
        'vahan_transport_id': pt.vahanId,
        'is_approved': 0,
      });

      final demoTransporterRow = await txn.query(DatabaseTables.users,
          columns: ['id'],
          where: 'email = ?',
          whereArgs: [DemoConstants.transporterDemoEmail]);
      if (demoTransporterRow.isNotEmpty) {
        await txn.insert(DatabaseTables.transporters, {
          'user_id': demoTransporterRow.first['id'],
          'company_name': MockUsers.transporterDemo.companyName,
          'gstin': '27ABCDE1234F1Z5',
          'vahan_transport_id': 'VAHAN-9999-DEMO',
          'is_approved': 1,
        });
      }

      // ---------- live demo tender (scheduled, engine arms it on entry) ----------
      await _insertTender(
        txn,
        tender: MockTenders.liveDemo(createdBy: userId),
        materials: [MockMaterials.steel],
        transporterIds: [1, 2, 3, 4, 5, 6, 7],
      );

      // ---------- history tender 1 — transporter 1 WINS ----------
      final h1 = await _insertTender(
        txn,
        tender: MockTenders.history1(createdBy: userId),
        materials: [MockMaterials.coal],
        transporterIds: [1, 2, 3, 4, 5],
      );
      await _finishHistory(txn,
          ctx: h1,
          stage1:
              MockBids.historyStage1(auctionId: h1.auctionId, tenderId: h1.tenderId),
          stage2:
              MockBids.historyStage2(auctionId: h1.auctionId, tenderId: h1.tenderId),
          winnerId: 1,
          winnerName: MockTransporters.approved[0].companyName,
          winningBid: 9500);

      // ---------- history tender 2 — transporter 1 LOST ----------
      final h2 = await _insertTender(
        txn,
        tender: MockTenders.history2(createdBy: userId),
        materials: [MockMaterials.cement],
        transporterIds: [1, 3, 6, 7],
      );
      await _finishHistory(txn,
          ctx: h2,
          stage1:
              MockBids.history2Stage1(auctionId: h2.auctionId, tenderId: h2.tenderId),
          stage2:
              MockBids.history2Stage2(auctionId: h2.auctionId, tenderId: h2.tenderId),
          winnerId: 3,
          winnerName: MockTransporters.approved[2].companyName,
          winningBid: 13900);
    });
  }

  static Future<({int auctionId, int tenderId})> _insertTender(
    Transaction txn, {
    required tender,
    required List materials,
    required List<int> transporterIds,
  }) async {
    final tenderId = await txn.insert(
        DatabaseTables.tenders, _stripId(tender.toMap()));
    for (final m in materials) {
      await txn.insert(DatabaseTables.materials,
          _stripId(m.toMap())..['tender_id'] = tenderId);
    }
    for (final tid in transporterIds) {
      await txn.insert(DatabaseTables.tenderParticipants,
          {'tender_id': tenderId, 'transporter_id': tid});
    }
    final auctionId = await txn.insert(DatabaseTables.auctions, {
      'tender_id': tenderId,
      'current_stage': 0,
      'stage1_start': tender.biddingStart.toIso8601String(),
      'stage1_end': tender.softEnd.toIso8601String(),
      'stage2_start': tender.softEnd
          .add(const Duration(seconds: 45))
          .toIso8601String(),
      'stage2_end': tender.hardStop.toIso8601String(),
      'status': 'scheduled',
    });
    return (auctionId: auctionId, tenderId: tenderId);
  }

  static Future<void> _finishHistory(
    Transaction txn, {
    required ({int auctionId, int tenderId}) ctx,
    required List<Bid> stage1,
    required List<Bid> stage2,
    required int winnerId,
    required String winnerName,
    required double winningBid,
  }) async {
    // Top-5 ranking from stage1 bids (already sorted by amount in mock data).
    final ranked = [...stage1]..sort((a, b) => a.amount.compareTo(b.amount));
    for (var i = 0; i < ranked.length && i < AppConstants.top5Size; i++) {
      await txn.insert(DatabaseTables.auctionParticipants, {
        'auction_id': ctx.auctionId,
        'transporter_id': ranked[i].transporterId,
        'qualified_stage2': 1,
        'stage1_rank': i + 1,
      });
    }
    for (final b in [...stage1, ...stage2]) {
      await txn.insert(DatabaseTables.bids, _stripId(b.toMap()));
    }
    await txn.insert(DatabaseTables.auctionResults, {
      'auction_id': ctx.auctionId,
      'winner_transporter_id': winnerId,
      'winner_name': winnerName,
      'winning_bid': winningBid,
      'completed_at': stage2.last.submittedAt.toIso8601String(),
    });
    await txn.update(DatabaseTables.auctions, {
      'status': 'completed',
      'current_stage': 2,
      'winner_transporter_id': winnerId,
      'final_price': winningBid,
    }, where: 'id = ?', whereArgs: [ctx.auctionId]);
  }

  static Map<String, Object?> _stripId(Map<String, Object?> m) {
    return {...m}..remove('id');
  }

  /// The demo auction must always be fresh — if a previous session left it
  /// unfinished and past its deadline, wipe it and re-arm a new one.
  static Future<void> _refreshStaleDemo(Database db) async {
    final rows = await db.rawQuery(
        'SELECT t.id AS tid, a.stage1_end FROM ${DatabaseTables.tenders} t '
        'JOIN ${DatabaseTables.auctions} a ON a.tender_id = t.id '
        "WHERE t.title = ? AND a.status != 'completed'",
        [_demoTenderTitle]);
    if (rows.isEmpty) return;
    final tenderId = rows.first['tid'] as int;
    final end =
        DateTime.tryParse(rows.first['stage1_end'] as String) ?? DateTime.now();
    if (DateTime.now().difference(end) < const Duration(hours: 1)) return;

    await db.transaction((txn) async {
      await txn.rawDelete(
          'DELETE FROM ${DatabaseTables.auctionResults} WHERE auction_id IN (SELECT id FROM ${DatabaseTables.auctions} WHERE tender_id=?)',
          [tenderId]);
      await txn.rawDelete(
          'DELETE FROM ${DatabaseTables.auctionParticipants} WHERE auction_id IN (SELECT id FROM ${DatabaseTables.auctions} WHERE tender_id=?)',
          [tenderId]);
      await txn.delete(DatabaseTables.bids,
          where: 'tender_id = ?', whereArgs: [tenderId]);
      await txn.delete(DatabaseTables.auctions,
          where: 'tender_id = ?', whereArgs: [tenderId]);
      await txn.delete(DatabaseTables.tenderParticipants,
          where: 'tender_id = ?', whereArgs: [tenderId]);
      await txn.delete(DatabaseTables.materials,
          where: 'tender_id = ?', whereArgs: [tenderId]);
      await txn.delete(DatabaseTables.tenders,
          where: 'id = ?', whereArgs: [tenderId]);

      final userId = Sqflite.firstIntValue(await txn.query(
              DatabaseTables.users,
              columns: ['id'],
              where: 'email = ?',
              whereArgs: [DemoConstants.demoUserEmail])) ??
          2;
      await _insertTender(
        txn,
        tender: MockTenders.liveDemo(createdBy: userId),
        materials: [MockMaterials.steel],
        transporterIds: [1, 2, 3, 4, 5, 6, 7],
      );
    });
  }
}
