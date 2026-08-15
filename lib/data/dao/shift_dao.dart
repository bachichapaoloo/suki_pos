import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../domain/entities/shift/cash_denomination_count.dart';

class ShiftDao {
  final DatabaseHelper _databaseHelper;

  ShiftDao(this._databaseHelper);

  /// Check if cashier has an open shift
  Future<Map<String, dynamic>?> getActiveShift(int cashierId) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.shift,
      where: 'cashier_id = ? AND status = 1',
      whereArgs: [cashierId],
      orderBy: 'start_time DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Step 1: Open shift and log change fund
  Future<int> openShift(int cashierId, double beginningCash) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.insert(SchemaConstants.shift, {
      'cashier_id': cashierId,
      'beginning_cash': beginningCash,
      'status': 1,
      'start_time': now,
      'created_at': now,
    });
  }

  /// Step 3 & 4: Save Tender Declaration and Denominations
  Future<int> saveCashDeclaration({
    required int cashierId,
    required double totalCash,
    required double changeFund,
    required List<CashDenominationCount> denominations,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final declarationId = await txn.insert(SchemaConstants.cashDeclaration, {
        'cashier_id': cashierId,
        'total_cash': totalCash,
        'total_amount': totalCash,
        'change_fund': changeFund,
        'status': 1,
        'transaction_date': now,
        'created_at': now,
      });

      final batch = txn.batch();
      for (final denom in denominations) {
        batch.insert(SchemaConstants.cashDeclarationDenomination, {
          'cash_declaration_id': declarationId,
          'denomination': denom.denomination,
          'quantity': denom.count,
        });
      }

      await batch.commit(noResult: true);
      return declarationId;
    });
  }

  /// Calculates theoretical cash collected for active shift
  Future<double> getShiftCashSales(String startTime, String endTime) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(p.cash_tendered - p.change_given) AS total_cash_sales
      FROM ${SchemaConstants.payment} p
      INNER JOIN ${SchemaConstants.saleTransaction} st ON p.sale_transaction_id = st.id
      WHERE st.status = 1 AND st.transaction_date >= ? AND st.transaction_date <= ?
    ''',
      [startTime, endTime],
    );

    return (result.first['total_cash_sales'] as num? ?? 0.0).toDouble();
  }

  /// Step 5: Close Shift, record Short/Over, and update Shift record
  Future<void> closeShift({
    required int shiftId,
    required int cashierId,
    required double beginningCash,
    required double theoreticalCashSales,
    required double actualCashCount,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final expectedTotal = beginningCash + theoreticalCashSales;
    final variance = actualCashCount - expectedTotal;

    await db.transaction((txn) async {
      // 1. Record Short/Over
      await txn.insert(SchemaConstants.shortOver, {
        'cashier_id': cashierId,
        'total_cash': actualCashCount,
        'change_fund': beginningCash,
        'total_collected': theoreticalCashSales,
        'theoretical_sales': expectedTotal,
        'actual_cash': actualCashCount,
        'short_amount': variance < 0 ? variance.abs() : 0.0,
        'over_amount': variance > 0 ? variance : 0.0,
        'short_over_amount': variance,
        'status': 1,
        'transaction_date': now,
        'created_at': now,
      });

      // 2. Close Shift
      await txn.update(
        SchemaConstants.shift,
        {
          'ending_cash': actualCashCount,
          'cash_variance': variance,
          'status': 2, // Closed
          'end_time': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [shiftId],
      );
    });
  }
}
