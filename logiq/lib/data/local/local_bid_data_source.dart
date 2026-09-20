import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../../core/database/database_tables.dart';
import '../../models/bid.dart';

/// Local (SQLite) access to bids.
/// REPLACE WITH: remote implementation when company REST APIs arrive.
class LocalBidDataSource {
  LocalBidDataSource._();
  static final LocalBidDataSource instance = LocalBidDataSource._();

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<Bid> insert({
    required int auctionId,
    required int tenderId,
    required int transporterId,
    required double amount,
    required int stage,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    final id = await db.insert(DatabaseTables.bids, {
      'auction_id': auctionId,
      'tender_id': tenderId,
      'transporter_id': transporterId,
      'amount': amount,
      'stage': stage,
      'submitted_at': now.toIso8601String(),
      'is_valid': 1,
    });
    return Bid(
      id: id,
      auctionId: auctionId,
      tenderId: tenderId,
      transporterId: transporterId,
      amount: amount,
      stage: stage,
      submittedAt: now,
    );
  }

  Future<void> invalidatePrevious({
    required int auctionId,
    required int transporterId,
    required int stage,
  }) async {
    final db = await _db;
    await db.update(
      DatabaseTables.bids,
      {'is_valid': 0},
      where:
          'auction_id = ? AND transporter_id = ? AND stage = ? AND is_valid = 1',
      whereArgs: [auctionId, transporterId, stage],
    );
  }

  /// Latest valid bid per transporter for a stage, sorted ascending (L1 first).
  Future<List<Bid>> validStageBids(int auctionId, int stage) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.bids,
        where: 'auction_id = ? AND stage = ? AND is_valid = 1',
        whereArgs: [auctionId, stage],
        orderBy: 'amount ASC, submitted_at ASC');
    return rows.map(Bid.fromMap).toList();
  }

  Future<List<Bid>> allValidBids(int auctionId) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.bids,
        where: 'auction_id = ? AND is_valid = 1',
        whereArgs: [auctionId]);
    return rows.map(Bid.fromMap).toList();
  }

  Future<List<Bid>> bidsByTransporter(int transporterId) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.bids,
        where: 'transporter_id = ?',
        whereArgs: [transporterId],
        orderBy: 'submitted_at DESC');
    return rows.map(Bid.fromMap).toList();
  }

  Future<Bid?> latestBidFor({
    required int auctionId,
    required int transporterId,
    required int stage,
  }) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseTables.bids,
      where:
          'auction_id = ? AND transporter_id = ? AND stage = ? AND is_valid = 1',
      whereArgs: [auctionId, transporterId, stage],
      orderBy: 'amount ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Bid.fromMap(rows.first);
  }
}
