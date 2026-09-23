import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import 'database_tables.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    String path;
    if (kIsWeb) {
      path = AppConstants.dbName;
    } else {
      final dbDir = await getDatabasesPath();
      path = '$dbDir/${AppConstants.dbName}';
    }
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: (db, version) async {
        for (final sql in DatabaseTables.createStatements) {
          await db.execute(sql);
        }
      },
    );
  }

  Future<void> init() async => database;

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> wipe() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final sql in DatabaseTables.dropStatements) {
        await txn.execute(sql);
      }
      for (final sql in DatabaseTables.createStatements) {
        await txn.execute(sql);
      }
    });
  }
}
