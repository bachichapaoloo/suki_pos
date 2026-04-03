import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'suki_pos.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
        final sql = await rootBundle.loadString('assets/migrations/v1_schema.sql');
        for (final stmt in sql.split(';').where((s) => s.trim().isNotEmpty)) {
          await db.execute(stmt);
        }
      },
      onUpgrade: (db, oldV, newV) async {
        for (var v = oldV + 1; v <= newV; v++) {
          final sql = await rootBundle.loadString('assets/migrations/v${v}_migration.sql');
          for (final stmt in sql.split(';').where((s) => s.trim().isNotEmpty)) {
            await db.execute(stmt);
          }
        }
      },
    );
  }
}
