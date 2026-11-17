import 'package:sqflite/sqflite.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/pos/tender_payment_leg.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../domain/entities/orders/sales_order.dart';
import '../../services/cart_calculator.dart';

class OrderDao {
  final DatabaseHelper _databaseHelper;

  OrderDao(this._databaseHelper);

  /// Ensures the single-row `counter_table` (id = 1) exists and is synced with existing max sequences.
  Future<Map<String, dynamic>> _ensureCounterRow(Transaction txn) async {
    final rows = await txn.query(
      SchemaConstants.counterTable,
      where: 'id = 1',
      limit: 1,
    );
    final maxSi = Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COALESCE(MAX(si_number), 0) FROM ${SchemaConstants.saleTransaction}',
          ),
        ) ??
        0;
    final maxTseq = Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COALESCE(MAX(tseq_no), 0) FROM ${SchemaConstants.saleTransaction}',
          ),
        ) ??
        0;

    if (rows.isEmpty) {
      final now = DateTime.now().toIso8601String();
      await txn.insert(SchemaConstants.counterTable, {
        'id': 1,
        'tseq_no': maxTseq,
        'si_number': maxSi,
        'z_read_count': 0,
        'post_void_count': 0,
        'so_number': 1,
        'incoming_number': 1,
        'outgoing_number': 1,
        'deposit_number': 1,
        'trans_number': maxSi,
        'last_updated': now,
      });
      return {
        'id': 1,
        'tseq_no': maxTseq,
        'si_number': maxSi,
        'z_read_count': 0,
        'post_void_count': 0,
        'trans_number': maxSi,
      };
    }

    final current = Map<String, dynamic>.from(rows.first);
    final curTseq = (current['tseq_no'] as num? ?? 0).toInt();
    final curSi = (current['si_number'] as num? ?? 0).toInt();
    if (maxTseq > curTseq || maxSi > curSi) {
      final syncedTseq = maxTseq > curTseq ? maxTseq : curTseq;
      final syncedSi = maxSi > curSi ? maxSi : curSi;
      await txn.update(
        SchemaConstants.counterTable,
        {
          'tseq_no': syncedTseq,
          'si_number': syncedSi,
          'last_updated': DateTime.now().toIso8601String(),
        },
        where: 'id = 1',
      );
      current['tseq_no'] = syncedTseq;
      current['si_number'] = syncedSi;
    }
    return current;
  }

  /// Executes checkout atomically across all normalized POS tables (`sales_order`,
  /// `sale_transaction`, `transaction_line` [with full `sales_m2` columns & modifiers],
  /// `cogs_line` [`sales_m3`], `payment` [all 6 tender types + Split Payment pro-ration],
  /// `discount_beneficiary`, `customer`, `gift_check_serial`, `stock`, `electronic_journal`,
  /// and `counter_table`).
  Future<int> checkoutOrderTransaction({
    required SalesOrderAggregate order,
    required int paymentMethodId,
    required double cashTendered,
    required double changeGiven,
    double manualDiscountPercentage = 0.0,
    double manualDiscountFixed = 0.0,
    int? bankId,
    String? referenceNumber,
    int? chargeAccountId,
    List<TenderPaymentLeg>? payments,
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
        manualDiscountPercentage: manualDiscountPercentage > 0
            ? manualDiscountPercentage
            : (order.discPercentage),
        manualDiscountFixed: manualDiscountFixed > 0
            ? manualDiscountFixed
            : (order.discFixedAmount),
        appliedDiscount: appliedDiscount,
        guestCount: order.guestCount,
        eligibleGuestCount: order.eligibleGuestCount,
        surchargeAmount: order.surchargeAmount,
        surchargePercent: order.surchargePercent,
      );

      // Compute VAT Private (12% VAT removed on statutory SC/PWD discounts)
      final isSpecialVatExempt = appliedDiscount?.isSpecialVatExempt ?? false;
      double totalVatPrivate = 0.0;
      if (isSpecialVatExempt) {
        final safeGuest = order.guestCount > 0 ? order.guestCount : 1;
        final safeElig = order.eligibleGuestCount > 0
            ? (order.eligibleGuestCount <= safeGuest
                ? order.eligibleGuestCount
                : safeGuest)
            : safeGuest;
        final shareRatio = safeElig / safeGuest;
        double discGross = 0.0;
        for (final ci in order.items) {
          final isExempt =
              ci.isDiscountExempt || ci.item.isDiscountExempt || ci.isFreeItem;
          if (!isExempt && !ci.item.isVatExempt) {
            discGross += ci.effectiveTotalPrice;
          }
        }
        final eligibleGross = discGross * shareRatio;
        final netOfVat = eligibleGross / 1.12;
        totalVatPrivate = eligibleGross - netOfVat;
      }

      // 2. Atomically allocate Next Sequence and SI Numbers via counter_table
      final counter = await _ensureCounterRow(txn);
      final nextTseqNumber = (counter['tseq_no'] as num).toInt() + 1;
      final nextSiNumber = (counter['si_number'] as num).toInt() + 1;
      final nextTransNumber = (counter['trans_number'] as num? ?? 0).toInt() + 1;

      await txn.update(
        SchemaConstants.counterTable,
        {
          'tseq_no': nextTseqNumber,
          'si_number': nextSiNumber,
          'trans_number': nextTransNumber,
          'last_updated': now,
        },
        where: 'id = 1',
      );

      final maxSeq =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COALESCE(MAX(seq_no), 0) FROM ${SchemaConstants.saleTransaction}',
            ),
          ) ??
          0;
      final nextSeqNumber = maxSeq + 1;

      // Query active shift for posting date reference, but keep z_number = 0 (un-Z-read) per KwikPOS Lite
      final activeShiftRes = await txn.query(
        SchemaConstants.shift,
        columns: ['id', 'start_time'],
        where: 'cashier_id = ? AND status = 1',
        whereArgs: [order.cashierId],
        limit: 1,
      );

      final String postingDate =
          activeShiftRes.isNotEmpty &&
              activeShiftRes.first['start_time'] != null
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

      // 4. Insert Sale Transaction Record (`sales_m2` header parity, z_number = 0, x_read_status = 0)
      final txnId = await txn.insert(SchemaConstants.saleTransaction, {
        'sales_order_id': orderId,
        'cashier_id': order.cashierId,
        'si_number': nextSiNumber,
        'seq_no': nextSeqNumber,
        'tseq_no': nextTseqNumber,
        'z_number': 0, // 0 = Un-Z-Read (sealed when Z-Reading runs)
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
        'vat_private': totalVatPrivate,
        'non_vat_sales': breakdown.nonVatSales,
        'discount_id': order.discountId,
        'status': 1, // 1 = Completed
        'is_voided': 0,
        'x_read_status': 0, // 0 = Un-X-Read (sealed when X-Reading runs)
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
      ejBuffer.writeln('TSEQ No        : $nextTseqNumber');
      ejBuffer.writeln('Transaction No : $txnNo');
      ejBuffer.writeln('Sales Order ID : $orderId');
      ejBuffer.writeln('Cashier ID     : ${order.cashierId}');
      ejBuffer.writeln('Order Type ID  : ${order.orderTypeId}');
      ejBuffer.writeln(
        'Guests / Elig  : ${order.guestCount} / ${order.eligibleGuestCount}',
      );
      ejBuffer.writeln('Date/Time      : $now');
      ejBuffer.writeln('----------------------------------------');
      ejBuffer.writeln('ITEMS SOLD:');

      // Pre-calculate discountable gross & effective subtotal for pro-rating order discount & surcharge across lines
      double totalDiscountableEffective = 0.0;
      double totalEffectiveSubtotal = 0.0;
      for (final ci in order.items) {
        totalEffectiveSubtotal += ci.effectiveTotalPrice;
        final isExempt =
            ci.isDiscountExempt || ci.item.isDiscountExempt || ci.isFreeItem;
        if (!isExempt) {
          totalDiscountableEffective += ci.effectiveTotalPrice;
        }
      }

      // 5. Insert Line Items (`sales_m2` line parity), Modifiers, COGS (`sales_m3` -> `cogs_line`), and Deduct Stock
      int lineIndex = 0;
      for (final cartItem in order.items) {
        lineIndex++;
        final isDiscExempt =
            cartItem.isDiscountExempt || cartItem.item.isDiscountExempt;
        final isFree = cartItem.isFreeItem;

        // Lookup Category & Department names for snapshot on transaction_line
        String? categoryName;
        String? departmentName;
        final catRows = await txn.query(
          SchemaConstants.category,
          columns: ['name'],
          where: 'id = ?',
          whereArgs: [cartItem.item.categoryId],
          limit: 1,
        );
        if (catRows.isNotEmpty) {
          categoryName = catRows.first['name'] as String?;
        }
        final deptRows = await txn.query(
          SchemaConstants.department,
          columns: ['name'],
          where: 'id = ?',
          whereArgs: [cartItem.item.departmentId],
          limit: 1,
        );
        if (deptRows.isNotEmpty) {
          departmentName = deptRows.first['name'] as String?;
        }

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
          itemLabel +=
              ' [Disc: -₱${cartItem.totalLineDiscount.toStringAsFixed(2)}]';
        }
        if (isDiscExempt) {
          itemLabel += ' (Disc Exempt)';
        }
        ejBuffer.writeln(itemLabel);

        // Calculate options / modifier added amount
        final optionsDeltaPerUnit = cartItem.selectedOptions.fold<double>(
          0.0,
          (sum, opt) => sum + opt.priceDelta,
        );
        final lineAddedAmount = optionsDeltaPerUnit * cartItem.quantity;

        // Insert Options / Modifiers into order_item_option
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

          ejBuffer.writeln(
            '    + Option: ${option.alias ?? ''} (₱${option.priceDelta.toStringAsFixed(2)})',
          );
        }

        if (cartItem.notes != null && cartItem.notes!.isNotEmpty) {
          ejBuffer.writeln('    Note: ${cartItem.notes}');
        }

        // Pro-rate order-level discount and surcharge onto this line (KwikPOS Lite sales_m2 parity)
        final lineEffectiveBeforeOrderDisc = cartItem.effectiveTotalPrice;
        final double lineOrderDiscountShare = (!isDiscExempt &&
                !isFree &&
                totalDiscountableEffective > 0 &&
                breakdown.manualDiscountAmount > 0)
            ? breakdown.manualDiscountAmount *
                (lineEffectiveBeforeOrderDisc / totalDiscountableEffective)
            : 0.0;
        final double lineTotalDeduction =
            cartItem.totalLineDiscount + lineOrderDiscountShare;
        final double lineSurchargeShare =
            (totalEffectiveSubtotal > 0 && breakdown.surchargeAmount > 0)
                ? breakdown.surchargeAmount *
                    (lineEffectiveBeforeOrderDisc / totalEffectiveSubtotal)
                : 0.0;
        final double lineNetChargeAmount =
            (lineEffectiveBeforeOrderDisc - lineOrderDiscountShare)
                .clamp(0.0, double.infinity);

        // Calculate line-level tax breakdown (VATable, VAT 12%, VAT Exempt, VAT Private)
        final isVatExemptItem = cartItem.item.isVatExempt;
        double lineVatableSales = 0.0;
        double lineVatAmount = 0.0;
        double lineVatExemptSales = 0.0;
        double lineVatPrivate = 0.0;

        if (isVatExemptItem) {
          lineVatExemptSales = lineNetChargeAmount;
        } else if (isSpecialVatExempt && !isDiscExempt && !isFree) {
          final safeGuest = order.guestCount > 0 ? order.guestCount : 1;
          final safeElig = order.eligibleGuestCount > 0
              ? (order.eligibleGuestCount <= safeGuest
                  ? order.eligibleGuestCount
                  : safeGuest)
              : safeGuest;
          final shareRatio = safeElig / safeGuest;
          final eligGross = lineEffectiveBeforeOrderDisc * shareRatio;
          final nonEligGross = lineEffectiveBeforeOrderDisc - eligGross;
          final netOfVatElig = eligGross / 1.12;
          lineVatPrivate = eligGross - netOfVatElig;
          lineVatExemptSales =
              (netOfVatElig - lineOrderDiscountShare).clamp(0.0, double.infinity);
          lineVatableSales = nonEligGross / 1.12;
          lineVatAmount = nonEligGross - lineVatableSales;
        } else {
          final lineWithSurcharge = lineNetChargeAmount + lineSurchargeShare;
          lineVatableSales = lineWithSurcharge / 1.12;
          lineVatAmount = lineWithSurcharge - lineVatableSales;
        }

        final String? customizationKey = cartItem.selectedOptions.isNotEmpty
            ? 'CUST_${txnId}_$lineIndex'
            : null;
        final int itemTypeCode = cartItem.item.isComposition
            ? 2
            : (cartItem.item.isFinishedGood ? 1 : 0);

        // Insert Parent Transaction Line (full KwikPOS Lite sales_m2 fields)
        await txn.insert(SchemaConstants.transactionLine, {
          'sale_transaction_id': txnId,
          'item_id': cartItem.item.id,
          'barcode': cartItem.item.barcode ?? cartItem.item.itemCode,
          'item_name': cartItem.item.name,
          'category_name': categoryName,
          'department_name': departmentName,
          'quantity': cartItem.quantity.toDouble(),
          'unit_price': cartItem.effectiveUnitPrice,
          'gross_price': cartItem.unitPrice,
          'amount': lineNetChargeAmount,
          'gross_amount': cartItem.totalPrice,
          'cost_price': cartItem.item.costPrice,
          'deduction': lineTotalDeduction,
          'added_amount': lineAddedAmount,
          'surcharge': lineSurchargeShare,
          'disc_type': appliedDiscount?.discountTypeId,
          'disc_fixed_amt': cartItem.itemDiscountAmount,
          'disc_percent': cartItem.itemDiscountPercent > 0
              ? cartItem.itemDiscountPercent
              : (lineOrderDiscountShare > 0
                  ? (appliedDiscount?.percentage ?? order.discPercentage)
                  : 0.0),
          'is_disc_exempt': isDiscExempt ? 1 : 0,
          'vat_sales': lineVatableSales,
          'vat_amount': lineVatAmount,
          'non_vat': 0.0,
          'vat_exempt_sales': lineVatExemptSales,
          'vat_private': lineVatPrivate,
          'zero_rated': 0.0,
          'item_type': itemTypeCode,
          'order_type_id': order.orderTypeId,
          'box_barcode': cartItem.item.itemCode,
          'tax_code': isVatExemptItem ? 2 : 1,
          'customization_key': customizationKey,
          'customization_seq': customizationKey != null ? 1 : null,
        });

        // Insert Child Customization / Option Rows in transaction_line (KwikPOS Lite customization_sequence = 2..N parity)
        if (customizationKey != null) {
          int custSeq = 1;
          for (final opt in cartItem.selectedOptions) {
            custSeq++;
            await txn.insert(SchemaConstants.transactionLine, {
              'sale_transaction_id': txnId,
              'item_id': opt.itemId ?? cartItem.item.id,
              'barcode': cartItem.item.barcode ?? cartItem.item.itemCode,
              'item_name': '+ ${opt.alias ?? 'Option'}',
              'category_name': categoryName,
              'department_name': departmentName,
              'quantity': 0.0, // Keep 0 so item quantity sums are not inflated
              'unit_price': opt.priceDelta,
              'gross_price': opt.priceDelta,
              'amount': 0.0, // Already included in parent line amount
              'gross_amount': 0.0,
              'cost_price': opt.costPriceDelta,
              'deduction': 0.0,
              'added_amount': opt.priceDelta * cartItem.quantity,
              'surcharge': 0.0,
              'disc_type': appliedDiscount?.discountTypeId,
              'disc_fixed_amt': 0.0,
              'disc_percent': 0.0,
              'is_disc_exempt': isDiscExempt ? 1 : 0,
              'vat_sales': 0.0,
              'vat_amount': 0.0,
              'non_vat': 0.0,
              'vat_exempt_sales': 0.0,
              'vat_private': 0.0,
              'zero_rated': 0.0,
              'item_type': itemTypeCode,
              'order_type_id': order.orderTypeId,
              'box_barcode': cartItem.item.itemCode,
              'tax_code': isVatExemptItem ? 2 : 1,
              'customization_key': customizationKey,
              'customization_seq': custSeq,
            });
          }
        }

        // Insert COGS (`sales_m3` -> `cogs_line`) & Deduct Stock Quantity
        if (cartItem.item.id != null) {
          final compRows = await txn.rawQuery(
            '''
            SELECT c.component_item_id, c.quantity AS comp_qty, i.cost_price AS comp_cost
            FROM ${SchemaConstants.composition} c
            LEFT JOIN ${SchemaConstants.item} i ON c.component_item_id = i.id
            WHERE c.finished_item_id = ?
            ''',
            [cartItem.item.id],
          );

          if (compRows.isNotEmpty) {
            for (final comp in compRows) {
              final compItemId = comp['component_item_id'] as int;
              final compQty =
                  (comp['comp_qty'] as num? ?? 1.0).toDouble() *
                  cartItem.quantity;
              final compCost = (comp['comp_cost'] as num? ?? 0.0).toDouble();
              await txn.insert(SchemaConstants.cogsLine, {
                'sale_transaction_id': txnId,
                'tseq_no': nextTseqNumber,
                'parent_item_id': cartItem.item.id,
                'component_item_id': compItemId,
                'quantity': compQty,
                'cost_price': compCost,
                'amount': compQty * compCost,
                'cashier_id': order.cashierId,
                'z_number': 0,
                'status': 1,
                'transaction_date': now,
                'created_at': now,
                'posted_at': postingDate,
              });

              await txn.rawUpdate(
                '''
                UPDATE ${SchemaConstants.stock}
                SET quantity = quantity - ?,
                    updated_at = ?
                WHERE item_id = ?
                ''',
                [compQty, now, compItemId],
              );
            }
          } else {
            final itemQty = cartItem.quantity.toDouble();
            final itemCost = cartItem.item.costPrice;
            await txn.insert(SchemaConstants.cogsLine, {
              'sale_transaction_id': txnId,
              'tseq_no': nextTseqNumber,
              'parent_item_id': cartItem.item.id,
              'component_item_id': cartItem.item.id,
              'quantity': itemQty,
              'cost_price': itemCost,
              'amount': itemQty * itemCost,
              'cashier_id': order.cashierId,
              'z_number': 0,
              'status': 1,
              'transaction_date': now,
              'created_at': now,
              'posted_at': postingDate,
            });
          }

          // Also deduct the parent item's direct stock row if present
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

      // 6. Build Effective Payment Legs (Single Tender or Multi-Tender Split Payment)
      List<TenderPaymentLeg> effectiveLegs = [];
      if (payments != null && payments.isNotEmpty) {
        effectiveLegs = payments;
      } else {
        // Resolve payment method code & name from DB
        String methodCode = 'cash';
        String methodName = 'Cash';
        final pmRows = await txn.query(
          SchemaConstants.paymentMethod,
          where: 'id = ?',
          whereArgs: [paymentMethodId],
          limit: 1,
        );
        if (pmRows.isNotEmpty) {
          methodCode = (pmRows.first['code'] as String? ?? 'cash').toLowerCase();
          methodName = pmRows.first['name'] as String? ?? 'Cash';
        }
        effectiveLegs = [
          TenderPaymentLeg(
            paymentMethodId: paymentMethodId,
            paymentMethodCode: methodCode,
            paymentMethodName: methodName,
            amount: breakdown.netTotal,
            cashTendered: cashTendered,
            changeGiven: changeGiven,
            cashlessAmount: methodCode == 'cash' ? null : cashTendered,
            bankId: bankId,
            referenceNumber: referenceNumber,
            chargeAccountId: chargeAccountId,
          ),
        ];
      }

      // Insert Payment Record(s) with Pro-Rated VAT/Gross and Full Tender Metadata
      for (final leg in effectiveLegs) {
        final double ratio = breakdown.netTotal > 0
            ? (leg.amount / breakdown.netTotal).clamp(0.0, 1.0)
            : 1.0;

        String? effectiveRefNo =
            (leg.referenceNumber != null &&
                leg.referenceNumber!.trim().isNotEmpty)
            ? leg.referenceNumber!.trim()
            : null;
        if (leg.chargeAccountId != null) {
          final chargeMaps = await txn.query(
            SchemaConstants.chargePayment,
            columns: ['name', 'code'],
            where: 'id = ?',
            whereArgs: [leg.chargeAccountId],
            limit: 1,
          );
          if (chargeMaps.isNotEmpty) {
            final chargeName = chargeMaps.first['name'] as String;
            effectiveRefNo = effectiveRefNo != null
                ? '$chargeName ($effectiveRefNo)'
                : 'Charge: $chargeName';
          }
        }

        await txn.insert(SchemaConstants.payment, {
          'sale_transaction_id': txnId,
          'cashier_id': order.cashierId,
          'payment_method_id': leg.paymentMethodId,
          'amount': leg.amount,
          'gross_price': breakdown.grossSubtotal * ratio,
          'gross_amount': breakdown.grossSubtotal * ratio,
          'vat_sales': breakdown.vatableSales * ratio,
          'vat_amount': breakdown.vatAmount * ratio,
          'non_vat': breakdown.nonVatSales * ratio,
          'vat_exempt': breakdown.vatExemptSales * ratio,
          'vat_private': totalVatPrivate * ratio,
          'zero_rated': breakdown.zeroRatedSales * ratio,
          'cash_tendered': leg.cashTendered,
          'change_given': leg.changeGiven,
          'bank_id': leg.bankId,
          'card_number': leg.cardNumber,
          'card_expiry': leg.cardExpiry,
          'approval_number': leg.approvalNumber,
          'reference_number': effectiveRefNo,
          'merchant_terminal': leg.merchantTerminal,
          'payment_channel': leg.paymentChannel,
          'card_type': leg.cardType,
          'cashless_amount': leg.cashlessAmount,
          'excess_amount': leg.excessAmount,
          'gift_check_id': leg.giftCheckId,
          'gift_check_qty': leg.giftCheckQty,
          'serial_numbers': leg.serialNumbers,
          'charge_account_id': leg.chargeAccountId,
          'x_read_status': 0,
          'z_number': 0,
          'status': 1,
          'transaction_date': now,
          'created_at': now,
          'posted_at': postingDate,
        });

        // If Gift Check serials were redeemed, mark them redeemed in gift_check_serial
        if (leg.giftCheckId != null &&
            leg.serialNumbers != null &&
            leg.serialNumbers!.trim().isNotEmpty) {
          final serialList = leg.serialNumbers!
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          for (final serial in serialList) {
            final updated = await txn.update(
              SchemaConstants.giftCheckSerial,
              {
                'status': 2, // 2 = Redeemed
                'redeemed_by': 'Cashier #${order.cashierId}',
                'redeemed_at': now,
                'redeeming_transaction_id': txnId,
              },
              where: 'serial_number = ?',
              whereArgs: [serial],
            );
            if (updated == 0) {
              await txn.insert(SchemaConstants.giftCheckSerial, {
                'gift_check_id': leg.giftCheckId,
                'serial_number': serial,
                'status': 2,
                'redeemed_by': 'Cashier #${order.cashierId}',
                'redeemed_at': now,
                'redeeming_transaction_id': txnId,
                'created_at': now,
              });
            }
          }
        }

        // If customer details were captured on this tender leg, persist to customer table
        if (leg.customerName != null && leg.customerName!.trim().isNotEmpty) {
          await txn.insert(SchemaConstants.customer, {
            'tseq_no': nextTseqNumber,
            'omt_ref_no': effectiveRefNo,
            'name': leg.customerName!.trim(),
            'address': leg.customerAddress,
            'tin_number': leg.customerTin,
            'created_at': now,
            'updated_at': now,
          });
        }
      }

      // 7. Insert Statutory Discount Beneficiary if recorded
      if (order.beneficiaryName != null && order.beneficiaryName!.isNotEmpty) {
        final discTypeId =
            order.beneficiaryDiscountTypeId ??
            (appliedDiscount?.discountTypeId ?? 2);
        await txn.insert(SchemaConstants.discountBeneficiary, {
          'sale_transaction_id': txnId,
          'tseq_no': nextTseqNumber,
          'discount_type_id': discTypeId,
          'beneficiary_name': order.beneficiaryName ?? 'N/A',
          'id_number': order.beneficiaryIdNo,
          'status': 1,
          'created_at': now,
        });
      }

      // Finish EJ Text Buffer
      ejBuffer.writeln('----------------------------------------');
      ejBuffer.writeln('FINANCIAL SUMMARY:');
      ejBuffer.writeln(
        '  Gross Subtotal : ₱${breakdown.grossSubtotal.toStringAsFixed(2)}',
      );
      if (breakdown.itemDiscountAmount > 0) {
        ejBuffer.writeln(
          '  Item Discounts : -₱${breakdown.itemDiscountAmount.toStringAsFixed(2)}',
        );
      }
      ejBuffer.writeln(
        '  Order Discount : -₱${breakdown.manualDiscountAmount.toStringAsFixed(2)}',
      );
      if (appliedDiscount != null) {
        ejBuffer.writeln('  Discount Name  : ${appliedDiscount.name}');
      }
      if (order.beneficiaryName != null && order.beneficiaryName!.isNotEmpty) {
        ejBuffer.writeln(
          '  Beneficiary    : ${order.beneficiaryName} (ID: ${order.beneficiaryIdNo ?? "N/A"})',
        );
      }
      if (breakdown.surchargeAmount > 0) {
        ejBuffer.writeln(
          '  Surcharge      : +₱${breakdown.surchargeAmount.toStringAsFixed(2)}',
        );
      }
      ejBuffer.writeln(
        '  VATable Sales  : ₱${breakdown.vatableSales.toStringAsFixed(2)}',
      );
      ejBuffer.writeln(
        '  VAT Amount 12% : ₱${breakdown.vatAmount.toStringAsFixed(2)}',
      );
      ejBuffer.writeln(
        '  VAT Exempt     : ₱${breakdown.vatExemptSales.toStringAsFixed(2)}',
      );
      if (totalVatPrivate > 0) {
        ejBuffer.writeln(
          '  Less 12% VAT   : -₱${totalVatPrivate.toStringAsFixed(2)}',
        );
      }
      ejBuffer.writeln(
        '  NET TOTAL DUE  : ₱${breakdown.netTotal.toStringAsFixed(2)}',
      );
      ejBuffer.writeln('TENDER BREAKDOWN (${effectiveLegs.length} leg(s)):');
      for (final leg in effectiveLegs) {
        ejBuffer.writeln(
          '  - ${leg.paymentMethodName}: Applied ₱${leg.amount.toStringAsFixed(2)} | Tendered ₱${leg.cashTendered.toStringAsFixed(2)} | Change ₱${leg.changeGiven.toStringAsFixed(2)}${leg.excessAmount > 0 ? " | Excess ₱${leg.excessAmount.toStringAsFixed(2)}" : ""}',
        );
      }
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

  /// Looks up a transaction header by its official Sales Invoice (`si_number`) or `id`.
  Future<Map<String, dynamic>?> getTransactionBySiNumber(int siNumber) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        st.id AS transaction_id,
        st.sales_order_id,
        st.si_number,
        st.tseq_no,
        st.z_number,
        st.x_read_status,
        st.is_voided,
        st.status,
        st.gross_amount,
        st.net_amount,
        st.guest_count,
        st.eligible_guest_count,
        st.discount_amount AS order_discount_amount,
        st.item_discount_amount,
        st.surcharge_amount,
        st.vat_sales AS vatable_sales,
        st.vat_amount,
        st.vat_exempt AS vat_exempt_sales,
        st.vat_zero_rated AS zero_rated_sales,
        st.transaction_date,
        u.name AS cashier_name,
        ot.name AS order_type_name,
        COALESCE((SELECT SUM(p.cash_tendered) FROM ${SchemaConstants.payment} p WHERE p.sale_transaction_id = st.id), 0.0) AS cash_tendered,
        COALESCE((SELECT SUM(p.change_given) FROM ${SchemaConstants.payment} p WHERE p.sale_transaction_id = st.id), 0.0) AS change_given,
        (SELECT p.reference_number FROM ${SchemaConstants.payment} p WHERE p.sale_transaction_id = st.id LIMIT 1) AS reference_number,
        (SELECT b.name FROM ${SchemaConstants.payment} p LEFT JOIN ${SchemaConstants.bank} b ON p.bank_id = b.id WHERE p.sale_transaction_id = st.id LIMIT 1) AS bank_name,
        (SELECT GROUP_CONCAT(pm.name, ' + ') FROM ${SchemaConstants.payment} p JOIN ${SchemaConstants.paymentMethod} pm ON p.payment_method_id = pm.id WHERE p.sale_transaction_id = st.id) AS payment_method_name,
        d.name AS discount_name,
        dben.beneficiary_name,
        dben.id_number AS beneficiary_id_no
      FROM ${SchemaConstants.saleTransaction} st
      LEFT JOIN ${SchemaConstants.appUser} u ON st.cashier_id = u.id
      LEFT JOIN ${SchemaConstants.orderType} ot ON st.order_type_id = ot.id
      LEFT JOIN ${SchemaConstants.discount} d ON st.discount_id = d.id
      LEFT JOIN ${SchemaConstants.discountBeneficiary} dben ON dben.sale_transaction_id = st.id
      WHERE st.si_number = ? OR st.id = ?
      ORDER BY CASE WHEN st.si_number = ? THEN 0 ELSE 1 END
      LIMIT 1
      ''',
      [siNumber, siNumber, siNumber],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Returns active void reasons from `void_reason` (seeding defaults if empty).
  Future<List<Map<String, dynamic>>> getActiveVoidReasons() async {
    final db = await _databaseHelper.database;
    var rows = await db.query(
      SchemaConstants.voidReason,
      where: 'is_active = 1',
      orderBy: 'id ASC',
    );
    if (rows.isEmpty) {
      final defaults = [
        'Customer Changed Mind',
        'Wrong Item Punched',
        'Wrong Tender / Payment Mode',
        'Wrong Discount Applied',
        'Duplicate Transaction',
      ];
      for (final reason in defaults) {
        await db.insert(SchemaConstants.voidReason, {
          'reason': reason,
          'is_active': 1,
        });
      }
      rows = await db.query(
        SchemaConstants.voidReason,
        where: 'is_active = 1',
        orderBy: 'id ASC',
      );
    }
    return rows;
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
        st.si_number,
        st.tseq_no,
        st.z_number,
        st.x_read_status,
        st.is_voided,
        st.gross_amount,
        st.net_amount,
        st.guest_count,
        st.eligible_guest_count,
        st.discount_amount AS order_discount_amount,
        st.item_discount_amount,
        st.surcharge_amount,
        st.vat_sales AS vatable_sales,
        st.vat_amount,
        st.vat_exempt AS vat_exempt_sales,
        st.vat_zero_rated AS zero_rated_sales,
        st.transaction_date,
        st.status,
        u.name AS cashier_name,
        ot.name AS order_type_name,
        COALESCE((SELECT SUM(p.cash_tendered) FROM ${SchemaConstants.payment} p WHERE p.sale_transaction_id = st.id), 0.0) AS cash_tendered,
        COALESCE((SELECT SUM(p.change_given) FROM ${SchemaConstants.payment} p WHERE p.sale_transaction_id = st.id), 0.0) AS change_given,
        (SELECT p.reference_number FROM ${SchemaConstants.payment} p WHERE p.sale_transaction_id = st.id LIMIT 1) AS reference_number,
        (SELECT b.name FROM ${SchemaConstants.payment} p LEFT JOIN ${SchemaConstants.bank} b ON p.bank_id = b.id WHERE p.sale_transaction_id = st.id LIMIT 1) AS bank_name,
        (SELECT GROUP_CONCAT(pm.name, ' + ') FROM ${SchemaConstants.payment} p JOIN ${SchemaConstants.paymentMethod} pm ON p.payment_method_id = pm.id WHERE p.sale_transaction_id = st.id) AS payment_method_name,
        d.name AS discount_name,
        dben.beneficiary_name,
        dben.id_number AS beneficiary_id_no
      FROM ${SchemaConstants.saleTransaction} st
      LEFT JOIN ${SchemaConstants.appUser} u ON st.cashier_id = u.id
      LEFT JOIN ${SchemaConstants.orderType} ot ON st.order_type_id = ot.id
      LEFT JOIN ${SchemaConstants.discount} d ON st.discount_id = d.id
      LEFT JOIN ${SchemaConstants.discountBeneficiary} dben ON dben.sale_transaction_id = st.id
      ORDER BY st.transaction_date DESC, st.id DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionLineDetails(
    int transactionId,
  ) async {
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
        tl.customization_seq,
        soi.id AS sales_order_item_id
      FROM ${SchemaConstants.transactionLine} tl
      LEFT JOIN ${SchemaConstants.saleTransaction} st ON tl.sale_transaction_id = st.id
      LEFT JOIN ${SchemaConstants.salesOrderItem} soi ON soi.sales_order_id = st.sales_order_id AND soi.item_id = tl.item_id
      WHERE tl.sale_transaction_id = ?
        AND (tl.customization_seq IS NULL OR tl.customization_seq = 1)
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

  /// Post-Voids a transaction while enforcing KwikPOS Lite `post_void_guard_helper` rules:
  /// - Blocks if already voided (`is_voided == 1` or `status == 2`)
  /// - Blocks if already included in an X-Reading (`x_read_status == 1`)
  /// - Blocks if already included in a Z-Reading (`z_number > 0`)
  /// - Optionally verifies `expectedAmountDue` when called from the Sales Entry SI# Post-Void dialog
  /// - Increments `counter_table.tseq_no` and `counter_table.post_void_count`
  /// - Inserts audit rows into `void_transaction`
  /// - Marks `sale_transaction`, `sales_order`, `payment`, `cogs_line`, `discount_beneficiary` as voided (`status = 2`)
  /// - Restores stock quantities
  Future<void> voidOrderTransaction({
    required int transactionId,
    required int cashierId,
    required String reason,
    int? voidReasonId,
    int? authorizedById,
    double? expectedAmountDue,
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
      final isVoided = (txnData['is_voided'] as num? ?? 0).toInt() == 1 ||
          (txnData['status'] as num? ?? 1).toInt() == 2;
      if (isVoided) {
        throw Exception('Transaction is already voided.');
      }

      final xReadStatus = (txnData['x_read_status'] as num? ?? 0).toInt();
      if (xReadStatus == 1) {
        throw Exception(
          'Cannot post-void a transaction that has already been included in an X-Reading.',
        );
      }

      final zNumber = (txnData['z_number'] as num? ?? 0).toInt();
      if (zNumber > 0) {
        throw Exception(
          'Cannot post-void a transaction that has already been closed in a Z-Reading.',
        );
      }

      final netAmount = (txnData['net_amount'] as num? ?? 0.0).toDouble();
      if (expectedAmountDue != null &&
          (netAmount - expectedAmountDue).abs() > 0.05) {
        throw Exception(
          'Amount Due mismatch. Expected ₱${netAmount.toStringAsFixed(2)} for this Sales Invoice.',
        );
      }

      final salesOrderId = txnData['sales_order_id'] as int?;
      final originalTseqNo = (txnData['tseq_no'] as num? ?? 0).toInt();
      final now = DateTime.now().toIso8601String();

      // Increment counter_table tseq_no and post_void_count
      final counter = await _ensureCounterRow(txn);
      final newTseqNo = (counter['tseq_no'] as num).toInt() + 1;
      final newPostVoidCount =
          (counter['post_void_count'] as num? ?? 0).toInt() + 1;
      await txn.update(
        SchemaConstants.counterTable,
        {
          'tseq_no': newTseqNo,
          'post_void_count': newPostVoidCount,
          'last_updated': now,
        },
        where: 'id = 1',
      );

      // 1. Mark Transaction, Order, Payment, COGS, and Discount Beneficiary as Voided (status = 2)
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

      if (salesOrderId != null) {
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
      }

      await txn.update(
        SchemaConstants.payment,
        {
          'status': 2,
          'posted_at': now,
        },
        where: 'sale_transaction_id = ?',
        whereArgs: [transactionId],
      );

      await txn.update(
        SchemaConstants.cogsLine,
        {
          'status': 2,
          'posted_at': now,
        },
        where: 'sale_transaction_id = ?',
        whereArgs: [transactionId],
      );

      await txn.update(
        SchemaConstants.discountBeneficiary,
        {'status': 2},
        where: 'sale_transaction_id = ?',
        whereArgs: [transactionId],
      );

      // 2. Fetch lines using standardized sale_transaction_id
      final lineItems = await txn.query(
        SchemaConstants.transactionLine,
        where:
            'sale_transaction_id = ? AND (customization_seq IS NULL OR customization_seq = 1)',
        whereArgs: [transactionId],
      );

      // 3. Insert into void_transaction & Restore Stock
      for (final line in lineItems) {
        final itemId = line['item_id'] as int?;
        final qtySold = (line['quantity'] as num).toDouble();
        final unitPrice = (line['unit_price'] as num? ?? 0.0).toDouble();

        await txn.insert(SchemaConstants.voidTransaction, {
          'original_transaction_id': transactionId,
          'original_tseq_no': originalTseqNo,
          'new_tseq_no': newTseqNo,
          'item_id': itemId,
          'item_barcode': line['barcode'] as String?,
          'item_name': line['item_name'] as String?,
          'price': unitPrice,
          'quantity': qtySold,
          'void_reason_id': voidReasonId,
          'cashier_id': cashierId,
          'authorized_by_id': authorizedById ?? cashierId,
          'z_number': 0,
          'x_read_status': 0,
          'transaction_date': now,
          'created_at': now,
        });

        if (itemId != null && qtySold > 0) {
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

      // Restore recipe/composition component stock from cogs_line where component_item_id != parent_item_id
      final cogsComponents = await txn.query(
        SchemaConstants.cogsLine,
        where: 'sale_transaction_id = ? AND component_item_id != parent_item_id',
        whereArgs: [transactionId],
      );
      for (final comp in cogsComponents) {
        final compItemId = comp['component_item_id'] as int?;
        final compQty = (comp['quantity'] as num? ?? 0.0).toDouble();
        if (compItemId != null && compQty > 0) {
          await txn.rawUpdate(
            '''
            UPDATE ${SchemaConstants.stock}
            SET quantity = quantity + ?,
                remarks = ?,
                updated_at = ?
            WHERE item_id = ?
            ''',
            [compQty, 'RESTORED COGS: Void Txn #$transactionId', now, compItemId],
          );
        }
      }

      // 4. Log to Electronic Journal
      final ejContent =
          '''
========================================
*** POST-VOID TRANSACTION AUDIT LOG ***
Txn ID: $transactionId | Orig TSEQ: $originalTseqNo | Void TSEQ: $newTseqNo
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
        'activity_type': 'POST_VOID',
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

    final totalSales =
        (salesRes.isNotEmpty ? salesRes.first['total_sales'] as num? : 0.0)
            ?.toDouble() ??
        0.0;
    final completedCount =
        (salesRes.isNotEmpty
            ? (salesRes.first['completed_count'] as num?)?.toInt()
            : 0) ??
        0;
    final activeCount =
        (activeRes.isNotEmpty
            ? (activeRes.first['active_count'] as num?)?.toInt()
            : 0) ??
        0;
    final totalOrdersToday =
        (ordersRes.isNotEmpty
            ? (ordersRes.first['total_orders_today'] as num?)?.toInt()
            : 0) ??
        0;

    return {
      'total_sales': totalSales,
      'completed_count': completedCount,
      'active_count': activeCount,
      'total_orders_today': totalOrdersToday,
    };
  }

  /// Retrieves list of sales orders with table names, cashier, and order types.
  Future<List<Map<String, dynamic>>> getSalesOrders({
    int? paymentStatus,
    int limit = 50,
  }) async {
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
