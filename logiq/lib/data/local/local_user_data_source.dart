import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../../core/database/database_tables.dart';
import '../../models/transporter.dart';
import '../../models/user.dart';

/// Local (SQLite) access to users / transporters.
/// REPLACE WITH: ApiUserService (Dio) when company REST APIs arrive.
class LocalUserDataSource {
  LocalUserDataSource._();
  static final LocalUserDataSource instance = LocalUserDataSource._();

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<AppUser?> findByEmail(String email) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.users,
        where: 'email = ?', whereArgs: [email.toLowerCase().trim()]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser?> findById(int id) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.users,
        where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<List<AppUser>> all({String? role, String? status, bool? approved}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (role != null) {
      if (role == 'user' || role == 'shipper') {
        where.add('(role = ? OR role = ?)');
        args.addAll(['user', 'shipper']);
      } else {
        where.add('role = ?');
        args.add(role);
      }
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status);
    }
    if (approved != null) {
      where.add('is_approved = ?');
      args.add(approved ? 1 : 0);
    }
    final rows = await db.query(DatabaseTables.users,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'id ASC');
    return rows.map(AppUser.fromMap).toList();
  }

  Future<void> setStatus(int userId, String status, {String? rejectionReason}) async {
    final db = await _db;
    final isApproved = status == AppUser.statusApproved;
    await db.transaction((txn) async {
      await txn.update(
        DatabaseTables.users,
        {
          'status': status,
          'is_approved': isApproved ? 1 : 0,
          if (isApproved)
            'rejection_reason': ''
          else
            'rejection_reason': ?rejectionReason,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      await txn.update(
        DatabaseTables.transporters,
        {'is_approved': isApproved ? 1 : 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });
  }

  Future<void> setApproval(int userId, bool approved) async {
    await setStatus(userId, approved ? AppUser.statusApproved : AppUser.statusRejected);
  }

  Future<int> insertUser(AppUser user) async {
    final db = await _db;
    return await db.insert(
      DatabaseTables.users,
      {
        'name': user.name,
        'company_name': user.companyName,
        'email': user.email.trim().toLowerCase(),
        'password': user.password,
        'role': user.role,
        'phone': user.phone,
        'status': user.status,
        'rejection_reason': user.rejectionReason,
        'is_approved': user.isApproved ? 1 : 0,
        'created_at': user.createdAt.toIso8601String(),
      },
    );
  }

  Future<int> insertTransporterCompany({
    required int userId,
    required String companyName,
    String gstin = '',
    String vahanTransportId = '',
    bool isApproved = false,
  }) async {
    final db = await _db;
    return await db.insert(DatabaseTables.transporters, {
      'user_id': userId,
      'company_name': companyName,
      'gstin': gstin,
      'vahan_transport_id': vahanTransportId,
      'is_approved': isApproved ? 1 : 0,
    });
  }

  Future<void> deleteUser(int userId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(DatabaseTables.users, where: 'id = ?', whereArgs: [userId]);
      await txn.delete(DatabaseTables.transporters,
          where: 'user_id = ?', whereArgs: [userId]);
    });
  }

  // ---------- transporter companies ----------

  Future<Transporter?> byUserId(int userId) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.transporters,
        where: 'user_id = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;
    return Transporter.fromMap(rows.first);
  }

  Future<Transporter?> byId(int id) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.transporters,
        where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Transporter.fromMap(rows.first);
  }

  Future<List<Transporter>> allCompanies({bool approvedOnly = false}) async {
    final db = await _db;
    final rows = await db.query(DatabaseTables.transporters,
        where: approvedOnly ? 'is_approved = 1' : null, orderBy: 'id ASC');
    return rows.map(Transporter.fromMap).toList();
  }

  Future<Map<int, String>> companyNamesByIds(List<int> ids) async {
    if (ids.isEmpty) return {};
    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query(DatabaseTables.transporters,
        columns: ['id', 'company_name'],
        where: 'id IN ($placeholders)',
        whereArgs: ids);
    return {
      for (final r in rows) r['id'] as int: r['company_name'] as String,
    };
  }
}
