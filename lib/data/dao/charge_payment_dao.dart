import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/domain/entities/maintenance/charge.dart';

class ChargePaymentDao {
  final DatabaseHelper _databaseHelper;

  ChargePaymentDao(this._databaseHelper);

  Future<List<Charge>> getChargePayments() async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.chargePayment,
      orderBy: 'id ASC',
    );

    return results.map(Charge.fromMap).toList();
  }

  Future<List<Charge>> getActiveChargePayments() async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.chargePayment,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );

    return results.map(Charge.fromMap).toList();
  }

  Future<List<Charge>> getChargePaymentsByChargeId(
    int chargeId,
  ) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.chargePayment,
      where: 'charge_id = ?',
      whereArgs: [chargeId],
      orderBy: 'id ASC',
    );

    return results.map(Charge.fromMap).toList();
  }

  Future<int> insertChargePayment(Charge charge) async {
    final db = await _databaseHelper.database;
    return await db.insert(SchemaConstants.chargePayment, charge.toMap());
  }

  Future<int> updateChargePayment(Charge charge) async {
    final db = await _databaseHelper.database;
    return await db.update(
      SchemaConstants.chargePayment,
      charge.toMap(),
      where: 'id = ?',
      whereArgs: [charge.id],
    );
  }

  Future<int> deleteChargePayment(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      SchemaConstants.chargePayment,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
