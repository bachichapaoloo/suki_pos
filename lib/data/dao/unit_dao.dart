import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart'; // Make sure the typo 'schena' is fixed!

class UnitDao {
  final DatabaseHelper _databaseHelper;

  UnitDao(this._databaseHelper);

  Future<List<Map<String, dynamic>>> getAllUnits() async {
    final db = await _databaseHelper.database;
    return await db.query(
      SchemaConstants.unit,
      orderBy: 'name ASC',
    );
  }

  Future<int> insertUnit(Map<String, dynamic> unitMap) async {
    final db = await _databaseHelper.database;
    unitMap['created_at'] = DateTime.now().toIso8601String();
    return await db.insert(
      SchemaConstants.unit,
      unitMap,
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<int> updateUnit(int id, Map<String, dynamic> unitMap) async {
    final db = await _databaseHelper.database;
    return await db.update(
      SchemaConstants.unit,
      unitMap,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUnit(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      SchemaConstants.unit,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
