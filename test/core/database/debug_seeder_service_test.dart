import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/debug_seeder_service.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/data/dao/shift_dao.dart';

void main() {
  late DatabaseHelper dbHelper;
  late Database db;
  late DebugSeederService seeder;
  late ShiftDao shiftDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper();
    db = await dbHelper.initInMemoryTestDatabase();
    seeder = DebugSeederService(dbHelper);
    shiftDao = ShiftDao(dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  test('seedIfCatalogEmpty seeds full POS catalog, stocks, discounts, modifiers, compositions, and gift check serials', () async {
    final seededFirstTime = await seeder.seedIfCatalogEmpty();
    expect(seededFirstTime, isTrue);

    // Calling seedIfCatalogEmpty again when items exist should be a no-op
    final seededSecondTime = await seeder.seedIfCatalogEmpty();
    expect(seededSecondTime, isFalse);

    // Verify counts across master tables
    final depts = await db.query(SchemaConstants.department);
    final cats = await db.query(SchemaConstants.category);
    final items = await db.query(SchemaConstants.item);
    final prices = await db.query(SchemaConstants.itemPrice);
    final stocks = await db.query(SchemaConstants.stock);
    final discounts = await db.query(SchemaConstants.discount);
    final compositions = await db.query(SchemaConstants.composition);
    final optionGroups = await db.query(SchemaConstants.optionGroup);
    final optionValues = await db.query(SchemaConstants.optionValue);
    final gcSerials = await db.query(SchemaConstants.giftCheckSerial);
    final users = await db.query(SchemaConstants.appUser);

    expect(depts.length, 5);
    expect(cats.length, 8);
    expect(items.length, 15);
    expect(prices.length, 15);
    expect(stocks.length, 15);
    expect(discounts.length, 6);
    expect(compositions.length, 6);
    expect(optionGroups.length, 2);
    expect(optionValues.length, 7);
    expect(gcSerials.length, 8);
    expect(users.length, 3); // Superuser + Cashier Juan + Cashier Maria
  });

  test('resetTransactionsAndReseed clears shifts/deposits/counters and restores fresh stock & GC serials', () async {
    await seeder.seedDemoCatalog();

    // Open a shift and redeem a Gift Check serial
    final shiftId = await shiftDao.openShift(2, 2500);
    expect(shiftId, greaterThan(0));
    await db.update(
      SchemaConstants.giftCheckSerial,
      {'status': 2},
      where: 'serial_number = ?',
      whereArgs: ['GC-500-001'],
    );
    await db.update(
      SchemaConstants.stock,
      {'quantity': 1.0},
      where: 'item_id = 1',
    );

    // Execute resetTransactionsAndReseed
    final summary = await seeder.resetTransactionsAndReseed();
    expect(summary.transactionsCleared, isTrue);

    // Verify shift and deposit were cleared and counter_table reset to 0
    final shifts = await db.query(SchemaConstants.shift);
    final deposits = await db.query(SchemaConstants.deposit);
    final counters = await db.query(SchemaConstants.counterTable, where: 'id = 1');
    expect(shifts, isEmpty);
    expect(deposits, isEmpty);
    expect(counters.first['tseq_no'], 0);
    expect(counters.first['si_number'], 0);
    expect(counters.first['z_read_count'], 0);

    // Verify GC-500-001 is restored to status = 1 (Available) and Item #1 stock restored to 60.0
    final gcRow = await db.query(
      SchemaConstants.giftCheckSerial,
      where: 'serial_number = ?',
      whereArgs: ['GC-500-001'],
    );
    expect(gcRow.first['status'], 1);

    final stockRow = await db.query(
      SchemaConstants.stock,
      where: 'item_id = 1',
    );
    expect(stockRow.first['quantity'], 60.0);
  });

  test('seedSampleShiftAndTransactions creates SI #1..#5 and matches exact QA playbook X-Reading totals', () async {
    await seeder.seedSampleShiftAndTransactions(cashierId: 2);

    final xData = await shiftDao.getXReadingReportData(2);
    expect(xData['beginningCash'], closeTo(2000.0, 0.01));
    expect(xData['cashSales'], closeTo(668.0, 0.01)); // 448 (SI#1) + 220 (SI#4 leg)
    expect(xData['cardAmount'], closeTo(384.0, 0.01)); // SI#2
    expect(xData['atmAmount'], closeTo(566.50, 0.01)); // SI#3
    expect(xData['giftCheckAmount'], closeTo(400.0, 0.01)); // SI#4 leg
    expect(xData['totalExcess'], closeTo(100.0, 0.01)); // SI#4 GC excess
    expect(xData['cashIn'], closeTo(300.0, 0.01));
    expect(xData['cashOut'], closeTo(100.0, 0.01));
    expect(xData['expectedCash'], closeTo(2868.0, 0.01));
    expect(xData['netSales'], closeTo(2018.50, 0.01));
    expect(xData['postVoidAmount'], closeTo(220.0, 0.01));
    expect(xData['postVoidCount'], 1);
    expect(xData['totalDiscounts'], closeTo(90.50, 0.01)); // 40.00 SC + 50.50 VIP
  });
}
