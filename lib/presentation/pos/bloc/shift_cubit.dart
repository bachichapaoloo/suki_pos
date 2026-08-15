import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/data/dao/shift_dao.dart';
import 'package:suki_pos/domain/entities/shift/cash_denomination_count.dart';
import 'package:suki_pos/domain/entities/shift/shift.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_state.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final ShiftDao shiftDao;

  ShiftCubit({required this.shiftDao}) : super(ShiftInitial());

  /// Step 1: Check or prompt for an active shift
  Future<void> checkActiveShift(int cashierId) async {
    emit(ShiftLoading());
    try {
      final map = await shiftDao.getActiveShift(cashierId);
      if (map == null) {
        emit(ShiftInactive());
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

  /// Step 1: Open register with change fund
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
      return true;
    } catch (e) {
      emit(ShiftError('Failed to open shift: ${e.toString()}'));
      return false;
    }
  }

  /// Step 3: Refresh mid-day sales reading
  Future<void> refreshSalesReading() async {
    if (state is ShiftActive) {
      final active = state as ShiftActive;
      try {
        final cashSales = await shiftDao.getShiftCashSales(
          active.shift.startTime.toIso8601String(),
          DateTime.now().toIso8601String(),
        );
        emit(active.copyWith(theoreticalCashSales: cashSales));
      } catch (e) {
        emit(ShiftError('Failed to update sales reading: ${e.toString()}'));
      }
    }
  }

  /// Step 4: Save Tender Declaration & Cash Drawer Count
  Future<void> saveTenderDeclaration(List<CashDenominationCount> denominations, double totalCash) async {
    if (state is ShiftActive) {
      final active = state as ShiftActive;
      try {
        await shiftDao.saveCashDeclaration(
          cashierId: active.shift.cashierId,
          totalCash: totalCash,
          changeFund: active.shift.beginningCash,
          denominations: denominations,
        );
        emit(
          active.copyWith(
            declaredCash: totalCash,
            denominations: denominations,
          ),
        );
      } catch (e) {
        emit(ShiftError('Failed to save cash declaration: ${e.toString()}'));
      }
    }
  }

  /// Step 5: X-Reading & Shift Logout
  Future<bool> finalizeXReadingAndCloseShift() async {
    if (state is ShiftActive) {
      final active = state as ShiftActive;
      try {
        await shiftDao.closeShift(
          shiftId: active.shift.id!,
          cashierId: active.shift.cashierId,
          beginningCash: active.shift.beginningCash,
          theoreticalCashSales: active.theoreticalCashSales,
          actualCashCount: active.declaredCash ?? 0.0,
        );
        emit(ShiftInactive());
        return true;
      } catch (e) {
        emit(ShiftError('Failed to close shift: ${e.toString()}'));
      }
    }
    return false;
  }
}
