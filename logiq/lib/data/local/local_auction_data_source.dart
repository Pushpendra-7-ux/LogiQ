import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../../core/database/database_tables.dart';
import '../../models/auction.dart';
import '../../models/auction_participant.dart';
import '../../models/auction_result.dart';

/// Local (SQLite) access to auctions, participants and results.
/// REPLACE WITH: remote implementation when company REST APIs arrive.
class LocalAuctionDataSource {
  LocalAuctionDataSource._();
  static final LocalAuctionDataSource instance = LocalAuctionDataSource._();

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<Auction?> byTenderId(int tenderId) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.auctions,
        where: 'tender_id = ?', whereArgs: [tenderId], limit: 1);
    if (rows.isEmpty) return null;
    return Auction.fromMap(rows.first);
  }

  Future<Auction?> byId(int id) async {
    final db = await _db;
    final rows = await db
        .query(DatabaseTables.auctions, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Auction.fromMap(rows.first);
  }

  Future<List<Auction>> all() async {
    final db = await _db;
    final rows = await db
        .query(DatabaseTables.auctions, orderBy: 'id DESC');
    return rows.map(Auction.fromMap).toList();
  }

  Future<List<Auction>> running() async {
    final db = await _db;
    final rows = await db.rawQuery(
        "SELECT * FROM ${DatabaseTables.auctions} WHERE status IN "
        "('scheduled','stage1_live','stage1_completed','stage2_live')");
    return rows.map(Auction.fromMap).toList();
  }

  Future<void> save(Auction auction) async {
    final db = await _db;
    if (auction.id == null) {
      await db.insert(DatabaseTables.auctions, auction.toMap()..remove('id'));
    } else {
      await db.update(DatabaseTables.auctions, auction.toMap()..remove('id'),
          where: 'id = ?', whereArgs: [auction.id]);
    }
  }

  /// Ensures auction_participant rows exist for a tender's participants.
  Future<void> syncParticipants(
      int auctionId, List<int> transporterIds) async {
    final db = await _db;
    final existing = await db.query(DatabaseTables.auctionParticipants,
        columns: ['transporter_id'], where: 'auction_id = ?',
        whereArgs: [auctionId]);
    final have = existing.map((r) => r['transporter_id'] as int).toSet();
    for (final tid in transporterIds) {
      if (!have.contains(tid)) {
        await db.insert(DatabaseTables.auctionParticipants, {
          'auction_id': auctionId,
          'transporter_id': tid,
          'qualified_stage2': 0,
        });
      }
    }
  }

  Future<void> markStage1Results(int auctionId,
      {required List<int> qualifiedTransporterIds}) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(DatabaseTables.auctionParticipants,
          {'qualified_stage2': 0, 'stage1_rank': null},
          where: 'auction_id = ?', whereArgs: [auctionId]);
      for (var i = 0; i < qualifiedTransporterIds.length; i++) {
        await txn.rawUpdate(
            'UPDATE ${DatabaseTables.auctionParticipants} SET qualified_stage2 = 1, stage1_rank = ? '
            'WHERE auction_id = ? AND transporter_id = ?',
            [i + 1, auctionId, qualifiedTransporterIds[i]]);
      }
    });
  }

  Future<List<AuctionParticipant>> participants(int auctionId) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.auctionParticipants,
        where: 'auction_id = ?', whereArgs: [auctionId]);
    return rows.map(AuctionParticipant.fromMap).toList();
  }

  Future<List<AuctionParticipant>> qualified(int auctionId) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.auctionParticipants,
        where: 'auction_id = ? AND qualified_stage2 = 1',
        whereArgs: [auctionId],
        orderBy: 'stage1_rank ASC');
    return rows.map(AuctionParticipant.fromMap).toList();
  }

  Future<void> saveResult(AuctionResult result) async {
    final db = await _db;
    if (result.id == null) {
      await db.insert(
          DatabaseTables.auctionResults, result.toMap()..remove('id'));
    } else {
      await db.update(DatabaseTables.auctionResults,
          result.toMap()..remove('id'),
          where: 'id = ?', whereArgs: [result.id]);
    }
  }

  Future<AuctionResult?> resultByAuction(int auctionId) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.auctionResults,
        where: 'auction_id = ?', whereArgs: [auctionId], limit: 1);
    if (rows.isEmpty) return null;
    return AuctionResult.fromMap(rows.first);
  }

  Future<AuctionResult?> resultByTender(int tenderId) async {
    final db = await _db;
    final rows = await db.rawQuery(
        'SELECT r.* FROM ${DatabaseTables.auctionResults} r '
        'JOIN ${DatabaseTables.auctions} a ON a.id = r.auction_id '
        'WHERE a.tender_id = ? LIMIT 1',
        [tenderId]);
    if (rows.isEmpty) return null;
    return AuctionResult.fromMap(rows.first);
  }

  Future<int> countByStatus(List<String> statuses) async {
    final db = await _db;
    if (statuses.isEmpty) return 0;
    return Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseTables.auctions} WHERE status IN (${statuses.map((_) => '?').join(',')})',
            statuses)) ??
        0;
  }
}
