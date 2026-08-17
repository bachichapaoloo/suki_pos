import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/maintenance/discount_type.dart';

class DiscountDao {
  final DatabaseHelper _databaseHelper;

  DiscountDao(this._databaseHelper);

  Future<List<DiscountType>> getDiscountTypes() async {
    final db = await _databaseHelper.database;
    final list = await db.query(SchemaConstants.discountType, orderBy: 'code ASC');
    return list.map(DiscountType.fromMap).toList();
  }

  Future<List<Discount>> getAllDiscounts({bool onlyActive = false}) async {
    final db = await _databaseHelper.database;
    final list = await db.rawQuery('''
      SELECT 
        d.*,
        dt.code AS discount_type_code,
        dt.name AS discount_type_name
      FROM ${SchemaConstants.discount} d
      JOIN ${SchemaConstants.discountType} dt ON d.discount_type_id = dt.id
      ${onlyActive ? 'WHERE d.active = 1' : ''}
      ORDER BY d.name ASC
    ''');

    return list.map(Discount.fromMap).toList();
  }

  Future<Discount?> getDiscountById(int id) async {
    final db = await _databaseHelper.database;
    final list = await db.rawQuery(
      '''
      SELECT 
        d.*,
        dt.code AS discount_type_code,
        dt.name AS discount_type_name
      FROM ${SchemaConstants.discount} d
      JOIN ${SchemaConstants.discountType} dt ON d.discount_type_id = dt.id
      WHERE d.id = ?
      ORDER BY d.name ASC
    ''',
      [id],
    );

    if (list.isNotEmpty) return Discount.fromMap(list.first);
    return null;
  }

  Future<int> insertDiscount(Map<String, dynamic> discountMap) async {
    final db = await _databaseHelper.database;
    return db.insert(SchemaConstants.discount, discountMap);
  }

  Future<int> updateDiscount(int id, Map<String, dynamic> discountMap) async {
    final db = await _databaseHelper.database;
    return db.update(SchemaConstants.discount, discountMap, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDiscount(int id) async {
    final db = await _databaseHelper.database;
    return db.delete(SchemaConstants.discount, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> toggleDiscountStatus(int id, bool isActive) async {
    final db = await _databaseHelper.database;
    return await db.update(
          SchemaConstants.discount,
          {'active': isActive ? 1 : 0},
          where: 'id = ?',
          whereArgs: [id],
        ) ==
        1;
  }
}
