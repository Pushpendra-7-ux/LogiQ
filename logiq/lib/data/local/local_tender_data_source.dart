import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../../core/database/database_tables.dart';
import '../../models/material.dart';
import '../../models/tender.dart';

/// Local (SQLite) access to tenders, materials and participants.
/// REPLACE WITH: ApiTenderService (Dio) when company REST APIs arrive.
class LocalTenderDataSource {
  LocalTenderDataSource._();
  static final LocalTenderDataSource instance = LocalTenderDataSource._();

  Future<Database> get _db => DatabaseHelper.instance.database;

  /// Inserts tender + materials + participants in one transaction.
  /// Pass [auction] map to create the paired auction row on publish.
  Future<int> insert({
    required Tender tender,
    required List<MaterialItem> materials,
    required List<int> transporterIds,
    Map<String, Object?>? auction,
  }) async {
    final db = await _db;
    return db.transaction((txn) async {
      final map = tender.toMap()..remove('id');
      final tenderId = await txn.insert(DatabaseTables.tenders, map);
      for (final m in materials) {
        await txn.insert(DatabaseTables.materials,
            {...m.toMap()..remove('id'), 'tender_id': tenderId});
      }
      for (final tid in transporterIds.toSet()) {
        await txn.insert(DatabaseTables.tenderParticipants,
            {'tender_id': tenderId, 'transporter_id': tid});
      }
      if (auction != null) {
        await txn.insert(DatabaseTables.auctions,
            {...auction, 'tender_id': tenderId});
      }
      return tenderId;
    });
  }

  Future<void> updateDraft({
    required int tenderId,
    required Tender tender,
    required List<MaterialItem> materials,
    required List<int> transporterIds,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(DatabaseTables.tenders, tender.toMap()..remove('id'),
          where: 'id = ?', whereArgs: [tenderId]);
      await txn.delete(DatabaseTables.materials,
          where: 'tender_id = ?', whereArgs: [tenderId]);
      for (final m in materials) {
        await txn.insert(DatabaseTables.materials,
            {...m.toMap()..remove('id'), 'tender_id': tenderId});
      }
      await txn.delete(DatabaseTables.tenderParticipants,
          where: 'tender_id = ?', whereArgs: [tenderId]);
      for (final tid in transporterIds.toSet()) {
        await txn.insert(DatabaseTables.tenderParticipants,
            {'tender_id': tenderId, 'transporter_id': tid});
      }
    });
  }

  Future<void> setStatus(int tenderId, TenderStatus status) async {
    final db = await _db;
    await db.update(DatabaseTables.tenders, {'status': status.value},
        where: 'id = ?', whereArgs: [tenderId]);
  }

  Future<void> deleteDraft(int tenderId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(DatabaseTables.tenderParticipants,
          where: 'tender_id = ?', whereArgs: [tenderId]);
      await txn.delete(DatabaseTables.materials,
          where: 'tender_id = ?', whereArgs: [tenderId]);
      await txn.delete(DatabaseTables.tenders,
          where: 'id = ?', whereArgs: [tenderId]);
    });
  }

  Future<Tender?> byId(int id) async {
    final db = await _db;
    final rows =
        await db.query(DatabaseTables.tenders, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Tender.fromMap(rows.first);
  }

  Future<List<Tender>> byCreator(int userId, {List<TenderStatus>? statuses}) async {
    final db = await _db;
    String where = 'created_by = ?';
    var args = <Object?>[userId];
    if (statuses != null && statuses.isNotEmpty) {
      where +=
          ' AND status IN (${List.filled(statuses.length, '?').join(',')})';
      args = [...args, ...statuses.map((s) => s.value)];
    }
    final rows = await db.query(DatabaseTables.tenders,
        where: where, whereArgs: args, orderBy: 'id DESC');
    return rows.map(Tender.fromMap).toList();
  }

  Future<List<Tender>> forTransporter(int transporterId) async {
    final db = await _db;
    final rows = await db.rawQuery(
        'SELECT DISTINCT t.* FROM ${DatabaseTables.tenders} t '
        'JOIN ${DatabaseTables.tenderParticipants} p ON p.tender_id = t.id '
        'WHERE p.transporter_id = ? AND t.status != ? '
        'ORDER BY t.id DESC',
        [transporterId, TenderStatus.draft.value]);
    return rows.map(Tender.fromMap).toList();
  }

  Future<List<Tender>> all() async {
    final db = await _db;
    final rows = await db
        .query(DatabaseTables.tenders, orderBy: 'id DESC');
    return rows.map(Tender.fromMap).toList();
  }

  Future<List<MaterialItem>> materials(int tenderId) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.materials,
        where: 'tender_id = ?', whereArgs: [tenderId], orderBy: 'id ASC');
    return rows.map(MaterialItem.fromMap).toList();
  }

  Future<List<int>> participantIds(int tenderId) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.tenderParticipants,
        columns: ['transporter_id'],
        where: 'tender_id = ?',
        whereArgs: [tenderId]);
    return rows.map((r) => r['transporter_id'] as int).toList();
  }

  Future<int> participantCount(int tenderId) async {
    final db = await _db;
    return Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM ${DatabaseTables.tenderParticipants} WHERE tender_id = ?',
            [tenderId])) ??
        0;
  }

  Future<List<Tender>> history({required int? creatorId, int? transporterId}) async {
    final db = await _db;
    if (creatorId != null) {
      return byCreator(creatorId,
          statuses: [TenderStatus.completed, TenderStatus.cancelled]);
    }
    if (transporterId != null) {
      final rows = await db.rawQuery(
          'SELECT DISTINCT t.* FROM ${DatabaseTables.tenders} t '
          'JOIN ${DatabaseTables.tenderParticipants} p ON p.tender_id = t.id '
          "WHERE p.transporter_id = ? AND t.status IN ('completed','cancelled') "
          'ORDER BY t.id DESC',
          [transporterId]);
      return rows.map(Tender.fromMap).toList();
    }
    final rows = await db.query(DatabaseTables.tenders,
        where: "status IN ('completed','cancelled')", orderBy: 'id DESC');
    return rows.map(Tender.fromMap).toList();
  }
}
