import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:intl/intl.dart';
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

  /// Returns the absolute file path of the active SQLite database.
  Future<String> getDatabaseFilePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _newDatabaseName);
  }

  /// Exports a consistent snapshot of the SQLite database to [destinationFilePath]
  /// (or to a timestamped file in a `backups` folder if not provided).
  Future<String> exportDatabaseBackup({String? destinationFilePath}) async {
    final db = await database;
    // Flush WAL to main database file before copying
    try {
      await db.rawQuery('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {}

    final sourcePath = await getDatabaseFilePath();
    final sourceFile = File(sourcePath);

    String targetPath;
    if (destinationFilePath != null && destinationFilePath.trim().isNotEmpty) {
      targetPath = destinationFilePath.trim();
    } else {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupDir = Directory(join(Directory.current.path, 'backups'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      targetPath = join(backupDir.path, 'suki_pos_backup_$timestamp.db');
    }

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  /// Restores the SQLite database from [sourceFilePath] and re-opens the connection.
  Future<void> restoreDatabaseBackup(String sourceFilePath) async {
    final backupFile = File(sourceFilePath);
    if (!await backupFile.exists()) {
      throw Exception('Selected backup file does not exist.');
    }

    final targetPath = await getDatabaseFilePath();
    await close();

    // Remove WAL/SHM sidecars if present before overwriting
    final walFile = File('$targetPath-wal');
    final shmFile = File('$targetPath-shm');
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    await backupFile.copy(targetPath);
    _database = await _initDatabase();
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

  /// Opens a fresh in-memory database for unit/integration testing.
  Future<Database> initInMemoryTestDatabase() async {
    await close();
    _database = await openDatabase(
      inMemoryDatabasePath,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onOpen: _onOpen,
    );
    return _database!;
  }
}
