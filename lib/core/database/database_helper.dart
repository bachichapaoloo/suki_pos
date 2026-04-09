import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String dbPath;

    if (Platform.isWindows) {
      // For Windows: Place database in a 'database' folder next to the .exe
      final String exePath = Platform.resolvedExecutable;
      final String exeDir = dirname(exePath);
      final String dbFolder = join(exeDir, 'database');

      // Ensure the directory exists
      final directory = Directory(dbFolder);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      dbPath = join(dbFolder, 'suki_pos.db');
    } else {
      // For Android/iOS: Use the standard databases directory
      final String databasesPath = await getDatabasesPath();
      dbPath = join(databasesPath, 'suki_pos.db');
    }

    developer.log('Initializing database at: $dbPath', name: 'DatabaseHelper');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        developer.log(
          'Creating database version $version',
          name: 'DatabaseHelper',
        );
        try {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA journal_mode = WAL');

          developer.log(
            'Loading v1_schema.sql from assets...',
            name: 'DatabaseHelper',
          );
          final sql = await rootBundle.loadString(
            'assets/migrations/v1_schema.sql',
          );

          // 1. Remove single-line comments (-- comment)
          final cleanSql = sql.replaceAll(RegExp(r'--.*'), '');

          final statements = <String>[];
          final rawStatements = cleanSql.split(';');
          String buffer = '';

          for (final stmt in rawStatements) {
            buffer += stmt;
            final trimmed = buffer.trim();
            final upper = trimmed.toUpperCase();

            // If we are in a BEGIN block but haven't reached END, keep buffering
            // This happens in TRIGGERS
            if (upper.contains('BEGIN') && !upper.contains('END')) {
              buffer += ';';
              continue;
            }

            if (trimmed.isNotEmpty) {
              statements.add(trimmed);
            }
            buffer = '';
          }

          int count = 0;
          for (final stmt in statements) {
            try {
              await db.execute(stmt);
              count++;
            } catch (e) {
              developer.log(
                'Error executing statement: $stmt',
                name: 'DatabaseHelper',
              );
              rethrow;
            }
          }
          developer.log(
            'Executed $count statements from v1_schema.sql',
            name: 'DatabaseHelper',
          );
        } catch (e, stack) {
          developer.log(
            'Error during onCreate: $e',
            name: 'DatabaseHelper',
            error: e,
            stackTrace: stack,
          );
          rethrow;
        }
      },
      onOpen: (db) async {
        developer.log('Database opened', name: 'DatabaseHelper');
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldV, newV) async {
        developer.log(
          'Upgrading database from $oldV to $newV',
          name: 'DatabaseHelper',
        );
        for (var v = oldV + 1; v <= newV; v++) {
          final sql = await rootBundle.loadString(
            'assets/migrations/v${v}_migration.sql',
          );
          for (final stmt in sql.split(';').where((s) => s.trim().isNotEmpty)) {
            await db.execute(stmt);
          }
        }
      },
    );
  }
}
