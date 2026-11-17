import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/data/dao/order_dao.dart';
import 'package:suki_pos/data/dao/shift_dao.dart';
import 'package:suki_pos/data/models/maintenance/item_price_model.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/option_value.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/sales_order.dart';
import 'package:suki_pos/domain/entities/pos/tender_payment_leg.dart';
import 'package:suki_pos/domain/entities/shift/cash_denomination_count.dart';

void main() {
  late DatabaseHelper dbHelper;
  late Database db;
  late OrderDao orderDao;
  late ShiftDao shiftDao;
  late int cashierId;
  late int itemId;
  late int rawNoodleId;
  late int giftCheckId;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper();
    db = await dbHelper.initInMemoryTestDatabase();
    orderDao = OrderDao(dbHelper);
    shiftDao = ShiftDao(dbHelper);

    // Seed a test cashier, department, category, finished item, raw component, and composition
    cashierId = await db.insert('app_user', {
      'role_id': 2,
      'name': 'Juan Dela Cruz',
      'password_hash': 'hash',
      'is_active': 1,
    });

    final deptId = await db.insert('department', {
      'code': 'D01',
      'name': 'Food',
      'is_active': 1,
    });

    final catId = await db.insert('category', {
      'code': 'C01',
      'name': 'Ramen',
      'department_id': deptId,
      'is_active': 1,
    });

    itemId = await db.insert('item', {
      'item_code': 'ITM-RAMEN',
      'barcode': '480001',
      'name': 'Tonkotsu Ramen',
      'print_name': 'Tonkotsu Ramen',
      'category_id': catId,
      'department_id': deptId,
      'cost_price': 65.0,
      'is_vat_exempt': 0,
      'is_discount_exempt': 0,
      'is_composition': 1,
      'is_active': 1,
    });

    await db.insert('item_price', {
      'item_id': itemId,
      'price_level': 'default',
      'price': 224.0,
    });

    rawNoodleId = await db.insert('item', {
      'item_code': 'RAW-NOODLE',
      'barcode': '480002',
      'name': 'Ramen Noodle Pack',
      'print_name': 'Ramen Noodle Pack',
      'category_id': catId,
      'department_id': deptId,
      'cost_price': 30.0,
      'is_raw_material': 1,
      'is_active': 1,
    });

    await db.insert('stock', {
      'item_id': itemId,
      'quantity': 50.0,
    });
    await db.insert('stock', {
      'item_id': rawNoodleId,
      'quantity': 100.0,
    });

    // Recipe composition (1 Tonkotsu Ramen uses 2 units of Ramen Noodle Pack)
    await db.insert('composition', {
      'finished_item_id': itemId,
      'component_item_id': rawNoodleId,
      'quantity': 2.0,
    });

    // Seed option_group (id=1) and option_value (id=10) for modifier foreign keys
    await db.insert('option_group', {
      'id': 1,
      'name': 'Add-ons',
    });
    await db.insert('option_value', {
      'id': 10,
      'option_group_id': 1,
      'alias': 'Ajitama Egg',
      'price_delta': 56.0,
    });

    // Gift Check master + serials
    giftCheckId = await db.insert('gift_check', {
      'code': 500,
      'name': 'P500 Gift Certificate',
      'amount': 500.0,
      'is_active': 1,
    });
    await db.insert('gift_check_serial', {
      'gift_check_id': giftCheckId,
      'serial_number': 'GC-SER-001',
      'status': 1,
    });
  });

  tearDown(() async {
    await dbHelper.close();
  });

  Item buildRamenItem() {
    return Item(
      id: itemId,
      itemCode: 'ITM-RAMEN',
      barcode: '480001',
      name: 'Tonkotsu Ramen',
      printName: 'Tonkotsu Ramen',
      categoryId: 1,
      departmentId: 1,
      costPrice: 65,
      isComposition: true,
      prices: [
        ItemPriceModel(id: 1, priceLevel: 'default', price: 224),
      ],
    );
  }

  test('Full KwikPOS Lite Sales Entry -> Multi-Tender Saving -> X-Read -> Z-Read lifecycle', () async {
    // 1. Pre-flight guard checks before opening shift
    expect(await shiftDao.isZReadingDoneForToday(), isFalse);
    expect(await shiftDao.getMissingZReadingDate(), isNull);
    expect(await shiftDao.getPendingCashierInfo(cashierId), isNull);

    // 2. Open shift with Opening Change Fund (₱2,000.00)
    final shiftId = await shiftDao.openShift(cashierId, 2000);
    expect(shiftId, greaterThan(0));

    final deposits = await db.query('deposit');
    expect(deposits.length, 1);
    expect(deposits.first['deposit_amount'], 2000.0);
    expect(deposits.first['x_read_status'], 0);
    expect(deposits.first['z_number'], 0);

    // Before any sales, Tender Declaration should be blocked due to no transactions
    expect(
      await shiftDao.shouldBlockTenderDeclarationDueToNoTransactions(cashierId),
      isTrue,
    );

    // 3. Checkout Order #1: Cash + Modifier + Composition COGS (sales_m2 & sales_m3)
    final ramen = buildRamenItem();
    const extraEggOption = OptionValue(
      id: 10,
      optionGroupId: 1,
      alias: 'Ajitama Egg',
      priceDelta: 56,
    );
    final cart1 = [
      CartItem(
        id: 'line-1',
        item: ramen,
        quantity: 2,
        selectedOptions: const [extraEggOption],
      ),
    ];
    final order1 = SalesOrderAggregate(
      orderTypeId: 2, // Take-Out (no service charge)
      cashierId: cashierId,
      items: cart1,
      createdAt: DateTime.now(),
    );

    // Unit price = 224 + 56 = 280; qty 2 = 560.00 (500 VATable + 60 VAT)
    final txnId1 = await orderDao.checkoutOrderTransaction(
      order: order1,
      paymentMethodId: 1, // Cash
      cashTendered: 600,
      changeGiven: 40,
      payments: const [
        TenderPaymentLeg(
          paymentMethodId: 1,
          paymentMethodCode: 'cash',
          paymentMethodName: 'Cash',
          amount: 560,
          cashTendered: 600,
          changeGiven: 40,
          customerName: 'Maria Santos',
          customerTin: '123-456-789',
        ),
      ],
    );
    expect(txnId1, greaterThan(0));

    // Verify transaction_line (sales_m2): parent line + modifier child line
    final txnLines1 = await db.query(
      'transaction_line',
      where: 'sale_transaction_id = ?',
      whereArgs: [txnId1],
      orderBy: 'customization_seq ASC',
    );
    expect(txnLines1.length, 2);
    expect(txnLines1[0]['customization_seq'], 1);
    expect(txnLines1[0]['category_name'], 'Ramen');
    expect(txnLines1[0]['department_name'], 'Food');
    expect(txnLines1[0]['gross_amount'], closeTo(560.0, 0.01));
    expect(txnLines1[1]['customization_seq'], 2);
    expect(txnLines1[1]['item_name'], contains('Ajitama Egg'));

    // Verify cogs_line (sales_m3): 2 bowls * 2 noodle packs = 4 units @ 30.0 = 120.0
    final cogs1 = await db.query('cogs_line');
    expect(cogs1.length, 1);
    expect(cogs1.first['component_item_id'], rawNoodleId);
    expect(cogs1.first['quantity'], 4.0);
    expect(cogs1.first['amount'], 120.0);

    // Verify component stock deducted (100 - 4 = 96)
    final rawStock = await db.query(
      'stock',
      where: 'item_id = ?',
      whereArgs: [rawNoodleId],
    );
    expect(rawStock.first['quantity'], 96.0);

    // Verify customer row saved
    final customers = await db.query('customer');
    expect(customers.length, 1);
    expect(customers.first['name'], 'Maria Santos');

    // 4. Checkout Order #2: Split Payment (Gift Check w/ Excess + Credit Card)
    final cart2 = [
      CartItem(id: 'line-2', item: ramen, quantity: 3), // 3 * 224 = 672.00
    ];
    final order2 = SalesOrderAggregate(
      orderTypeId: 2,
      cashierId: cashierId,
      items: cart2,
      createdAt: DateTime.now(),
    );

    // Customer uses P500 GC for P400 leg (P100 excess) + P272 Credit Card = P672
    final txnId2 = await orderDao.checkoutOrderTransaction(
      order: order2,
      paymentMethodId: 5, // Gift Check primary
      cashTendered: 772,
      changeGiven: 0,
      payments: [
        TenderPaymentLeg(
          paymentMethodId: 5,
          paymentMethodCode: 'gift_check',
          paymentMethodName: 'Gift Check',
          amount: 400,
          cashTendered: 500,
          excessAmount: 100,
          cashlessAmount: 500,
          giftCheckId: giftCheckId,
          giftCheckQty: 1,
          serialNumbers: 'GC-SER-001',
        ),
        const TenderPaymentLeg(
          paymentMethodId: 2,
          paymentMethodCode: 'card',
          paymentMethodName: 'Credit/Debit Card',
          amount: 272,
          cashTendered: 272,
          cashlessAmount: 272,
          cardType: 2,
          cardNumber: '4111',
          approvalNumber: 'APP-9988',
        ),
      ],
    );
    expect(txnId2, greaterThan(txnId1));

    // Verify gift_check_serial was marked redeemed (status = 2)
    final gcSerialRows = await db.query(
      'gift_check_serial',
      where: 'serial_number = ?',
      whereArgs: ['GC-SER-001'],
    );
    expect(gcSerialRows.first['status'], 2);

    // Verify pro-rated VAT on Split Payment rows (total VAT for 672.00 is 72.00)
    final splitPayments = await db.query(
      'payment',
      where: 'sale_transaction_id = ?',
      whereArgs: [txnId2],
      orderBy: 'id ASC',
    );
    expect(splitPayments.length, 2);
    final totalSplitVat = (splitPayments[0]['vat_amount'] as num).toDouble() +
        (splitPayments[1]['vat_amount'] as num).toDouble();
    expect(totalSplitVat, closeTo(72.0, 0.01));
    expect(splitPayments[0]['excess_amount'], 100.0);

    // 5. Cash Fund In (+₱500) and Cash Fund Out (-₱200)
    await shiftDao.insertCashFundLog(
      cashierId: cashierId,
      isCashIn: true,
      amount: 500,
      reason: 'Extra coins',
    );
    await shiftDao.insertCashFundLog(
      cashierId: cashierId,
      isCashIn: false,
      amount: 200,
      reason: 'Ice purchase',
    );

    // Expected Drawer Cash = 2000 (Opening) + 560 (Cash Sales) + 500 (Cash In) - 200 (Cash Out) = 2860.00
    final xPreviewBeforeDecl = await shiftDao.getXReadingReportData(cashierId);
    expect(xPreviewBeforeDecl['expectedCash'], closeTo(2860.0, 0.01));

    // 6. Save Tender Declaration (insert and update-in-place when x_read_status = 0)
    await shiftDao.saveCashDeclaration(
      cashierId: cashierId,
      totalCash: 2860,
      changeFund: 2000,
      denominations: const [
        CashDenominationCount(denomination: 1000, count: 2),
        CashDenominationCount(denomination: 500, count: 1),
        CashDenominationCount(denomination: 200, count: 1),
        CashDenominationCount(denomination: 100, count: 1),
        CashDenominationCount(denomination: 50, count: 1),
        CashDenominationCount(denomination: 10, count: 1),
      ],
    );
    expect(await shiftDao.hasTenderDeclarationForShift(cashierId), isTrue);

    // Update-in-place with +₱10 overage (2870.00)
    await shiftDao.saveCashDeclaration(
      cashierId: cashierId,
      totalCash: 2870,
      changeFund: 2000,
      denominations: const [
        CashDenominationCount(denomination: 1000, count: 2),
        CashDenominationCount(denomination: 500, count: 1),
        CashDenominationCount(denomination: 200, count: 1),
        CashDenominationCount(denomination: 100, count: 1),
        CashDenominationCount(denomination: 50, count: 1),
        CashDenominationCount(denomination: 20, count: 1),
      ],
    );
    final declRows = await db.query('cash_declaration');
    expect(declRows.length, 1); // Updated in place, not duplicated!
    expect(declRows.first['total_cash'], 2870.0);

    // 7. Execute X-Reading (closes shift, writes short_over, seals x_read_status = 1)
    await shiftDao.executeXReading(
      cashierId: cashierId,
      shiftId: shiftId,
    );

    final shortOverRows = await db.query('short_over');
    expect(shortOverRows.length, 1);
    expect(shortOverRows.first['short_over_amount'], closeTo(10.0, 0.01));

    // Verify Post-Void is now BLOCKED because x_read_status == 1
    await expectLater(
      orderDao.voidOrderTransaction(
        transactionId: txnId2,
        cashierId: cashierId,
        reason: 'Customer changed mind',
      ),
      throwsException,
    );

    // 8. Execute Z-Reading (writes daily_summary, increments z_read_count, seals z_number = 1)
    final zNumber = await shiftDao.executeZReading(cashierId: cashierId);
    expect(zNumber, 1);

    final dailySummaryRows = await db.query('daily_summary');
    expect(dailySummaryRows.length, 1);
    expect(dailySummaryRows.first['z_number'], 1);
    expect(dailySummaryRows.first['net_sales'], closeTo(560.0 + 672.0, 0.01));

    // Verify Z-Reading done for today guard is now true
    expect(await shiftDao.isZReadingDoneForToday(), isTrue);
  });

  test('Post-Void by SI# with expectedAmountDue verification, stock restoration, and 6-tender saving', () async {
    await shiftDao.openShift(cashierId, 1500);
    final ramen = buildRamenItem();

    // Checkout with ATM + Bank Check (with excess) + Charge Account
    final cart = [
      CartItem(id: 'line-1', item: ramen, quantity: 2), // 2 * 224 = 448.00
    ];
    final order = SalesOrderAggregate(
      orderTypeId: 2,
      cashierId: cashierId,
      items: cart,
      createdAt: DateTime.now(),
    );

    final txnId = await orderDao.checkoutOrderTransaction(
      order: order,
      paymentMethodId: 3, // ATM primary
      cashTendered: 500,
      changeGiven: 0,
      payments: const [
        TenderPaymentLeg(
          paymentMethodId: 3,
          paymentMethodCode: 'atm',
          paymentMethodName: 'ATM / Online Banking',
          amount: 148,
          cashTendered: 148,
          cashlessAmount: 148,
          paymentChannel: 'GCash',
          referenceNumber: 'GCASH-998877',
        ),
        TenderPaymentLeg(
          paymentMethodId: 4,
          paymentMethodCode: 'bank_check',
          paymentMethodName: 'Bank Check',
          amount: 200,
          cashTendered: 252,
          excessAmount: 52,
          cashlessAmount: 252,
          referenceNumber: 'CHK-001122',
        ),
        TenderPaymentLeg(
          paymentMethodId: 6,
          paymentMethodCode: 'charge',
          paymentMethodName: 'Charge Account',
          amount: 100,
          cashTendered: 100,
          cashlessAmount: 100,
          customerName: 'VIP Corporate Account',
          referenceNumber: 'PO-5544',
        ),
      ],
    );

    // Component stock was 100, minus 4 = 96
    var stockRow = await db.query('stock', where: 'item_id = ?', whereArgs: [rawNoodleId]);
    expect(stockRow.first['quantity'], 96.0);

    // Lookup by SI#1
    final siLookup = await orderDao.getTransactionBySiNumber(1);
    expect(siLookup, isNotNull);
    expect(siLookup!['transaction_id'], txnId);

    // Post-Void with wrong expectedAmountDue should throw
    await expectLater(
      orderDao.voidOrderTransaction(
        transactionId: txnId,
        cashierId: cashierId,
        reason: 'Wrong amount test',
        expectedAmountDue: 999,
      ),
      throwsException,
    );

    // Post-Void with exact expectedAmountDue (448.00) succeeds
    await orderDao.voidOrderTransaction(
      transactionId: txnId,
      cashierId: cashierId,
      reason: 'Customer cancelled order',
      expectedAmountDue: 448,
    );

    // Component stock restored back to 100.0
    stockRow = await db.query('stock', where: 'item_id = ?', whereArgs: [rawNoodleId]);
    expect(stockRow.first['quantity'], 100.0);

    // Verify void_transaction, payment, cogs_line, and counter_table.post_void_count
    final voidRows = await db.query('void_transaction');
    expect(voidRows.length, 1);

    final paymentRows = await db.query('payment', where: 'sale_transaction_id = ?', whereArgs: [txnId]);
    expect(paymentRows.length, 3);
    expect(paymentRows.every((p) => p['status'] == 2), isTrue);

    final cogsRows = await db.query('cogs_line', where: 'sale_transaction_id = ?', whereArgs: [txnId]);
    expect(cogsRows.every((c) => c['status'] == 2), isTrue);

    final counterRows = await db.query('counter_table', where: 'id = 1');
    expect(counterRows.first['post_void_count'], 1);
  });
}
