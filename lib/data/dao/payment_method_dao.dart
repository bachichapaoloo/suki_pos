import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/domain/entities/maintenance/payment_method.dart';

class PaymentMethodDao {
  final DatabaseHelper _databaseHelper;

  PaymentMethodDao(this._databaseHelper);

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.paymentMethod,
      orderBy: 'id ASC',
    );

    return results.map(PaymentMethod.fromMap).toList();
  }

  Future<List<PaymentMethod>> getActivePaymentMethods() async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.paymentMethod,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );

    return results.map(PaymentMethod.fromMap).toList();
  }

  Future<PaymentMethod?> getPaymentMethodById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      SchemaConstants.paymentMethod,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return PaymentMethod.fromMap(result.first);
    }

    return null;
  }

  Future<PaymentMethod?> getPaymentMethodByCode(String code) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      SchemaConstants.paymentMethod,
      where: 'code = ?',
      whereArgs: [code],
    );

    if (result.isNotEmpty) {
      return PaymentMethod.fromMap(result.first);
    }

    return null;
  }

  Future<int> insertPaymentMethod(PaymentMethod paymentMethod) async {
    final db = await _databaseHelper.database;
    return await db.insert(SchemaConstants.paymentMethod, paymentMethod.toMap());
  }

  Future<int> updatePaymentMethod(PaymentMethod paymentMethod) async {
    final db = await _databaseHelper.database;
    return await db.update(
      SchemaConstants.paymentMethod,
      paymentMethod.toMap(),
      where: 'id = ?',
      whereArgs: [paymentMethod.id],
    );
  }

  Future<int> deletePaymentMethod(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      SchemaConstants.paymentMethod,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
