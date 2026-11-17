import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../domain/entities/shift/cash_denomination_count.dart';

class ShiftDao {
  final DatabaseHelper _databaseHelper;

  ShiftDao(this._databaseHelper);

  String _todayDateStr([DateTime? dt]) {
    final now = dt ?? DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Ensures `counter_table` (id = 1) exists and returns its current values.
  Future<Map<String, dynamic>> _ensureCounterRow(DatabaseExecutor db) async {
    final rows = await db.query(
      SchemaConstants.counterTable,
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.insert(SchemaConstants.counterTable, {
        'id': 1,
        'tseq_no': 0,
        'si_number': 0,
        'z_read_count': 0,
        'post_void_count': 0,
        'so_number': 1,
        'incoming_number': 1,
        'outgoing_number': 1,
        'deposit_number': 1,
        'trans_number': 0,
        'last_updated': now,
      });
      return {
        'id': 1,
        'tseq_no': 0,
        'si_number': 0,
        'z_read_count': 0,
        'post_void_count': 0,
        'deposit_number': 1,
        'trans_number': 0,
      };
    }
    return Map<String, dynamic>.from(rows.first);
  }

  Future<int> _incrementTseqNo(DatabaseExecutor db) async {
    final counter = await _ensureCounterRow(db);
    final nextTseq = (counter['tseq_no'] as num? ?? 0).toInt() + 1;
    await db.update(
      SchemaConstants.counterTable,
      {
        'tseq_no': nextTseq,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'id = 1',
    );
    return nextTseq;
  }

  // ===========================================================================
  // KWIKPOS LITE PRE-FLIGHT & READING VALIDATION HELPERS
  // ===========================================================================

  /// Checks if ANOTHER cashier (`cashier_id != currentCashierId`) has un-X-read
  /// transactions, change funds (`deposit`), tender declarations, or an open shift.
  /// Returns `{ 'cashierId': id, 'cashierName': name }` or `null`.
  Future<Map<String, dynamic>?> getPendingCashierInfo(
    int currentCashierId,
  ) async {
    final db = await _databaseHelper.database;

    // 1. Check open shift of another cashier
    final openShift = await db.rawQuery(
      '''
      SELECT s.cashier_id, COALESCE(u.name, 'Cashier #' || s.cashier_id) AS cashier_name
      FROM ${SchemaConstants.shift} s
      LEFT JOIN ${SchemaConstants.appUser} u ON s.cashier_id = u.id
      WHERE s.status = 1 AND s.cashier_id != ?
      LIMIT 1
      ''',
      [currentCashierId],
    );
    if (openShift.isNotEmpty) {
      return {
        'cashierId': openShift.first['cashier_id'] as int,
        'cashierName': openShift.first['cashier_name'] as String,
      };
    }

    // 2. Check un-X-read sale_transaction
    final unreadSales = await db.rawQuery(
      '''
      SELECT st.cashier_id, COALESCE(u.name, 'Cashier #' || st.cashier_id) AS cashier_name
      FROM ${SchemaConstants.saleTransaction} st
      LEFT JOIN ${SchemaConstants.appUser} u ON st.cashier_id = u.id
      WHERE st.x_read_status = 0 AND (st.z_number = 0 OR st.z_number IS NULL)
        AND st.cashier_id != ?
      LIMIT 1
      ''',
      [currentCashierId],
    );
    if (unreadSales.isNotEmpty) {
      return {
        'cashierId': unreadSales.first['cashier_id'] as int,
        'cashierName': unreadSales.first['cashier_name'] as String,
      };
    }

    // 3. Check un-X-read deposit (Change Fund)
    final unreadDeposit = await db.rawQuery(
      '''
      SELECT d.cashier_id, COALESCE(u.name, 'Cashier #' || d.cashier_id) AS cashier_name
      FROM ${SchemaConstants.deposit} d
      LEFT JOIN ${SchemaConstants.appUser} u ON d.cashier_id = u.id
      WHERE d.x_read_status = 0 AND (d.z_number = 0 OR d.z_number IS NULL)
        AND d.cashier_id != ?
      LIMIT 1
      ''',
      [currentCashierId],
    );
    if (unreadDeposit.isNotEmpty) {
      return {
        'cashierId': unreadDeposit.first['cashier_id'] as int,
        'cashierName': unreadDeposit.first['cashier_name'] as String,
      };
    }

    return null;
  }

  /// Checks if Z-Reading has already been executed for today's date (`daily_summary`).
  Future<bool> isZReadingDoneForToday() async {
    final db = await _databaseHelper.database;
    final todayStr = _todayDateStr();
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM ${SchemaConstants.dailySummary}
            WHERE SUBSTR(transaction_date, 1, 10) = ?
            ''',
            [todayStr],
          ),
        ) ??
        0;
    return count > 0;
  }

  /// Checks if any un-Z-read `sale_transaction` or `deposit` exists from a previous date (< today).
  /// Returns the earliest missing date string (`YYYY-MM-DD`) or `null`.
  Future<String?> getMissingZReadingDate() async {
    final db = await _databaseHelper.database;
    final todayStr = _todayDateStr();

    final txnDateRes = await db.rawQuery(
      '''
      SELECT SUBSTR(transaction_date, 1, 10) AS txn_date
      FROM ${SchemaConstants.saleTransaction}
      WHERE (z_number = 0 OR z_number IS NULL)
        AND SUBSTR(transaction_date, 1, 10) < ?
      ORDER BY transaction_date ASC
      LIMIT 1
      ''',
      [todayStr],
    );
    if (txnDateRes.isNotEmpty && txnDateRes.first['txn_date'] != null) {
      return txnDateRes.first['txn_date'] as String;
    }

    final depDateRes = await db.rawQuery(
      '''
      SELECT SUBSTR(transaction_date, 1, 10) AS dep_date
      FROM ${SchemaConstants.deposit}
      WHERE (z_number = 0 OR z_number IS NULL)
        AND SUBSTR(transaction_date, 1, 10) < ?
      ORDER BY transaction_date ASC
      LIMIT 1
      ''',
      [todayStr],
    );
    if (depDateRes.isNotEmpty && depDateRes.first['dep_date'] != null) {
      return depDateRes.first['dep_date'] as String;
    }

    return null;
  }

  /// Checks if there are any open/pending orders (`sales_order.payment_status = 0`).
  Future<bool> hasOpenOrders() async {
    final db = await _databaseHelper.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${SchemaConstants.salesOrder} WHERE payment_status = 0',
          ),
        ) ??
        0;
    return count > 0;
  }

  /// Checks if the cashier has completed Tender Declaration for the current un-X-read shift.
  Future<bool> hasTenderDeclarationForShift(int cashierId) async {
    final db = await _databaseHelper.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM ${SchemaConstants.cashDeclaration}
            WHERE cashier_id = ?
              AND x_read_status = 0
              AND (z_number = 0 OR z_number IS NULL)
              AND status = 1
            ''',
            [cashierId],
          ),
        ) ??
        0;
    return count > 0;
  }

  /// Checks if at least one Tender Declaration exists for the un-Z-read day.
  Future<bool> hasTenderDeclarationForZRead() async {
    final db = await _databaseHelper.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM ${SchemaConstants.cashDeclaration}
            WHERE (z_number = 0 OR z_number IS NULL) AND status = 1
            ''',
          ),
        ) ??
        0;
    return count > 0;
  }

  /// Checks if any cashier still has un-X-read records (`x_read_status = 0 AND z_number = 0`)
  /// in `sale_transaction`, `deposit`, or `cash_declaration`, or an open shift (`status = 1`).
  Future<bool> hasAnyUnxReadRecords() async {
    final db = await _databaseHelper.database;

    final openShifts = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${SchemaConstants.shift} WHERE status = 1',
          ),
        ) ??
        0;
    if (openShifts > 0) return true;

    final unreadTxns = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM ${SchemaConstants.saleTransaction}
            WHERE x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)
            ''',
          ),
        ) ??
        0;
    if (unreadTxns > 0) return true;

    final unreadDeps = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM ${SchemaConstants.deposit}
            WHERE x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)
            ''',
          ),
        ) ??
        0;
    if (unreadDeps > 0) return true;

    final unreadDecs = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM ${SchemaConstants.cashDeclaration}
            WHERE x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)
            ''',
          ),
        ) ??
        0;
    return unreadDecs > 0;
  }

  /// KwikPOS Lite `shouldBlockTenderDeclarationDueToNoTransactions`:
  /// Returns true if the cashier has an active Change Fund (`deposit_amount > 0`)
  /// but 0 completed sales transactions in the current shift.
  Future<bool> shouldBlockTenderDeclarationDueToNoTransactions(
    int cashierId,
  ) async {
    final db = await _databaseHelper.database;
    final depCount = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM ${SchemaConstants.deposit}
            WHERE cashier_id = ? AND deposit_amount > 0
              AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)
            ''',
            [cashierId],
          ),
        ) ??
        0;
    if (depCount == 0) return false;

    final salesCount = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM ${SchemaConstants.saleTransaction}
            WHERE cashier_id = ? AND is_voided = 0
              AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)
            ''',
            [cashierId],
          ),
        ) ??
        0;
    return salesCount == 0;
  }

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

  // ===========================================================================
  // MODULE 1: OPENING CHANGE FUND (deposit + shift + counter_table + EJ)
  // ===========================================================================

  /// Opens a shift and records the opening Change Fund in `deposit` (`x_read_status = 0, z_number = 0`).
  Future<int> openShift(int cashierId, double beginningCash) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final counter = await _ensureCounterRow(txn);
      final nextTseq = (counter['tseq_no'] as num? ?? 0).toInt() + 1;
      final nextDepNo = (counter['deposit_number'] as num? ?? 1).toInt() + 1;

      await txn.update(
        SchemaConstants.counterTable,
        {
          'tseq_no': nextTseq,
          'deposit_number': nextDepNo,
          'last_updated': now,
        },
        where: 'id = 1',
      );

      // Insert into deposit (KwikPOS Lite cash_fund parity)
      await txn.insert(SchemaConstants.deposit, {
        'cashier_id': cashierId,
        'tseq_no': nextTseq,
        'deposit_amount': beginningCash,
        'z_number': 0,
        'x_read_status': 0,
        'status': 0, // 0 = Active / Un-X-Read
        'transaction_date': now,
        'created_at': now,
      });

      final shiftId = await txn.insert(SchemaConstants.shift, {
        'cashier_id': cashierId,
        'beginning_cash': beginningCash,
        'status': 1,
        'start_time': now,
        'created_at': now,
      });

      await txn.insert(SchemaConstants.electronicJournal, {
        'cashier_id': cashierId,
        'activity_type': 'CHANGE_FUND',
        'content':
            '=== OPENING CHANGE FUND ===\nShift ID: $shiftId | TSEQ: $nextTseq\nCashier ID: $cashierId\nBeginning Cash Float: ₱${beginningCash.toStringAsFixed(2)}\nTimestamp: $now',
        'created_at': now,
      });

      return shiftId;
    });
  }

  // ===========================================================================
  // MODULE 2: CASH FUND LOG (Cash In / Cash Out -> cash_fund_log)
  // ===========================================================================

  /// Records a Cash In (`movementType = 1`) or Cash Out (`movementType = 0`) operation in `cash_fund_log`.
  Future<int> insertCashFundLog({
    required int cashierId,
    required bool isCashIn,
    required double amount,
    required String reason,
    int? authorizedById,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final nextTseq = await _incrementTseqNo(txn);
      final movementType = isCashIn ? 1 : 0;

      final logId = await txn.insert(SchemaConstants.cashFundLog, {
        'cashier_id': cashierId,
        'authorized_by_id': authorizedById ?? cashierId,
        'tseq_no': nextTseq,
        'movement_type': movementType,
        'amount': amount,
        'reason': reason,
        'z_number': 0,
        'x_read_status': 0,
        'status': 1,
        'transaction_date': now,
        'created_at': now,
      });

      await txn.insert(SchemaConstants.electronicJournal, {
        'cashier_id': cashierId,
        'activity_type': isCashIn ? 'CASH_IN' : 'CASH_OUT',
        'content':
            '=== CASH FUND ${isCashIn ? "IN (DEPOSIT)" : "OUT (WITHDRAWAL)"} ===\nLog ID: $logId | TSEQ: $nextTseq\nCashier ID: $cashierId\nAmount: ₱${amount.toStringAsFixed(2)}\nReason: $reason\nTimestamp: $now',
        'created_at': now,
      });

      return logId;
    });
  }

  /// Retrieves un-X-read `cash_fund_log` entries for the given cashier.
  Future<List<Map<String, dynamic>>> getUnreadCashFundLogs(
    int cashierId,
  ) async {
    final db = await _databaseHelper.database;
    return await db.query(
      SchemaConstants.cashFundLog,
      where:
          'cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL) AND status = 1',
      whereArgs: [cashierId],
      orderBy: 'id DESC',
    );
  }

  // ===========================================================================
  // MODULE 3: TENDER DECLARATION (cash_declaration + cash_declaration_denomination)
  // ===========================================================================

  /// Returns current shift non-cash payment totals & counts grouped by payment method code.
  Future<Map<String, dynamic>> getShiftNonCashSummary(int cashierId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        LOWER(pm.code) AS method_code,
        COUNT(p.id) AS tx_count,
        COALESCE(SUM(p.amount), 0.0) AS total_amount,
        COALESCE(SUM(p.excess_amount), 0.0) AS total_excess
      FROM ${SchemaConstants.payment} p
      JOIN ${SchemaConstants.paymentMethod} pm ON p.payment_method_id = pm.id
      JOIN ${SchemaConstants.saleTransaction} st ON p.sale_transaction_id = st.id
      WHERE p.cashier_id = ?
        AND p.x_read_status = 0
        AND (p.z_number = 0 OR p.z_number IS NULL)
        AND p.status = 1
        AND st.is_voided = 0
      GROUP BY LOWER(pm.code)
      ''',
      [cashierId],
    );

    double cardAmount = 0.0;
    int cardCount = 0;
    double atmAmount = 0.0;
    int atmCount = 0;
    double checkAmount = 0.0;
    int checkCount = 0;
    double giftCheckAmount = 0.0;
    int giftCheckCount = 0;
    double chargeAmount = 0.0;
    int chargeCount = 0;
    double cashSales = 0.0;
    int cashCount = 0;
    double totalExcess = 0.0;

    for (final row in rows) {
      final code = (row['method_code'] as String? ?? '').toLowerCase();
      final count = (row['tx_count'] as num? ?? 0).toInt();
      final amt = (row['total_amount'] as num? ?? 0.0).toDouble();
      final exc = (row['total_excess'] as num? ?? 0.0).toDouble();
      totalExcess += exc;

      if (code == 'cash') {
        cashSales += amt;
        cashCount += count;
      } else if (code == 'card') {
        cardAmount += amt;
        cardCount += count;
      } else if (code == 'atm' || code == 'online') {
        atmAmount += amt;
        atmCount += count;
      } else if (code == 'bank_check') {
        checkAmount += amt;
        checkCount += count;
      } else if (code == 'gift_check' || code == 'coupon') {
        giftCheckAmount += amt;
        giftCheckCount += count;
      } else if (code == 'charge') {
        chargeAmount += amt;
        chargeCount += count;
      }
    }

    final totalNonCash =
        cardAmount + atmAmount + checkAmount + giftCheckAmount + chargeAmount;

    return {
      'cashSales': cashSales,
      'cashCount': cashCount,
      'cardAmount': cardAmount,
      'cardCount': cardCount,
      'atmAmount': atmAmount,
      'atmCount': atmCount,
      'checkAmount': checkAmount,
      'checkCount': checkCount,
      'giftCheckAmount': giftCheckAmount,
      'giftCheckCount': giftCheckCount,
      'chargeAmount': chargeAmount,
      'chargeCount': chargeCount,
      'totalNonCash': totalNonCash,
      'totalExcess': totalExcess,
    };
  }

  /// Gets the active un-X-read `cash_declaration` and its `CashDenominationCount` list for `cashierId`, if any.
  Future<Map<String, dynamic>?> getActiveCashDeclaration(int cashierId) async {
    final db = await _databaseHelper.database;
    final decRows = await db.query(
      SchemaConstants.cashDeclaration,
      where:
          'cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL) AND status = 1',
      whereArgs: [cashierId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (decRows.isEmpty) return null;

    final dec = decRows.first;
    final decId = dec['id'] as int;
    final denomRows = await db.query(
      SchemaConstants.cashDeclarationDenomination,
      where: 'cash_declaration_id = ?',
      whereArgs: [decId],
      orderBy: 'denomination DESC',
    );
    final denominations = denomRows
        .map(
          (r) => CashDenominationCount(
            denomination: (r['denomination'] as num).toDouble(),
            count: (r['quantity'] as num).toInt(),
          ),
        )
        .toList();

    return {
      'declaration': dec,
      'totalCash': (dec['total_cash'] as num? ?? 0.0).toDouble(),
      'denominations': denominations,
    };
  }

  /// Saves or updates Tender Declaration and Denominations (`cash_declaration` + `cash_declaration_denomination`).
  Future<int> saveCashDeclaration({
    required int cashierId,
    required double totalCash,
    required double changeFund,
    required List<CashDenominationCount> denominations,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();
    final nonCash = await getShiftNonCashSummary(cashierId);
    final totalNonCash = (nonCash['totalNonCash'] as num? ?? 0.0).toDouble();
    final totalDeclaredAllTenders = totalCash + totalNonCash;

    return await db.transaction((txn) async {
      // Check if an un-X-read declaration already exists for this cashier (KwikPOS Lite update-in-place parity)
      final existing = await txn.query(
        SchemaConstants.cashDeclaration,
        where:
            'cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL) AND status = 1',
        whereArgs: [cashierId],
        orderBy: 'id DESC',
        limit: 1,
      );

      int declarationId;
      int tseqNo;

      if (existing.isNotEmpty) {
        declarationId = existing.first['id'] as int;
        tseqNo = (existing.first['tseq_no'] as num? ?? 0).toInt();
        await txn.update(
          SchemaConstants.cashDeclaration,
          {
            'total_cash': totalCash,
            'total_amount': totalDeclaredAllTenders,
            'card_count': nonCash['cardCount'] as int? ?? 0,
            'check_count': nonCash['checkCount'] as int? ?? 0,
            'gift_check_count': nonCash['giftCheckCount'] as int? ?? 0,
            'account_count': nonCash['chargeCount'] as int? ?? 0,
            'atm_count': nonCash['atmCount'] as int? ?? 0,
            'change_fund': changeFund,
            'transaction_date': now,
          },
          where: 'id = ?',
          whereArgs: [declarationId],
        );
        await txn.delete(
          SchemaConstants.cashDeclarationDenomination,
          where: 'cash_declaration_id = ?',
          whereArgs: [declarationId],
        );
      } else {
        tseqNo = await _incrementTseqNo(txn);
        declarationId = await txn.insert(SchemaConstants.cashDeclaration, {
          'cashier_id': cashierId,
          'tseq_no': tseqNo,
          'total_cash': totalCash,
          'total_amount': totalDeclaredAllTenders,
          'card_count': nonCash['cardCount'] as int? ?? 0,
          'check_count': nonCash['checkCount'] as int? ?? 0,
          'gift_check_count': nonCash['giftCheckCount'] as int? ?? 0,
          'account_count': nonCash['chargeCount'] as int? ?? 0,
          'atm_count': nonCash['atmCount'] as int? ?? 0,
          'other_count': 0,
          'change_fund': changeFund,
          'z_number': 0,
          'x_read_status': 0,
          'status': 1,
          'transaction_date': now,
          'created_at': now,
        });
      }

      final batch = txn.batch();
      for (final denom in denominations) {
        batch.insert(SchemaConstants.cashDeclarationDenomination, {
          'cash_declaration_id': declarationId,
          'denomination': denom.denomination,
          'quantity': denom.count,
        });
      }
      await batch.commit(noResult: true);

      await txn.insert(SchemaConstants.electronicJournal, {
        'cashier_id': cashierId,
        'activity_type': 'TENDER_DECLARATION',
        'content':
            '=== TENDER DECLARATION ===\nDeclaration ID: $declarationId | TSEQ: $tseqNo\nCashier ID: $cashierId\nDeclared Physical Cash: ₱${totalCash.toStringAsFixed(2)}\nNon-Cash Total: ₱${totalNonCash.toStringAsFixed(2)}\nTotal Declared: ₱${totalDeclaredAllTenders.toStringAsFixed(2)}\nTimestamp: $now',
        'created_at': now,
      });

      return declarationId;
    });
  }

  /// Calculates theoretical cash collected for active shift (used for quick lookup)
  Future<double> getShiftCashSales(String startTime, String endTime) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(p.amount), 0.0) AS total_cash_sales
      FROM ${SchemaConstants.payment} p
      INNER JOIN ${SchemaConstants.paymentMethod} pm ON p.payment_method_id = pm.id
      INNER JOIN ${SchemaConstants.saleTransaction} st ON p.sale_transaction_id = st.id
      WHERE st.status = 1 AND st.is_voided = 0
        AND LOWER(pm.code) = 'cash'
        AND p.x_read_status = 0 AND (p.z_number = 0 OR p.z_number IS NULL)
      ''',
    );

    return (result.first['total_cash_sales'] as num? ?? 0.0).toDouble();
  }

  // ===========================================================================
  // MODULE 4: X-READING DATA & CLOSEOUT EXECUTION
  // ===========================================================================

  /// Computes the complete KwikPOS Lite X-Reading report metrics for `cashierId`.
  Future<Map<String, dynamic>> getXReadingReportData(int cashierId) async {
    final db = await _databaseHelper.database;

    // 1. Payment Media Summary
    final nonCash = await getShiftNonCashSummary(cashierId);
    final cashSales = (nonCash['cashSales'] as num? ?? 0.0).toDouble();
    final cashCount = (nonCash['cashCount'] as num? ?? 0).toInt();

    // 2. Beginning Change Fund (`deposit` or active `shift`)
    final depRes = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(deposit_amount), 0.0) AS total_deposit
      FROM ${SchemaConstants.deposit}
      WHERE cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)
      ''',
      [cashierId],
    );
    double beginningCash =
        (depRes.first['total_deposit'] as num? ?? 0.0).toDouble();
    if (beginningCash == 0.0) {
      final shift = await getActiveShift(cashierId);
      if (shift != null) {
        beginningCash = (shift['beginning_cash'] as num? ?? 0.0).toDouble();
      }
    }

    // 3. Cash In / Cash Out (`cash_fund_log`)
    final cashInRes = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0.0) AS total_in
      FROM ${SchemaConstants.cashFundLog}
      WHERE cashier_id = ? AND movement_type = 1
        AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL) AND status = 1
      ''',
      [cashierId],
    );
    final cashOutRes = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0.0) AS total_out
      FROM ${SchemaConstants.cashFundLog}
      WHERE cashier_id = ? AND movement_type = 0
        AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL) AND status = 1
      ''',
      [cashierId],
    );
    final cashIn = (cashInRes.first['total_in'] as num? ?? 0.0).toDouble();
    final cashOut = (cashOutRes.first['total_out'] as num? ?? 0.0).toDouble();

    // 4. Declared Cash (`cash_declaration`)
    final activeDec = await getActiveCashDeclaration(cashierId);
    final declaredCash =
        (activeDec?['totalCash'] as num?)?.toDouble();
    final expectedCash = beginningCash + cashSales + cashIn - cashOut;
    final shortOver = (declaredCash ?? 0.0) - expectedCash;

    // 5. Sales & Tax Aggregates from `sale_transaction`
    final salesAgg = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS sales_count,
        COALESCE(SUM(guest_count), 0) AS guest_count,
        COALESCE(SUM(gross_amount), 0.0) AS gross_sales,
        COALESCE(SUM(discount_amount), 0.0) AS order_discount,
        COALESCE(SUM(item_discount_amount), 0.0) AS item_discount,
        COALESCE(SUM(surcharge_amount), 0.0) AS surcharge_amount,
        COALESCE(SUM(net_amount), 0.0) AS net_sales,
        COALESCE(SUM(vat_sales), 0.0) AS vatable_sales,
        COALESCE(SUM(vat_amount), 0.0) AS vat_amount,
        COALESCE(SUM(vat_exempt), 0.0) AS vat_exempt_sales,
        COALESCE(SUM(vat_zero_rated), 0.0) AS zero_rated_sales,
        COALESCE(SUM(vat_private), 0.0) AS vat_private,
        COALESCE(SUM(non_vat_sales), 0.0) AS non_vat_sales,
        MIN(si_number) AS beg_si_no,
        MAX(si_number) AS end_si_no,
        MIN(tseq_no) AS beg_tseq_no,
        MAX(tseq_no) AS end_tseq_no
      FROM ${SchemaConstants.saleTransaction}
      WHERE cashier_id = ?
        AND is_voided = 0
        AND x_read_status = 0
        AND (z_number = 0 OR z_number IS NULL)
      ''',
      [cashierId],
    );
    final sRow = salesAgg.first;

    // 6. Post-Void Aggregates
    final voidAgg = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS void_count,
        COALESCE(SUM(net_amount), 0.0) AS void_amount
      FROM ${SchemaConstants.saleTransaction}
      WHERE cashier_id = ?
        AND is_voided = 1
        AND x_read_status = 0
        AND (z_number = 0 OR z_number IS NULL)
      ''',
      [cashierId],
    );
    final vRow = voidAgg.first;

    // 7. Discount Breakdown by Name
    final discRows = await db.rawQuery(
      '''
      SELECT
        COALESCE(d.name, 'Manual / Line Discount') AS disc_name,
        COUNT(st.id) AS disc_count,
        COALESCE(SUM(st.discount_amount + st.item_discount_amount), 0.0) AS disc_total
      FROM ${SchemaConstants.saleTransaction} st
      LEFT JOIN ${SchemaConstants.discount} d ON st.discount_id = d.id
      WHERE st.cashier_id = ?
        AND st.is_voided = 0
        AND st.x_read_status = 0
        AND (st.z_number = 0 OR st.z_number IS NULL)
        AND (st.discount_amount > 0 OR st.item_discount_amount > 0)
      GROUP BY COALESCE(d.name, 'Manual / Line Discount')
      ''',
      [cashierId],
    );
    final Map<String, double> discountBreakdown = {};
    for (final dr in discRows) {
      discountBreakdown[dr['disc_name'] as String] =
          (dr['disc_total'] as num? ?? 0.0).toDouble();
    }

    final grossSales = (sRow['gross_sales'] as num? ?? 0.0).toDouble();
    final orderDisc = (sRow['order_discount'] as num? ?? 0.0).toDouble();
    final itemDisc = (sRow['item_discount'] as num? ?? 0.0).toDouble();
    final totalDiscounts = orderDisc + itemDisc;
    final vatPrivate = (sRow['vat_private'] as num? ?? 0.0).toDouble();
    final surchargeAmount =
        (sRow['surcharge_amount'] as num? ?? 0.0).toDouble();
    final netSales = (sRow['net_sales'] as num? ?? 0.0).toDouble();
    final voidAmount = (vRow['void_amount'] as num? ?? 0.0).toDouble();
    final voidCount = (vRow['void_count'] as num? ?? 0).toInt();

    return {
      'cashierId': cashierId,
      'beginningCash': beginningCash,
      'cashSales': cashSales,
      'cashCount': cashCount,
      'cardAmount': nonCash['cardAmount'],
      'cardCount': nonCash['cardCount'],
      'atmAmount': nonCash['atmAmount'],
      'atmCount': nonCash['atmCount'],
      'checkAmount': nonCash['checkAmount'],
      'checkCount': nonCash['checkCount'],
      'giftCheckAmount': nonCash['giftCheckAmount'],
      'giftCheckCount': nonCash['giftCheckCount'],
      'chargeAmount': nonCash['chargeAmount'],
      'chargeCount': nonCash['chargeCount'],
      'totalNonCash': nonCash['totalNonCash'],
      'totalExcess': nonCash['totalExcess'],
      'cashIn': cashIn,
      'cashOut': cashOut,
      'expectedCash': expectedCash,
      'declaredCash': declaredCash,
      'shortOver': shortOver,
      'grossSales': grossSales + voidAmount, // KwikPOS Lite includes void in Gross then deducts Void
      'netGrossSales': grossSales,
      'postVoidAmount': voidAmount,
      'postVoidCount': voidCount,
      'orderDiscountAmount': orderDisc,
      'itemDiscountAmount': itemDisc,
      'totalDiscounts': totalDiscounts,
      'surchargeAmount': surchargeAmount,
      'netSales': netSales,
      'vatableSales': (sRow['vatable_sales'] as num? ?? 0.0).toDouble(),
      'vatAmount': (sRow['vat_amount'] as num? ?? 0.0).toDouble(),
      'vatExemptSales': (sRow['vat_exempt_sales'] as num? ?? 0.0).toDouble(),
      'zeroRatedSales': (sRow['zero_rated_sales'] as num? ?? 0.0).toDouble(),
      'vatPrivate': vatPrivate,
      'nonVatSales': (sRow['non_vat_sales'] as num? ?? 0.0).toDouble(),
      'salesCount': (sRow['sales_count'] as num? ?? 0).toInt(),
      'guestCount': (sRow['guest_count'] as num? ?? 0).toInt(),
      'begSiNo': (sRow['beg_si_no'] as num? ?? 0).toInt(),
      'endSiNo': (sRow['end_si_no'] as num? ?? 0).toInt(),
      'begTseqNo': (sRow['beg_tseq_no'] as num? ?? 0).toInt(),
      'endTseqNo': (sRow['end_tseq_no'] as num? ?? 0).toInt(),
      'discountBreakdown': discountBreakdown,
    };
  }

  /// Executes KwikPOS Lite X-Reading shift closeout:
  /// 1. Increments `counter_table.tseq_no`
  /// 2. Inserts `short_over` (`z_number = 0, status = 1`)
  /// 3. Seals `x_read_status = 1` across all shift tables for `cashierId`
  /// 4. Closes active `shift` (`status = 2`)
  /// 5. Writes `X_READING_CLOSEOUT` to `electronic_journal`
  Future<void> executeXReading({
    required int cashierId,
    int? shiftId,
  }) async {
    final report = await getXReadingReportData(cashierId);
    final beginningCash = (report['beginningCash'] as num? ?? 0.0).toDouble();
    final cashSales = (report['cashSales'] as num? ?? 0.0).toDouble();
    final expectedCash = (report['expectedCash'] as num? ?? 0.0).toDouble();
    final declaredCash = (report['declaredCash'] as num? ?? 0.0).toDouble();
    final variance = declaredCash - expectedCash;

    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final nextTseq = await _incrementTseqNo(txn);

      // 1. Insert Short/Over record (z_number = 0)
      await txn.insert(SchemaConstants.shortOver, {
        'cashier_id': cashierId,
        'tseq_no': nextTseq,
        'total_cash': declaredCash,
        'change_fund': beginningCash,
        'total_collected': cashSales,
        'theoretical_sales': expectedCash,
        'actual_cash': declaredCash,
        'short_amount': variance < 0 ? variance.abs() : 0.0,
        'over_amount': variance > 0 ? variance : 0.0,
        'short_over_amount': variance,
        'z_number': 0,
        'status': 1,
        'transaction_date': now,
        'created_at': now,
      });

      // 2. Seal x_read_status = 1 for this cashier across all shift tables
      await txn.update(
        SchemaConstants.saleTransaction,
        {'x_read_status': 1, 'posted_at': now},
        where:
            'cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)',
        whereArgs: [cashierId],
      );

      await txn.update(
        SchemaConstants.payment,
        {'x_read_status': 1, 'posted_at': now},
        where:
            'cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)',
        whereArgs: [cashierId],
      );

      await txn.update(
        SchemaConstants.deposit,
        {'x_read_status': 1, 'status': 1, 'posted_at': now},
        where:
            'cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)',
        whereArgs: [cashierId],
      );

      await txn.update(
        SchemaConstants.cashDeclaration,
        {'x_read_status': 1, 'posted_at': now},
        where:
            'cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)',
        whereArgs: [cashierId],
      );

      await txn.update(
        SchemaConstants.cashFundLog,
        {'x_read_status': 1, 'posted_at': now},
        where:
            'cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)',
        whereArgs: [cashierId],
      );

      await txn.update(
        SchemaConstants.voidTransaction,
        {'x_read_status': 1, 'posted_at': now},
        where:
            'cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)',
        whereArgs: [cashierId],
      );

      await txn.update(
        SchemaConstants.paymentDeposit,
        {'x_read_status': 1, 'posted_at': now},
        where:
            'cashier_id = ? AND x_read_status = 0 AND (z_number = 0 OR z_number IS NULL)',
        whereArgs: [cashierId],
      );

      // 3. Close active Shift(s) for this cashier
      if (shiftId != null) {
        await txn.update(
          SchemaConstants.shift,
          {
            'ending_cash': declaredCash,
            'cash_variance': variance,
            'status': 2, // Closed
            'end_time': now,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [shiftId],
        );
      } else {
        await txn.update(
          SchemaConstants.shift,
          {
            'ending_cash': declaredCash,
            'cash_variance': variance,
            'status': 2,
            'end_time': now,
            'updated_at': now,
          },
          where: 'cashier_id = ? AND status = 1',
          whereArgs: [cashierId],
        );
      }

      // 4. Log X-Reading closeout entry in Electronic Journal (using valid schema columns)
      final xReadContent = StringBuffer()
        ..writeln('=== X-READING SHIFT CLOSEOUT ===')
        ..writeln('TSEQ: $nextTseq | CASHIER ID: $cashierId')
        ..writeln('DATE: $now')
        ..writeln('Beginning Cash: ₱${beginningCash.toStringAsFixed(2)}')
        ..writeln('Cash Sales: ₱${cashSales.toStringAsFixed(2)}')
        ..writeln('Expected Cash: ₱${expectedCash.toStringAsFixed(2)}')
        ..writeln('Declared Cash: ₱${declaredCash.toStringAsFixed(2)}')
        ..writeln('Variance (Short/Over): ₱${variance.toStringAsFixed(2)}')
        ..writeln('Net Sales: ₱${(report["netSales"] as num? ?? 0.0).toStringAsFixed(2)}');

      await txn.insert(SchemaConstants.electronicJournal, {
        'cashier_id': cashierId,
        'activity_type': 'X_READING_CLOSEOUT',
        'content': xReadContent.toString(),
        'created_at': now,
      });
    });
  }

  /// Backward-compatible wrapper around `executeXReading`.
  Future<void> closeShift({
    required int shiftId,
    required int cashierId,
    required double beginningCash,
    required double theoreticalCashSales,
    required double actualCashCount,
  }) async {
    await executeXReading(cashierId: cashierId, shiftId: shiftId);
  }

  // ===========================================================================
  // MODULE 5: Z-READING DATA & END-OF-DAY CLOSEOUT EXECUTION
  // ===========================================================================

  /// Computes the consolidated KwikPOS Lite Z-Reading report data across all shifts
  /// where `z_number = 0 OR z_number IS NULL`.
  Future<Map<String, dynamic>> getZReadingReportData() async {
    final db = await _databaseHelper.database;

    // 1. Consolidated Payment Media Breakdown across all cashiers (`z_number = 0 OR z_number IS NULL`)
    final payRows = await db.rawQuery(
      '''
      SELECT
        LOWER(pm.code) AS method_code,
        COUNT(p.id) AS tx_count,
        COALESCE(SUM(p.amount), 0.0) AS total_amount,
        COALESCE(SUM(p.excess_amount), 0.0) AS total_excess
      FROM ${SchemaConstants.payment} p
      JOIN ${SchemaConstants.paymentMethod} pm ON p.payment_method_id = pm.id
      JOIN ${SchemaConstants.saleTransaction} st ON p.sale_transaction_id = st.id
      WHERE (p.z_number = 0 OR p.z_number IS NULL)
        AND p.status = 1
        AND st.is_voided = 0
      GROUP BY LOWER(pm.code)
      ''',
    );

    double cashSales = 0.0;
    int cashCount = 0;
    double cardAmount = 0.0;
    int cardCount = 0;
    double atmAmount = 0.0;
    int atmCount = 0;
    double checkAmount = 0.0;
    int checkCount = 0;
    double giftCheckAmount = 0.0;
    int giftCheckCount = 0;
    double chargeAmount = 0.0;
    int chargeCount = 0;
    double totalExcess = 0.0;

    for (final row in payRows) {
      final code = (row['method_code'] as String? ?? '').toLowerCase();
      final count = (row['tx_count'] as num? ?? 0).toInt();
      final amt = (row['total_amount'] as num? ?? 0.0).toDouble();
      final exc = (row['total_excess'] as num? ?? 0.0).toDouble();
      totalExcess += exc;

      if (code == 'cash') {
        cashSales += amt;
        cashCount += count;
      } else if (code == 'card') {
        cardAmount += amt;
        cardCount += count;
      } else if (code == 'atm' || code == 'online') {
        atmAmount += amt;
        atmCount += count;
      } else if (code == 'bank_check') {
        checkAmount += amt;
        checkCount += count;
      } else if (code == 'gift_check' || code == 'coupon') {
        giftCheckAmount += amt;
        giftCheckCount += count;
      } else if (code == 'charge') {
        chargeAmount += amt;
        chargeCount += count;
      }
    }

    // 2. Consolidated Beginning Change Fund (`deposit`)
    final depRes = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(deposit_amount), 0.0) AS total_deposit
      FROM ${SchemaConstants.deposit}
      WHERE (z_number = 0 OR z_number IS NULL)
      ''',
    );
    final beginningCash =
        (depRes.first['total_deposit'] as num? ?? 0.0).toDouble();

    // 3. Consolidated Cash In / Cash Out (`cash_fund_log`)
    final cashInRes = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0.0) AS total_in
      FROM ${SchemaConstants.cashFundLog}
      WHERE movement_type = 1 AND (z_number = 0 OR z_number IS NULL) AND status = 1
      ''',
    );
    final cashOutRes = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0.0) AS total_out
      FROM ${SchemaConstants.cashFundLog}
      WHERE movement_type = 0 AND (z_number = 0 OR z_number IS NULL) AND status = 1
      ''',
    );
    final cashIn = (cashInRes.first['total_in'] as num? ?? 0.0).toDouble();
    final cashOut = (cashOutRes.first['total_out'] as num? ?? 0.0).toDouble();

    // 4. Consolidated Declared Cash (`cash_declaration`) & Short/Over
    final decRes = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_cash), 0.0) AS total_declared_cash
      FROM ${SchemaConstants.cashDeclaration}
      WHERE (z_number = 0 OR z_number IS NULL) AND status = 1
      ''',
    );
    final declaredCash =
        (decRes.first['total_declared_cash'] as num? ?? 0.0).toDouble();
    final expectedCash = beginningCash + cashSales + cashIn - cashOut;
    final shortOver = declaredCash - expectedCash;

    // 5. Consolidated Sales & Tax Aggregates (`sale_transaction`)
    final salesAgg = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS sales_count,
        COALESCE(SUM(guest_count), 0) AS guest_count,
        COALESCE(SUM(gross_amount), 0.0) AS gross_sales,
        COALESCE(SUM(discount_amount), 0.0) AS order_discount,
        COALESCE(SUM(item_discount_amount), 0.0) AS item_discount,
        COALESCE(SUM(CASE WHEN (discount_amount > 0 OR item_discount_amount > 0) THEN 1 ELSE 0 END), 0) AS discount_count,
        COALESCE(SUM(surcharge_amount), 0.0) AS surcharge_amount,
        COALESCE(SUM(net_amount), 0.0) AS net_sales,
        COALESCE(SUM(vat_sales), 0.0) AS vatable_sales,
        COALESCE(SUM(vat_amount), 0.0) AS vat_amount,
        COALESCE(SUM(vat_exempt), 0.0) AS vat_exempt_sales,
        COALESCE(SUM(vat_zero_rated), 0.0) AS zero_rated_sales,
        COALESCE(SUM(vat_private), 0.0) AS vat_private,
        COALESCE(SUM(non_vat_sales), 0.0) AS non_vat_sales,
        MIN(si_number) AS beg_si_no,
        MAX(si_number) AS end_si_no,
        MIN(tseq_no) AS beg_tseq_no,
        MAX(tseq_no) AS end_tseq_no
      FROM ${SchemaConstants.saleTransaction}
      WHERE is_voided = 0 AND (z_number = 0 OR z_number IS NULL)
      ''',
    );
    final sRow = salesAgg.first;

    // 6. Consolidated Post-Void Aggregates
    final voidAgg = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS void_count,
        COALESCE(SUM(net_amount), 0.0) AS void_amount
      FROM ${SchemaConstants.saleTransaction}
      WHERE is_voided = 1 AND (z_number = 0 OR z_number IS NULL)
      ''',
    );
    final vRow = voidAgg.first;

    // 7. Consolidated Discount Breakdown by Name
    final discRows = await db.rawQuery(
      '''
      SELECT
        COALESCE(d.name, 'Manual / Line Discount') AS disc_name,
        COALESCE(SUM(st.discount_amount + st.item_discount_amount), 0.0) AS disc_total
      FROM ${SchemaConstants.saleTransaction} st
      LEFT JOIN ${SchemaConstants.discount} d ON st.discount_id = d.id
      WHERE st.is_voided = 0
        AND (st.z_number = 0 OR st.z_number IS NULL)
        AND (st.discount_amount > 0 OR st.item_discount_amount > 0)
      GROUP BY COALESCE(d.name, 'Manual / Line Discount')
      ''',
    );
    final Map<String, double> discountBreakdown = {};
    for (final dr in discRows) {
      discountBreakdown[dr['disc_name'] as String] =
          (dr['disc_total'] as num? ?? 0.0).toDouble();
    }

    // 8. Z-Counter & Accumulated Grand Totals (`daily_summary` & `counter_table`)
    final counter = await _ensureCounterRow(db);
    final nextZNumber = (counter['z_read_count'] as num? ?? 0).toInt() + 1;

    final prevGrandRes = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(net_sales), 0.0) AS prev_grand_total
      FROM ${SchemaConstants.dailySummary}
      ''',
    );
    final previousGrandTotal =
        (prevGrandRes.first['prev_grand_total'] as num? ?? 0.0).toDouble();

    final grossSales = (sRow['gross_sales'] as num? ?? 0.0).toDouble();
    final voidAmount = (vRow['void_amount'] as num? ?? 0.0).toDouble();
    final voidCount = (vRow['void_count'] as num? ?? 0).toInt();
    final orderDisc = (sRow['order_discount'] as num? ?? 0.0).toDouble();
    final itemDisc = (sRow['item_discount'] as num? ?? 0.0).toDouble();
    final totalDiscounts = orderDisc + itemDisc;
    final discountCount = (sRow['discount_count'] as num? ?? 0).toInt();
    final surchargeAmount =
        (sRow['surcharge_amount'] as num? ?? 0.0).toDouble();
    final netSales = (sRow['net_sales'] as num? ?? 0.0).toDouble();
    final presentGrandTotal = previousGrandTotal + netSales;

    return {
      'nextZNumber': nextZNumber,
      'previousGrandTotal': previousGrandTotal,
      'presentGrandTotal': presentGrandTotal,
      'beginningCash': beginningCash,
      'cashSales': cashSales,
      'cashCount': cashCount,
      'cardAmount': cardAmount,
      'cardCount': cardCount,
      'atmAmount': atmAmount,
      'atmCount': atmCount,
      'checkAmount': checkAmount,
      'checkCount': checkCount,
      'giftCheckAmount': giftCheckAmount,
      'giftCheckCount': giftCheckCount,
      'chargeAmount': chargeAmount,
      'chargeCount': chargeCount,
      'totalNonCash':
          cardAmount + atmAmount + checkAmount + giftCheckAmount + chargeAmount,
      'totalExcess': totalExcess,
      'cashIn': cashIn,
      'cashOut': cashOut,
      'expectedCash': expectedCash,
      'declaredCash': declaredCash,
      'shortOver': shortOver,
      'grossSales': grossSales + voidAmount,
      'netGrossSales': grossSales,
      'postVoidAmount': voidAmount,
      'postVoidCount': voidCount,
      'orderDiscountAmount': orderDisc,
      'itemDiscountAmount': itemDisc,
      'totalDiscounts': totalDiscounts,
      'discountCount': discountCount,
      'surchargeAmount': surchargeAmount,
      'netSales': netSales,
      'vatableSales': (sRow['vatable_sales'] as num? ?? 0.0).toDouble(),
      'vatAmount': (sRow['vat_amount'] as num? ?? 0.0).toDouble(),
      'vatExemptSales': (sRow['vat_exempt_sales'] as num? ?? 0.0).toDouble(),
      'zeroRatedSales': (sRow['zero_rated_sales'] as num? ?? 0.0).toDouble(),
      'vatPrivate': (sRow['vat_private'] as num? ?? 0.0).toDouble(),
      'nonVatSales': (sRow['non_vat_sales'] as num? ?? 0.0).toDouble(),
      'salesCount': (sRow['sales_count'] as num? ?? 0).toInt(),
      'guestCount': (sRow['guest_count'] as num? ?? 0).toInt(),
      'begSiNo': (sRow['beg_si_no'] as num? ?? 0).toInt(),
      'endSiNo': (sRow['end_si_no'] as num? ?? 0).toInt(),
      'begTseqNo': (sRow['beg_tseq_no'] as num? ?? 0).toInt(),
      'endTseqNo': (sRow['end_tseq_no'] as num? ?? 0).toInt(),
      'discountBreakdown': discountBreakdown,
    };
  }

  /// Executes KwikPOS Lite Z-Reading End-of-Day Closeout:
  /// 1. Validates no open orders and no un-X-read records exist
  /// 2. Increments `counter_table.tseq_no` and `counter_table.z_read_count` (`newZNumber`)
  /// 3. Inserts consolidated EOD row into `daily_summary`
  /// 4. Seals `z_number = newZNumber` across all operational tables (`sale_transaction`, `payment`, `cogs_line`, `deposit`, `cash_fund_log`, `cash_declaration`, `short_over`, `void_transaction`, `payment_deposit`)
  /// 5. Logs `Z_READING_CLOSEOUT` to `electronic_journal`
  Future<int> executeZReading({required int cashierId}) async {
    if (await hasOpenOrders()) {
      throw Exception(
        'Cannot execute Z-Reading while there are open/unpaid orders.',
      );
    }
    if (await hasAnyUnxReadRecords()) {
      throw Exception(
        'All cashiers must complete Tender Declaration and X-Reading before running Z-Reading.',
      );
    }

    final zData = await getZReadingReportData();
    final db = await _databaseHelper.database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final counter = await _ensureCounterRow(txn);
      final nextTseq = (counter['tseq_no'] as num? ?? 0).toInt() + 1;
      final newZNumber = (counter['z_read_count'] as num? ?? 0).toInt() + 1;

      await txn.update(
        SchemaConstants.counterTable,
        {
          'tseq_no': nextTseq,
          'z_read_count': newZNumber,
          'last_updated': now,
        },
        where: 'id = 1',
      );

      // 1. Insert consolidated EOD record into daily_summary
      await txn.insert(SchemaConstants.dailySummary, {
        'cashier_id': cashierId,
        'tseq_no': nextTseq,
        'z_number': newZNumber,
        'cash_amount': zData['declaredCash'],
        'cash_count': zData['cashCount'],
        'charge_amount': zData['chargeAmount'],
        'charge_count': zData['chargeCount'],
        'atm_amount': zData['atmAmount'],
        'atm_count': zData['atmCount'],
        'card_amount': zData['cardAmount'],
        'card_count': zData['cardCount'],
        'check_amount': zData['checkAmount'],
        'check_count': zData['checkCount'],
        'gift_check_amount': zData['giftCheckAmount'],
        'gift_check_count': zData['giftCheckCount'],
        'cash_in': zData['cashIn'],
        'cash_out': zData['cashOut'],
        'discount_amount': zData['totalDiscounts'],
        'discount_count': zData['discountCount'],
        'net_sales': zData['netSales'],
        'sales_count': zData['salesCount'],
        'deposit_amount': zData['beginningCash'],
        'guest_count': zData['guestCount'],
        'transaction_date': now,
        'created_at': now,
        'posted_at': now,
      });

      // 2. Seal z_number = newZNumber across all un-Z-read tables
      final tablesToSeal = [
        SchemaConstants.saleTransaction,
        SchemaConstants.payment,
        SchemaConstants.cogsLine,
        SchemaConstants.deposit,
        SchemaConstants.cashFundLog,
        SchemaConstants.cashDeclaration,
        SchemaConstants.shortOver,
        SchemaConstants.voidTransaction,
        SchemaConstants.paymentDeposit,
      ];

      for (final table in tablesToSeal) {
        await txn.update(
          table,
          {
            'z_number': newZNumber,
            'posted_at': now,
          },
          where: 'z_number = 0 OR z_number IS NULL',
        );
      }

      // 3. Log Z-Reading EOD closeout to Electronic Journal
      final zReadContent = StringBuffer()
        ..writeln('=== Z-READING END-OF-DAY CLOSEOUT ===')
        ..writeln('Z-COUNTER: #$newZNumber | TSEQ: $nextTseq | CASHIER ID: $cashierId')
        ..writeln('DATE: $now')
        ..writeln('Previous Grand Total: ₱${(zData["previousGrandTotal"] as num).toStringAsFixed(2)}')
        ..writeln('Net Sales Today: ₱${(zData["netSales"] as num).toStringAsFixed(2)}')
        ..writeln('Present Grand Total: ₱${(zData["presentGrandTotal"] as num).toStringAsFixed(2)}')
        ..writeln('Declared Cash: ₱${(zData["declaredCash"] as num).toStringAsFixed(2)}')
        ..writeln('Short/Over: ₱${(zData["shortOver"] as num).toStringAsFixed(2)}');

      await txn.insert(SchemaConstants.electronicJournal, {
        'cashier_id': cashierId,
        'activity_type': 'Z_READING_CLOSEOUT',
        'content': zReadContent.toString(),
        'created_at': now,
      });

      return newZNumber;
    });
  }
}
