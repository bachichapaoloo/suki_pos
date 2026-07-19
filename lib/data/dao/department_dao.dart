import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schena_constants.dart';

class DepartmentDao {
  final DatabaseHelper _databaseHelper;

  DepartmentDao(this._databaseHelper);

  Future<List<Map<String, dynamic>>> getAllDepartments() async {
    final db = await _databaseHelper.database;
    return db.query(
      SchemaConstants.department,
      orderBy: 'name ASC',
    );
  }

  Future<int> insertDepartment(Map<String, dynamic> departmentMap) async {
    final db = await _databaseHelper.database;
    return db.insert(
      SchemaConstants.department,
      departmentMap,
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<int> updateDepartment(int id, Map<String, dynamic> departmentMap) async {
    final db = await _databaseHelper.database;
    departmentMap['updated_at'] = DateTime.now().toIso8601String();
    return db.update(
      SchemaConstants.department,
      departmentMap,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDepartment(int id) async {
    final db = await _databaseHelper.database;
    return db.delete(
      SchemaConstants.department,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
