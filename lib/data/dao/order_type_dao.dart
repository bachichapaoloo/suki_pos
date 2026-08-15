import 'package:sqflite/sqflite.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';

class OrderTypeDao {
  final DatabaseHelper _databaseHelper;

  OrderTypeDao(this._databaseHelper);

  Future<List<Map<String, dynamic>>> getOrderTypes() async {
    final db = await _databaseHelper.database;
    return db.query(
      SchemaConstants.orderType,
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getOrderTypeById(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.orderType,
      where: 'id = ?',
      whereArgs: [id],
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertOrderType(Map<String, dynamic> orderTypeMap) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      SchemaConstants.orderType,
      orderTypeMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateOrderType(int id, Map<String, dynamic> orderTypeMap) async {
    final db = await _databaseHelper.database;
    orderTypeMap['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      SchemaConstants.orderType,
      orderTypeMap,
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteOrderType(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      SchemaConstants.orderType,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
