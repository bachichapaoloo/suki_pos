import 'package:sqflite/sqflite.dart';
import 'package:suki_pos/services/cart_calculator.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../../domain/entities/orders/sales_order.dart';

class OrderDao {
  final DatabaseHelper _databaseHelper;

  OrderDao(this._databaseHelper);

  /// Executes checkout atomically across 7 tables in a single transaction,
  /// including stock deduction and Electronic Journal (EJ) generation.
  Future<int> checkoutOrderTransaction({
    required SalesOrderAggregate order,
    required int paymentMethodId,
    required double cashTendered,
    required double changeGiven,
  }) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // 1. Insert Master Sales Order
      final orderId = await txn.insert(SchemaConstants.salesOrder, {
        'dining_table_id': order.diningTableId,
        'order_type_id': order.orderTypeId,
        'cashier_id': order.cashierId,
        'guest_count': order.guestCount,
        'payment_status': 1, // 1 = Paid
        'remarks': order.remarks,
        'transaction_date': now,
        'paid_at': now,
        'created_at': now,
        'updated_at': now,
      });

      // 2. Insert Sale Transaction Record for BIR Audit
      final breakdown = CartCalculator.calculate(items: order.items);
      final txnId = await txn.insert(SchemaConstants.saleTransaction, {
        'sales_order_id': orderId,
        'cashier_id': order.cashierId,
        'order_type_id': order.orderTypeId,
        'guest_count': order.guestCount,
        'gross_amount': breakdown.grossSubtotal,
        'net_amount': breakdown.netTotal,
        'status': 1, // 1 = Completed
        'transaction_date': now,
        'created_at': now,
      });

      final String txnNo = 'TXN-${txnId.toString().padLeft(6, '0')}';
      final StringBuffer ejBuffer = StringBuffer();

      // Start building EJ text format
      ejBuffer.writeln('========================================');
      ejBuffer.writeln('*** ELECTRONIC JOURNAL (EJ) LOG ***');
      ejBuffer.writeln('Transaction No : $txnNo');
      ejBuffer.writeln('Sales Order ID : $orderId');
      ejBuffer.writeln('Cashier ID     : ${order.cashierId}');
      ejBuffer.writeln('Order Type ID  : ${order.orderTypeId}');
      ejBuffer.writeln('Date/Time      : $now');
      ejBuffer.writeln('----------------------------------------');
      ejBuffer.writeln('ITEMS SOLD:');

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
          'created_at': now,
        });

        ejBuffer.writeln(
          '  ${cartItem.quantity}x ${cartItem.item.name} @ ₱${cartItem.unitPrice.toStringAsFixed(2)} = ₱${cartItem.totalPrice.toStringAsFixed(2)}',
        );

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

          ejBuffer.writeln('    + Option: ${option.alias} (₱${option.priceDelta.toStringAsFixed(2)})');
        }

        if (cartItem.notes != null && cartItem.notes!.isNotEmpty) {
          ejBuffer.writeln('    Note: ${cartItem.notes}');
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
              now,
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
        'amount': breakdown.netTotal,
        'cash_tendered': cashTendered,
        'change_given': changeGiven,
        'status': 1,
        'transaction_date': now,
        'created_at': now,
      });

      // Finish EJ Text Buffer
      ejBuffer.writeln('----------------------------------------');
      ejBuffer.writeln('FINANCIAL SUMMARY:');
      ejBuffer.writeln('  Gross Subtotal : ₱${breakdown.grossSubtotal.toStringAsFixed(2)}');
      ejBuffer.writeln('  Discount       : -₱${breakdown.manualDiscountAmount.toStringAsFixed(2)}');
      ejBuffer.writeln('  VATable Sales  : ₱${breakdown.vatableSales.toStringAsFixed(2)}');
      ejBuffer.writeln('  VAT Amount 12% : ₱${breakdown.vatAmount.toStringAsFixed(2)}');
      ejBuffer.writeln('  VAT Exempt     : ₱${breakdown.vatExemptSales.toStringAsFixed(2)}');
      ejBuffer.writeln('  NET TOTAL DUE  : ₱${breakdown.netTotal.toStringAsFixed(2)}');
      ejBuffer.writeln('  Tendered       : ₱${cashTendered.toStringAsFixed(2)}');
      ejBuffer.writeln('  Change Given   : ₱${changeGiven.toStringAsFixed(2)}');
      ejBuffer.writeln('========================================');

      // 5. Save Electronic Journal (EJ) Entry
      await txn.insert(SchemaConstants.electronicJournal, {
        'sale_transaction_id': txnId,
        'cashier_id': order.cashierId,
        'activity_type': 'COMPLETED_SALE',
        'content': ejBuffer.toString(),
        'created_at': now,
      });

      return txnId;
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

  Future<void> voidOrderTransaction({
    required int transactionId,
    required int cashierId,
    required String reason,
  }) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      final txnResults = await txn.query(
        SchemaConstants.saleTransaction,
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (txnResults.isEmpty) {
        throw Exception('Transaction not found');
      }

      final txnData = txnResults.first;
      final salesOrderId = txnData['sales_order_id'] as int;

      final now = DateTime.now().toIso8601String();

      await txn.update(
        SchemaConstants.saleTransaction,
        {
          'status': 2,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      final lineItems = await txn.query(
        SchemaConstants.transactionLine,
        where: 'sales_transaction_id = ?',
        whereArgs: [transactionId],
      );

      for (final line in lineItems) {
        final itemId = line['item_id'] as int;
        final qtySold = (line['quantity'] as num).toDouble();

        await txn.rawUpdate(
          '''
          UPDATE ${SchemaConstants.stock}
          SET quantity = quantity + ?,
              remarks = ?,
              updated_at = ?
          WHERE item_id = ?
        ''',
          [qtySold, 'RESTORED: Void Txn #$transactionId', now, itemId],
        );
      }

      final ejContent =
          '''
========================================
*** VOID TRANSACTION AUDIT LOG ***
Txn ID: $transactionId
Sales Order ID: $salesOrderId
Voided By Cashier ID: $cashierId
Reason: $reason
Timestamp: $now
Restored Line Items: ${lineItems.length}
========================================
''';

      await txn.insert(SchemaConstants.electronicJournal, {
        'sale_transaction_id': transactionId,
        'cashier_id': cashierId,
        'activity_type': 'VOID_TRANSACTION',
        'content': ejContent,
        'created_at': now,
      });
    });
  }
}
