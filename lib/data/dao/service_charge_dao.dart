import 'package:sqflite/sqflite.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';

class ServiceChargeDao {
  final DatabaseHelper _databaseHelper;

  ServiceChargeDao(this._databaseHelper);

  Future<Map<String, dynamic>?> getServiceChargeConfig() async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.serviceCharge,
      orderBy: 'id ASC',
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<int> saveServiceChargeConfig({
    required double amount,
    required bool isActive,
  }) async {
    final db = await _databaseHelper.database;
    final existing = await getServiceChargeConfig();

    if (existing != null) {
      return await db.update(
        SchemaConstants.serviceCharge,
        {
          'amount': amount,
          'is_active': isActive ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
    } else {
      return await db.insert(
        SchemaConstants.serviceCharge,
        {
          'id': 1,
          'amount': amount,
          'is_active': isActive ? 1 : 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
