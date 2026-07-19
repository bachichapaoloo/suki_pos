import 'dart:async';
import 'dart:developer' as developer;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:suki_pos/core/database/schena_constants.dart';

class DatabaseHelper {
  // Singleton pattern
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  // Update this to match whatever your old v1 database file was named
  static const String _oldDatabaseName = 'kpl_pos_db.db';

  // The new v2 database file
  static const String _newDatabaseName = 'suki_pos_v2.db';
  static const int _databaseVersion = 1; // Resetting to 1 for the new schema

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final oldPath = join(dbPath, _oldDatabaseName);
    final newPath = join(dbPath, _newDatabaseName);

    // DESTRUCTIVE MIGRATION: Wipe the old v1 database completely
    final oldExists = await databaseExists(oldPath);
    if (oldExists) {
      developer.log('Legacy v1 database found. Deleting to apply v2 schema...');
      await deleteDatabase(oldPath);
      developer.log('Legacy database wiped successfully.');
    }

    // Open (or create) the new v2 database
    return openDatabase(
      newPath,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  /// Strict SQLite configurations applied on every connection
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    await db.execute('PRAGMA journal_mode = WAL;');
  }

  /// Builds the new schema in a single atomic batch
  Future<void> _onCreate(Database db, int version) async {
    developer.log('Building SukiPOS v2 Schema...');

    // Using a transaction ensures that if one script fails, the whole DB creation aborts safely
    await db.transaction((txn) async {
      final batch = txn.batch();

      // 1. Create Tables
      SchemaConstants.createTableScripts.forEach(batch.execute);

      // 2. Create Indexes
      SchemaConstants.createIndexScripts.forEach(batch.execute);

      // 3. Seed Initial Data (e.g., Superuser account)
      SchemaConstants.seedScripts.forEach(batch.execute);

      await batch.commit(noResult: true);
    });

    developer.log('SukiPOS v2 Schema is ready to go!');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
