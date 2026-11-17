import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/data/dao/shift_dao.dart';
import 'package:suki_pos/domain/entities/shift/cash_denomination_count.dart';
import 'package:suki_pos/domain/entities/shift/shift.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_state.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final ShiftDao shiftDao;

  ShiftCubit({required this.shiftDao}) : super(ShiftInitial());

  /// Evaluates KwikPOS Lite's 4 pre-flight guards before entering Sales Entry:
  /// 1. Z-Reading already completed for today
  /// 2. Previous day's Z-Reading was skipped
  /// 3. Another cashier has un-X-read records / open shift
  /// 4. Whether current cashier needs to enter Opening Change Fund
  Future<SalesEntryGuardResult> evaluateSalesEntryGuards(
    int cashierId,
  ) async {
    try {
      final isZDoneToday = await shiftDao.isZReadingDoneForToday();
      final hasUnxRead = await shiftDao.hasAnyUnxReadRecords();
      if (isZDoneToday && !hasUnxRead) {
        return const SalesEntryGuardResult(
          canProceed: false,
          blockTitle: 'Store Already Closed (Z-Reading Done)',
          blockMessage:
              'End-of-Day Z-Reading has already been completed for today. No new sales transactions can be entered until the next business day.',
        );
      }

      final missingDate = await shiftDao.getMissingZReadingDate();
      if (missingDate != null) {
        return SalesEntryGuardResult(
          canProceed: false,
          blockTitle: 'Pending Z-Reading From $missingDate',
          blockMessage:
              'Unclosed transactions from $missingDate were found. Please complete Tender Declaration, X-Reading, and Z-Reading in Sales Reading before starting a new day.',
          redirectToSalesReading: true,
        );
      }

      final pendingCashier = await shiftDao.getPendingCashierInfo(cashierId);
      if (pendingCashier != null) {
        final pendingName = pendingCashier['cashierName'] as String;
        return SalesEntryGuardResult(
          canProceed: false,
          blockTitle: 'Pending Cashier Shift Open',
          blockMessage:
              '$pendingName still has an open shift or un-X-read transactions. $pendingName must complete Tender Declaration and X-Reading before another cashier can transact.',
        );
      }

      final activeShift = await shiftDao.getActiveShift(cashierId);
      return SalesEntryGuardResult(
        canProceed: true,
        needsChangeFund: activeShift == null,
      );
    } catch (_) {
      return const SalesEntryGuardResult(
        canProceed: true,
        needsChangeFund: false,
      );
    }
  }

  /// Checks active shift and loads full X-Reading and Z-Reading metrics
  Future<void> checkActiveShift(int cashierId) async {
    emit(ShiftLoading());
    try {
      final map = await shiftDao.getActiveShift(cashierId);
      if (map == null) {
        final zData = await shiftDao.getZReadingReportData();
        final isZDone = await shiftDao.isZReadingDoneForToday();
        final openOrders = await shiftDao.hasOpenOrders();
        final unxRead = await shiftDao.hasAnyUnxReadRecords();
        final hasDayDec = await shiftDao.hasTenderDeclarationForZRead();
        final pending = await shiftDao.getPendingCashierInfo(cashierId);

        emit(
          ShiftInactive(
            zReadingData: zData,
            canRunZReading: hasDayDec && !unxRead && !openOrders,
            isZReadingDoneToday: isZDone,
            hasOpenOrders: openOrders,
            hasUnxReadRecords: unxRead,
            hasDayTenderDeclaration: hasDayDec,
            pendingCashierName: pending?['cashierName'] as String?,
          ),
        );
      } else {
        final shift = ShiftEntity(
          id: map['id'] as int,
          cashierId: map['cashier_id'] as int,
          beginningCash: (map['beginning_cash'] as num).toDouble(),
          status: map['status'] as int,
          startTime: DateTime.parse(map['start_time'] as String),
        );
        emit(ShiftActive(shift: shift));
        await refreshSalesReading();
      }
    } catch (e) {
      emit(ShiftError('Failed to load active shift: ${e.toString()}'));
    }
  }

  /// Step 1: Open register with change fund (`deposit` + `shift`)
  Future<bool> openShift(int cashierId, double beginningCash) async {
    emit(ShiftLoading());
    try {
      final shiftId = await shiftDao.openShift(cashierId, beginningCash);
      final newShift = ShiftEntity(
        id: shiftId,
        cashierId: cashierId,
        beginningCash: beginningCash,
        startTime: DateTime.now(),
      );
      emit(ShiftActive(shift: newShift));
      await refreshSalesReading();
      return true;
    } catch (e) {
      emit(ShiftError('Failed to open shift: ${e.toString()}'));
      return false;
    }
  }

  /// Refreshes all 4 Sales Reading modules (Cash Fund Logs, Non-Cash Summary, Tender Declaration, X-Reading, Z-Reading)
  Future<void> refreshSalesReading() async {
    if (state is ShiftActive) {
      final active = state as ShiftActive;
      final cashierId = active.shift.cashierId;
      try {
        final xData = await shiftDao.getXReadingReportData(cashierId);
        final zData = await shiftDao.getZReadingReportData();
        final nonCash = await shiftDao.getShiftNonCashSummary(cashierId);
        final activeDec = await shiftDao.getActiveCashDeclaration(cashierId);
        final logs = await shiftDao.getUnreadCashFundLogs(cashierId);
        final openOrders = await shiftDao.hasOpenOrders();
        final blockNoSales = await shiftDao
            .shouldBlockTenderDeclarationDueToNoTransactions(cashierId);

        final cashSales = (xData['cashSales'] as num? ?? 0.0).toDouble();
        final cashIn = (xData['cashIn'] as num? ?? 0.0).toDouble();
        final cashOut = (xData['cashOut'] as num? ?? 0.0).toDouble();
        final declaredCash =
            (activeDec?['totalCash'] as num?)?.toDouble() ??
            active.declaredCash;
        final denoms =
            (activeDec?['denominations'] as List<CashDenominationCount>?) ??
            active.denominations;

        emit(
          active.copyWith(
            theoreticalCashSales: cashSales,
            cashIn: cashIn,
            cashOut: cashOut,
            declaredCash: declaredCash,
            denominations: denoms,
            nonCashSummary: nonCash,
            xReadingData: xData,
            zReadingData: zData,
            cashFundLogs: logs,
            hasOpenOrders: openOrders,
            shouldBlockTenderDecNoSales: blockNoSales,
          ),
        );
      } catch (e) {
        emit(ShiftError('Failed to update sales reading: ${e.toString()}'));
      }
    }
  }

  /// Module 1: Record Cash In (`isCashIn = true`) or Cash Out (`isCashIn = false`) in `cash_fund_log`
  Future<bool> recordCashFundMovement({
    required int cashierId,
    required bool isCashIn,
    required double amount,
    required String reason,
    int? authorizedById,
  }) async {
    try {
      await shiftDao.insertCashFundLog(
        cashierId: cashierId,
        isCashIn: isCashIn,
        amount: amount,
        reason: reason,
        authorizedById: authorizedById,
      );
      await refreshSalesReading();
      return true;
    } catch (e) {
      emit(ShiftError('Failed to record cash fund movement: ${e.toString()}'));
      return false;
    }
  }

  /// Module 2: Save Tender Declaration & Cash Drawer Count (`cash_declaration` + `cash_declaration_denomination`)
  Future<void> saveTenderDeclaration(
    List<CashDenominationCount> denominations,
    double totalCash,
  ) async {
    if (state is ShiftActive) {
      final active = state as ShiftActive;
      try {
        await shiftDao.saveCashDeclaration(
          cashierId: active.shift.cashierId,
          totalCash: totalCash,
          changeFund: active.shift.beginningCash,
          denominations: denominations,
        );
        await refreshSalesReading();
      } catch (e) {
        emit(ShiftError('Failed to save cash declaration: ${e.toString()}'));
      }
    }
  }

  /// Module 3: Execute X-Reading (Inserts `short_over`, seals `x_read_status = 1`, closes shift)
  Future<bool> finalizeXReadingAndCloseShift() async {
    if (state is ShiftActive) {
      final active = state as ShiftActive;
      try {
        await shiftDao.executeXReading(
          cashierId: active.shift.cashierId,
          shiftId: active.shift.id,
        );
        await checkActiveShift(active.shift.cashierId);
        return true;
      } catch (e) {
        emit(ShiftError('Failed to finalize X-Reading: ${e.toString()}'));
      }
    }
    return false;
  }

  /// Module 4: Execute Z-Reading End-of-Day Closeout (Inserts `daily_summary`, increments `z_read_count`, seals `z_number`)
  Future<int?> finalizeZReadingCloseout(int cashierId) async {
    try {
      // If the current shift is still active (and has Tender Declaration), close X-Reading first if needed
      if (state is ShiftActive) {
        final active = state as ShiftActive;
        if (active.declaredCash != null) {
          await shiftDao.executeXReading(
            cashierId: active.shift.cashierId,
            shiftId: active.shift.id,
          );
        }
      }
      final newZNo = await shiftDao.executeZReading(cashierId: cashierId);
      await checkActiveShift(cashierId);
      return newZNo;
    } catch (e) {
      emit(ShiftError('Failed to execute Z-Reading: ${e.toString()}'));
      return null;
    }
  }
}
