import 'package:sqflite/sqflite.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../domain/entities/orders/sales_order.dart';
import '../../services/cart_calculator.dart';

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
    double manualDiscountPercentage = 0.0,
    double manualDiscountFixed = 0.0,
  }) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // 1. Resolve applied discount details if specified
      Discount? appliedDiscount;
      if (order.discountId != null) {
        final discMaps = await txn.rawQuery(
          '''
          SELECT d.*, dt.code AS discount_type_code, dt.name AS discount_type_name
          FROM ${SchemaConstants.discount} d
          JOIN ${SchemaConstants.discountType} dt ON d.discount_type_id = dt.id
          WHERE d.id = ?
          LIMIT 1
          ''',
          [order.discountId],
        );
        if (discMaps.isNotEmpty) {
          appliedDiscount = Discount.fromMap(discMaps.first);
        }
      }

      // Calculate Financial Breakdown with actual discounts & item discounts
      final breakdown = CartCalculator.calculate(
        items: order.items,
        manualDiscountPercentage: manualDiscountPercentage > 0 ? manualDiscountPercentage : (order.discPercentage),
        manualDiscountFixed: manualDiscountFixed > 0 ? manualDiscountFixed : (order.discFixedAmount),
        appliedDiscount: appliedDiscount,
        guestCount: order.guestCount,
        eligibleGuestCount: order.eligibleGuestCount,
        surchargeAmount: order.surchargeAmount,
      );

      // 2. Compute Next Sequence and SI Numbers
      final maxSi =
          Sqflite.firstIntValue(
            await txn.rawQuery('SELECT MAX(si_number) FROM ${SchemaConstants.saleTransaction}'),
          ) ??
          0;
      final nextSiNumber = maxSi + 1;

      final maxTseq =
          Sqflite.firstIntValue(
            await txn.rawQuery('SELECT MAX(tseq_no) FROM ${SchemaConstants.saleTransaction}'),
          ) ??
          0;
      final nextTseqNumber = maxTseq + 1;

      final maxSeq =
          Sqflite.firstIntValue(
            await txn.rawQuery('SELECT MAX(seq_no) FROM ${SchemaConstants.saleTransaction}'),
          ) ??
          0;
      final nextSeqNumber = maxSeq + 1;

      // Query active shift Z-number if open
      final activeShiftRes = await txn.query(
        SchemaConstants.shift,
        columns: ['id', 'start_time'],
        where: 'cashier_id = ? AND status = 1',
        whereArgs: [order.cashierId],
        limit: 1,
      );
      final zNumber = activeShiftRes.isNotEmpty ? (activeShiftRes.first['id'] as int) : 1;

      final String postingDate = activeShiftRes.isNotEmpty && activeShiftRes.first['start_time'] != null
          ? (activeShiftRes.first['start_time'] as String).substring(0, 10)
          : now.substring(0, 10);

      // 3. Insert Master Sales Order
      final orderId = await txn.insert(SchemaConstants.salesOrder, {
        'dining_table_id': order.diningTableId,
        'order_type_id': order.orderTypeId,
        'cashier_id': order.cashierId,
        'guest_count': order.guestCount,
        'eligible_guest_count': order.eligibleGuestCount,
        'payment_status': 1, // 1 = Paid
        'discount_id': order.discountId,
        'disc_percentage': order.discPercentage,
        'disc_fixed_amount': order.discFixedAmount,
        'remarks': order.remarks,
        'transaction_date': now,
        'paid_at': now,
        'created_at': now,
        'updated_at': now,
      });

      // 4. Insert Sale Transaction Record for BIR Audit
      final txnId = await txn.insert(SchemaConstants.saleTransaction, {
        'sales_order_id': orderId,
        'cashier_id': order.cashierId,
        'si_number': nextSiNumber,
        'seq_no': nextSeqNumber,
        'tseq_no': nextTseqNumber,
        'z_number': zNumber,
        'order_type_id': order.orderTypeId,
        'guest_count': order.guestCount,
        'eligible_guest_count': order.eligibleGuestCount,
        'gross_amount': breakdown.grossSubtotal,
        'discount_amount': breakdown.manualDiscountAmount,
        'item_discount_amount': breakdown.itemDiscountAmount,
        'surcharge_amount': breakdown.surchargeAmount,
        'surcharge_percent': order.surchargePercent,
        'net_amount': breakdown.netTotal,
        'vat_sales': breakdown.vatableSales,
        'vat_amount': breakdown.vatAmount,
        'vat_exempt': breakdown.vatExemptSales,
        'vat_zero_rated': breakdown.zeroRatedSales,
        'vat_private': 0.0,
        'non_vat_sales': breakdown.nonVatSales,
        'discount_id': order.discountId,
        'status': 1, // 1 = Completed
        'is_voided': 0,
        'x_read_status': 0,
        'transaction_date': now,
        'created_at': now,
        'posted_at': postingDate,
      });

      final String txnNo = 'TXN-${txnId.toString().padLeft(6, '0')}';
      final String siNo = 'SI-${nextSiNumber.toString().padLeft(6, '0')}';
      final StringBuffer ejBuffer = StringBuffer();

      // Start building EJ text format
      ejBuffer.writeln('========================================');
      ejBuffer.writeln('*** ELECTRONIC JOURNAL (EJ) LOG ***');
      ejBuffer.writeln('Invoice No     : $siNo');
      ejBuffer.writeln('Transaction No : $txnNo');
      ejBuffer.writeln('Sales Order ID : $orderId');
      ejBuffer.writeln('Cashier ID     : ${order.cashierId}');
      ejBuffer.writeln('Order Type ID  : ${order.orderTypeId}');
      ejBuffer.writeln('Guests / Elig  : ${order.guestCount} / ${order.eligibleGuestCount}');
      ejBuffer.writeln('Date/Time      : $now');
      ejBuffer.writeln('----------------------------------------');
      ejBuffer.writeln('ITEMS SOLD:');

      // 5. Insert Line Items, Options, and Deduct Stock
      for (final cartItem in order.items) {
        final isDiscExempt = cartItem.isDiscountExempt || cartItem.item.isDiscountExempt;
        final isFree = cartItem.isFreeItem;

        final orderItemId = await txn.insert(SchemaConstants.salesOrderItem, {
          'sales_order_id': orderId,
          'item_id': cartItem.item.id,
          'item_barcode': cartItem.item.barcode ?? cartItem.item.itemCode,
          'item_name': cartItem.item.name,
          'quantity': cartItem.quantity,
          'unit_price': cartItem.unitPrice,
          'amount': cartItem.effectiveTotalPrice,
          'is_disc_exempt': isDiscExempt ? 1 : 0,
          'item_discount': cartItem.totalLineDiscount,
          'notes': cartItem.notes,
          'created_at': now,
        });

        String itemLabel =
            '  ${cartItem.quantity}x ${cartItem.item.name} @ ₱${cartItem.unitPrice.toStringAsFixed(2)} = ₱${cartItem.effectiveTotalPrice.toStringAsFixed(2)}';
        if (isFree) {
          itemLabel += ' [FREE ITEM / 100% COMP]';
        } else if (cartItem.totalLineDiscount > 0) {
          itemLabel += ' [Disc: -₱${cartItem.totalLineDiscount.toStringAsFixed(2)}]';
        }
        if (isDiscExempt) {
          itemLabel += ' (Disc Exempt)';
        }
        ejBuffer.writeln(itemLabel);

        // Insert Options / Modifiers
        for (final option in cartItem.selectedOptions) {
          await txn.insert(SchemaConstants.orderItemOption, {
            'sales_order_item_id': orderItemId,
            'option_group_id': option.optionGroupId,
            'option_value_id': option.id,
            'option_group_name': null,
            'option_value_name': option.alias ?? '',
            'price_delta': option.priceDelta,
            'quantity': 1.0,
          });

          ejBuffer.writeln('    + Option: ${option.alias ?? ''} (₱${option.priceDelta.toStringAsFixed(2)})');
        }

        if (cartItem.notes != null && cartItem.notes!.isNotEmpty) {
          ejBuffer.writeln('    Note: ${cartItem.notes}');
        }

        // Calculate line-level tax breakdown
        final lineEffectiveGross = cartItem.effectiveTotalPrice;
        final isVatExempt = cartItem.item.isVatExempt;
        final lineVatableSales = isVatExempt ? 0.0 : (lineEffectiveGross / 1.12);
        final lineVatAmount = isVatExempt ? 0.0 : (lineEffectiveGross - lineVatableSales);
        final lineVatExemptSales = isVatExempt ? lineEffectiveGross : 0.0;

        // Insert Transaction Line (Standardized sale_transaction_id)
        await txn.insert(SchemaConstants.transactionLine, {
          'sale_transaction_id': txnId,
          'item_id': cartItem.item.id,
          'barcode': cartItem.item.barcode ?? cartItem.item.itemCode,
          'item_name': cartItem.item.name,
          'quantity': cartItem.quantity.toDouble(),
          'unit_price': cartItem.effectiveUnitPrice,
          'gross_price': cartItem.unitPrice,
          'amount': cartItem.effectiveTotalPrice,
          'gross_amount': cartItem.totalPrice,
          'cost_price': cartItem.item.costPrice,
          'deduction': cartItem.totalLineDiscount,
          'disc_fixed_amt': cartItem.itemDiscountAmount,
          'disc_percent': cartItem.itemDiscountPercent,
          'is_disc_exempt': isDiscExempt ? 1 : 0,
          'order_type_id': order.orderTypeId,
          'vat_sales': lineVatableSales,
          'vat_amount': lineVatAmount,
          'vat_exempt_sales': lineVatExemptSales,
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

      // 6. Insert Payment Record
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

      // 7. Insert Statutory Discount Beneficiary if recorded
      if (order.beneficiaryName != null && order.beneficiaryName!.isNotEmpty) {
        final discTypeId = order.beneficiaryDiscountTypeId ?? (appliedDiscount?.discountTypeId ?? 2);
        await txn.insert(SchemaConstants.discountBeneficiary, {
          'sale_transaction_id': txnId,
          'tseq_no': nextTseqNumber,
          'discount_type_id': discTypeId,
          'beneficiary_name': order.beneficiaryName ?? 'N/A',
          'id_number': order.beneficiaryIdNo,
          'created_at': now,
        });
      }

      // Finish EJ Text Buffer
      ejBuffer.writeln('----------------------------------------');
      ejBuffer.writeln('FINANCIAL SUMMARY:');
      ejBuffer.writeln('  Gross Subtotal : ₱${breakdown.grossSubtotal.toStringAsFixed(2)}');
      if (breakdown.itemDiscountAmount > 0) {
        ejBuffer.writeln('  Item Discounts : -₱${breakdown.itemDiscountAmount.toStringAsFixed(2)}');
      }
      ejBuffer.writeln('  Order Discount : -₱${breakdown.manualDiscountAmount.toStringAsFixed(2)}');
      if (appliedDiscount != null) {
        ejBuffer.writeln('  Discount Name  : ${appliedDiscount.name}');
      }
      if (order.beneficiaryName != null && order.beneficiaryName!.isNotEmpty) {
        ejBuffer.writeln('  Beneficiary    : ${order.beneficiaryName} (ID: ${order.beneficiaryIdNo ?? "N/A"})');
      }
      if (breakdown.surchargeAmount > 0) {
        ejBuffer.writeln('  Surcharge      : +₱${breakdown.surchargeAmount.toStringAsFixed(2)}');
      }
      ejBuffer.writeln('  VATable Sales  : ₱${breakdown.vatableSales.toStringAsFixed(2)}');
      ejBuffer.writeln('  VAT Amount 12% : ₱${breakdown.vatAmount.toStringAsFixed(2)}');
      ejBuffer.writeln('  VAT Exempt     : ₱${breakdown.vatExemptSales.toStringAsFixed(2)}');
      ejBuffer.writeln('  NET TOTAL DUE  : ₱${breakdown.netTotal.toStringAsFixed(2)}');
      ejBuffer.writeln('  Tendered       : ₱${cashTendered.toStringAsFixed(2)}');
      ejBuffer.writeln('  Change Given   : ₱${changeGiven.toStringAsFixed(2)}');
      ejBuffer.writeln('========================================');

      // 8. Save Electronic Journal (EJ) Entry
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
        st.guest_count,
        st.eligible_guest_count,
        st.discount_amount AS order_discount_amount,
        st.item_discount_amount,
        st.vat_sales AS vatable_sales,
        st.vat_amount,
        st.vat_exempt AS vat_exempt_sales,
        st.vat_zero_rated AS zero_rated_sales,
        st.transaction_date,
        st.status,
        u.name AS cashier_name,
        ot.name AS order_type_name,
        p.cash_tendered,
        p.change_given,
        pm.name AS payment_method_name,
        d.name AS discount_name,
        dben.beneficiary_name,
        dben.id_number AS beneficiary_id_no
      FROM ${SchemaConstants.saleTransaction} st
      LEFT JOIN ${SchemaConstants.appUser} u ON st.cashier_id = u.id
      LEFT JOIN ${SchemaConstants.orderType} ot ON st.order_type_id = ot.id
      LEFT JOIN ${SchemaConstants.payment} p ON st.id = p.sale_transaction_id
      LEFT JOIN ${SchemaConstants.paymentMethod} pm ON p.payment_method_id = pm.id
      LEFT JOIN ${SchemaConstants.discount} d ON st.discount_id = d.id
      LEFT JOIN ${SchemaConstants.discountBeneficiary} dben ON dben.sale_transaction_id = st.id
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
        tl.deduction AS line_discount,
        tl.disc_percent,
        tl.disc_fixed_amt,
        soi.id AS sales_order_item_id
      FROM ${SchemaConstants.transactionLine} tl
      LEFT JOIN ${SchemaConstants.saleTransaction} st ON tl.sale_transaction_id = st.id
      LEFT JOIN ${SchemaConstants.salesOrderItem} soi ON soi.sales_order_id = st.sales_order_id AND soi.item_id = tl.item_id
      WHERE tl.sale_transaction_id = ?
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

      // 1. Mark Transaction & Order as Voided
      await txn.update(
        SchemaConstants.saleTransaction,
        {
          'status': 2,
          'is_voided': 1,
          'posted_at': now,
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      await txn.update(
        SchemaConstants.salesOrder,
        {
          'payment_status': 2,
          'remarks': 'VOIDED: $reason',
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [salesOrderId],
      );

      // 2. Fetch lines using standardized sale_transaction_id
      final lineItems = await txn.query(
        SchemaConstants.transactionLine,
        where: 'sale_transaction_id = ?',
        whereArgs: [transactionId],
      );

      // 3. Restore Stock with null-safety
      for (final line in lineItems) {
        final itemId = line['item_id'] as int?;
        final qtySold = (line['quantity'] as num).toDouble();

        if (itemId != null) {
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
      }

      // 4. Log to Electronic Journal
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

  /// Retrieves live aggregated metrics for the POS Dashboard.
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final todayStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Total sales today
    final salesRes = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(net_amount), 0.0) AS total_sales, COUNT(*) AS completed_count
      FROM ${SchemaConstants.saleTransaction}
      WHERE transaction_date LIKE ? AND is_voided = 0
      ''',
      ['$todayStr%'],
    );

    // Active (pending/unpaid) orders count
    final activeRes = await db.rawQuery(
      '''
      SELECT COUNT(*) AS active_count
      FROM ${SchemaConstants.salesOrder}
      WHERE payment_status = 0
      ''',
    );

    // Total orders count today
    final ordersRes = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total_orders_today
      FROM ${SchemaConstants.salesOrder}
      WHERE transaction_date LIKE ?
      ''',
      ['$todayStr%'],
    );

    final totalSales = (salesRes.isNotEmpty ? salesRes.first['total_sales'] as num? : 0.0)?.toDouble() ?? 0.0;
    final completedCount = (salesRes.isNotEmpty ? (salesRes.first['completed_count'] as num?)?.toInt() : 0) ?? 0;
    final activeCount = (activeRes.isNotEmpty ? (activeRes.first['active_count'] as num?)?.toInt() : 0) ?? 0;
    final totalOrdersToday = (ordersRes.isNotEmpty ? (ordersRes.first['total_orders_today'] as num?)?.toInt() : 0) ?? 0;

    return {
      'total_sales': totalSales,
      'completed_count': completedCount,
      'active_count': activeCount,
      'total_orders_today': totalOrdersToday,
    };
  }

  /// Retrieves list of sales orders with table names, cashier, and order types.
  Future<List<Map<String, dynamic>>> getSalesOrders({int? paymentStatus, int limit = 50}) async {
    final db = await _databaseHelper.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (paymentStatus != null) {
      whereClause = 'WHERE so.payment_status = ?';
      whereArgs.add(paymentStatus);
    }

    whereArgs.add(limit);

    return await db.rawQuery(
      '''
      SELECT 
        so.*,
        dt.name AS table_name,
        ot.name AS order_type_name,
        u.name AS cashier_name,
        (SELECT COUNT(*) FROM ${SchemaConstants.salesOrderItem} soi WHERE soi.sales_order_id = so.id) AS item_count,
        (SELECT COALESCE(SUM(soi.amount), 0.0) FROM ${SchemaConstants.salesOrderItem} soi WHERE soi.sales_order_id = so.id) AS total_amount
      FROM ${SchemaConstants.salesOrder} so
      LEFT JOIN ${SchemaConstants.diningTable} dt ON so.dining_table_id = dt.id
      LEFT JOIN ${SchemaConstants.orderType} ot ON so.order_type_id = ot.id
      LEFT JOIN ${SchemaConstants.appUser} u ON so.cashier_id = u.id
      $whereClause
      ORDER BY so.created_at DESC
      LIMIT ?
      ''',
      whereArgs,
    );
  }

  /// Holds / creates a pending sales order without checking out payment.
  Future<int> holdSalesOrder({
    required SalesOrderAggregate order,
  }) async {
    final db = await _databaseHelper.database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      final orderId = await txn.insert(SchemaConstants.salesOrder, {
        'dining_table_id': order.diningTableId,
        'order_type_id': order.orderTypeId,
        'cashier_id': order.cashierId,
        'guest_count': order.guestCount,
        'payment_status': 0, // 0 = Pending/Hold
        'disc_percentage': order.discPercentage,
        'disc_fixed_amount': order.discFixedAmount,
        'remarks': order.remarks,
        'transaction_date': now,
        'created_at': now,
        'updated_at': now,
      });

      for (final cartItem in order.items) {
        await txn.insert(SchemaConstants.salesOrderItem, {
          'sales_order_id': orderId,
          'item_id': cartItem.item.id,
          'item_barcode': cartItem.item.barcode ?? cartItem.item.itemCode,
          'item_name': cartItem.item.name,
          'quantity': cartItem.quantity,
          'unit_price': cartItem.unitPrice,
          'amount': cartItem.totalPrice,
          'is_disc_exempt': cartItem.item.isDiscountExempt ? 1 : 0,
          'notes': cartItem.notes,
          'created_at': now,
        });
      }

      return orderId;
    });
  }

  /// Cancels / Voids a pending sales order.
  Future<void> cancelPendingOrder(int orderId) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      SchemaConstants.salesOrder,
      {
        'payment_status': 2, // 2 = Voided/Cancelled
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
}
