import 'package:sqflite/sql.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';

class StockDao {
  final DatabaseHelper _databaseHelper;

  StockDao(this._databaseHelper);

  Future<List<Map<String, dynamic>>> getAllStock() async {
    final db = await _databaseHelper.database;
    return await db.query(SchemaConstants.stock);
  }

  Future<Map<String, dynamic>?> getStockByItemId(int itemId) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.stock,
      where: 'item_id = ?',
      whereArgs: [itemId],
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getStockWithItemDetails() async {
    final db = await _databaseHelper.database;
    return await db.rawQuery('''
      SELECT 
        s.*,
        i.name as item_name,
        i.item_code,
        i.barcode,
        u.name AS unit_name
      FROM ${SchemaConstants.stock} s
      INNER JOIN ${SchemaConstants.item} i ON s.item_id = i.id
      LEFT JOIN ${SchemaConstants.unit} u ON i.unit_id = u.id
      WHERE i.is_active = 1
      ORDER BY i.name ASC
''');
  }

  Future<void> updateQuantityDelta(int itemId, double delta, {String? remarks}) async {
    final db = await _databaseHelper.database;
    await db.rawUpdate(
      '''
      UPDATE ${SchemaConstants.stock}
      SET quantity = quantity + ?,
          remarks = COALESCE(?, remarks),
          updated_at = ?
      WHERE item_id = ?
    ''',
      [delta, remarks, DateTime.now().toIso8601String(), itemId],
    );
  }

  Future<int> upsertStock(Map<String, dynamic> stockMap) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      SchemaConstants.stock,
      stockMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
