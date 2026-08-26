import 'dart:async';
import 'dart:developer' as developer;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:suki_pos/core/database/schema_constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  static const String _oldDatabaseName = 'kpl_pos_db.db';
  static const String _newDatabaseName = 'suki_pos_v2.db';
  static const int _databaseVersion = 3; // Incremented for schema fixes

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final oldPath = join(dbPath, _oldDatabaseName);
    final newPath = join(dbPath, _newDatabaseName);

    final oldExists = await databaseExists(oldPath);
    if (oldExists) {
      developer.log('Legacy v1 database found. Deleting...');
      await deleteDatabase(oldPath);
    }

    return openDatabase(
      newPath,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    await db.execute('PRAGMA journal_mode = WAL;');
  }

  Future<void> _onOpen(Database db) async {
    await db.transaction((txn) async {
      final batch = txn.batch();
      SchemaConstants.createTableScripts.forEach(batch.execute);
      SchemaConstants.createIndexScripts.forEach(batch.execute);
      SchemaConstants.createTriggerScripts.forEach(batch.execute);
      SchemaConstants.seedScripts.forEach(batch.execute);
      await batch.commit(noResult: true);
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from $oldVersion to $newVersion...');
    await db.transaction((txn) async {
      if (oldVersion < 3) {
        // Safe column renaming across child tables if created with legacy name
        final tablesToCheck = [
          'transaction_line',
          'payment',
          'payment_deposit',
          'cogs_line',
          'discount_beneficiary',
          'electronic_journal',
        ];

        for (final table in tablesToCheck) {
          final columns = await txn.rawQuery('PRAGMA table_info($table)');
          final hasSalesTxnId = columns.any((c) => c['name'] == 'sales_transaction_id');
          final hasSaleTxnId = columns.any((c) => c['name'] == 'sale_transaction_id');

          if (hasSalesTxnId && !hasSaleTxnId) {
            await txn.execute(
              'ALTER TABLE $table RENAME COLUMN sales_transaction_id TO sale_transaction_id;',
            );
            developer.log('Renamed sales_transaction_id -> sale_transaction_id in $table');
          }
        }
      }

      final batch = txn.batch();
      SchemaConstants.createTableScripts.forEach(batch.execute);
      SchemaConstants.createIndexScripts.forEach(batch.execute);
      await batch.commit(noResult: true);
    });
  }

  Future<void> _onCreate(Database db, int version) async {
    developer.log('Building SukiPOS v2 Schema...');
    await db.transaction((txn) async {
      final batch = txn.batch();
      SchemaConstants.createTableScripts.forEach(batch.execute);
      SchemaConstants.createIndexScripts.forEach(batch.execute);
      SchemaConstants.seedScripts.forEach(batch.execute);
      await batch.commit(noResult: true);
    });
    developer.log('SukiPOS v2 Schema is ready.');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
