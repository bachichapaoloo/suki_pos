import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../../domain/entities/orders/sales_order.dart';

class OrderDao {
  final DatabaseHelper _databaseHelper;

  OrderDao(this._databaseHelper);

  /// Executes checkout atomically across 6 tables in a single transaction
  Future<int> checkoutOrderTransaction({
    required SalesOrderAggregate order,
    required int paymentMethodId,
    required double cashTendered,
    required double changeGiven,
  }) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // 1. Insert Master Sales Order
      final orderId = await txn.insert(SchemaConstants.salesOrder, {
        'dining_table_id': order.diningTableId,
        'order_type_id': order.orderTypeId,
        'cashier_id': order.cashierId,
        'guest_count': order.guestCount,
        'payment_status': 1, // Paid
        'remarks': order.remarks,
        'transaction_date': DateTime.now().toIso8601String(),
        'paid_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Insert Sale Transaction Record for BIR Audit
      final txnId = await txn.insert(SchemaConstants.saleTransaction, {
        'sales_order_id': orderId,
        'cashier_id': order.cashierId,
        'order_type_id': order.orderTypeId,
        'guest_count': order.guestCount,
        'gross_amount': order.grossAmount,
        'net_amount': order.grossAmount,
        'status': 1,
        'transaction_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // 3. Insert Line Items, Options, and Deduct Stock
      for (final cartItem in order.items) {
        final orderItemId = await txn.insert(SchemaConstants.salesOrderItem, {
          'sales_order_id': orderId,
          'item_id': cartItem.item.id,
          'item_barcode': cartItem.item.barcode ?? cartItem.item.itemCode,
          'item_name': cartItem.item.name,
          'quantity': cartItem.quantity,
          'unit_price': cartItem.unitPrice,
          'amount': cartItem.totalPrice,
          'notes': cartItem.notes,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Insert Options / Modifiers
        for (final option in cartItem.selectedOptions) {
          await txn.insert(SchemaConstants.orderItemOption, {
            'sales_order_item_id': orderItemId,
            'option_group_id': option.optionGroupId,
            'option_value_id': option.id,
            'option_value_name': option.alias,
            'price_delta': option.priceDelta,
            'quantity': 1.0,
          });
        }

        // Insert Transaction Line
        await txn.insert(SchemaConstants.transactionLine, {
          'sale_transaction_id': txnId,
          'item_id': cartItem.item.id,
          'barcode': cartItem.item.barcode ?? cartItem.item.itemCode,
          'item_name': cartItem.item.name,
          'quantity': cartItem.quantity.toDouble(),
          'unit_price': cartItem.unitPrice,
          'gross_price': cartItem.unitPrice,
          'amount': cartItem.totalPrice,
          'gross_amount': cartItem.totalPrice,
        });

        // Deduct Stock Quantity
        if (cartItem.item.id != null) {
          await txn.rawUpdate(
            '''
            UPDATE ${SchemaConstants.stock}
            SET quantity = quantity - ?,
                updated_at = ?
            WHERE item_id = ?
          ''',
            [
              cartItem.quantity,
              DateTime.now().toIso8601String(),
              cartItem.item.id,
            ],
          );
        }
      }

      // 4. Insert Payment Record
      await txn.insert(SchemaConstants.payment, {
        'sale_transaction_id': txnId,
        'cashier_id': order.cashierId,
        'payment_method_id': paymentMethodId,
        'amount': order.grossAmount,
        'cash_tendered': cashTendered,
        'change_given': changeGiven,
        'status': 1,
        'transaction_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      return orderId;
    });
  }

  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 50,
  }) async {
    final db = await _databaseHelper.database;

    return await db.rawQuery(
      '''
      SELECT
        st.id AS transaction_id,
        st.sales_order_id,
        st.gross_amount,
        st.net_amount,
        st.transaction_date,
        st.status,
        u.username AS cashier_name,
        ot.name AS order_type_name,
        p.cash_tendered,
        p.change_given,
        pm.name AS payment_method_name
      FROM ${SchemaConstants.saleTransaction} st
      LEFT JOIN ${SchemaConstants.appUser} u ON st.cashier_id = u.id
      LEFT JOIN ${SchemaConstants.orderType} ot ON st.order_type_id = ot.id
      LEFT JOIN ${SchemaConstants.payment} p ON st.id = p.sale_transaction_id
      LEFT JOIN ${SchemaConstants.paymentMethod} pm ON p.payment_method_id = pm.id
      ORDER BY st.transaction_date DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionLineDetails(int transactionId) async {
    final db = await _databaseHelper.database;

    return await db.rawQuery(
      '''
      SELECT
        tl.item_id,
        tl.item_name,
        tl.barcode,
        tl.quantity,
        tl.unit_price,
        tl.amount,
        soi.id AS sales_order_item_id
      FROM ${SchemaConstants.transactionLine} tl
      LEFT JOIN ${SchemaConstants.saleTransaction} st ON tl.sale_transaction_id = st.id
      LEFT JOIN ${SchemaConstants.salesOrderItem} soi ON soi.sales_order_id = st.sales_order_id AND soi.item_id = tl.item_id
      WHERE tl.sales_transaction_id = ?
      ''',
      [transactionId],
    );
  }

  Future<List<String>> getOrderItemOptions(int salesOrderItemId) async {
    final db = await _databaseHelper.database;

    final results = await db.query(
      SchemaConstants.orderItemOption,
      columns: ['option_value_name'],
      where: 'sales_order_item_id = ?',
      whereArgs: [salesOrderItemId],
    );

    return results.map((r) => r['option_value_name']! as String).toList();
  }
}
