import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/shift/cash_denomination_count.dart';
import 'package:suki_pos/domain/entities/shift/shift.dart';

class SalesEntryGuardResult extends Equatable {
  final bool canProceed;
  final String? blockTitle;
  final String? blockMessage;
  final bool redirectToSalesReading;
  final bool needsChangeFund;

  const SalesEntryGuardResult({
    required this.canProceed,
    this.blockTitle,
    this.blockMessage,
    this.redirectToSalesReading = false,
    this.needsChangeFund = false,
  });

  @override
  List<Object?> get props => [
        canProceed,
        blockTitle,
        blockMessage,
        redirectToSalesReading,
        needsChangeFund,
      ];
}

abstract class ShiftState extends Equatable {
  const ShiftState();

  @override
  List<Object?> get props => [];
}

class ShiftInitial extends ShiftState {}

class ShiftLoading extends ShiftState {}

/// No open shift for the current cashier (either before opening Change Fund,
/// or after completing X-Reading and ready for End-of-Day Z-Reading).
class ShiftInactive extends ShiftState {
  final Map<String, dynamic> zReadingData;
  final bool canRunZReading;
  final bool isZReadingDoneToday;
  final bool hasOpenOrders;
  final bool hasUnxReadRecords;
  final bool hasDayTenderDeclaration;
  final String? pendingCashierName;

  const ShiftInactive({
    this.zReadingData = const {},
    this.canRunZReading = false,
    this.isZReadingDoneToday = false,
    this.hasOpenOrders = false,
    this.hasUnxReadRecords = false,
    this.hasDayTenderDeclaration = false,
    this.pendingCashierName,
  });

  @override
  List<Object?> get props => [
        zReadingData,
        canRunZReading,
        isZReadingDoneToday,
        hasOpenOrders,
        hasUnxReadRecords,
        hasDayTenderDeclaration,
        pendingCashierName,
      ];
}

class ShiftClosed extends ShiftState {}

class ShiftActive extends ShiftState {
  final ShiftEntity shift;
  final double theoreticalCashSales;
  final double cashIn;
  final double cashOut;
  final double? declaredCash;
  final List<CashDenominationCount> denominations;
  final Map<String, dynamic> nonCashSummary;
  final Map<String, dynamic> xReadingData;
  final Map<String, dynamic> zReadingData;
  final List<Map<String, dynamic>> cashFundLogs;
  final bool hasOpenOrders;
  final bool shouldBlockTenderDecNoSales;

  const ShiftActive({
    required this.shift,
    this.theoreticalCashSales = 0.0,
    this.cashIn = 0.0,
    this.cashOut = 0.0,
    this.declaredCash,
    this.denominations = const [],
    this.nonCashSummary = const {},
    this.xReadingData = const {},
    this.zReadingData = const {},
    this.cashFundLogs = const [],
    this.hasOpenOrders = false,
    this.shouldBlockTenderDecNoSales = false,
  });

  double get expectedTotalCash =>
      shift.beginningCash + theoreticalCashSales + cashIn - cashOut;

  double get variance => (declaredCash ?? 0.0) - expectedTotalCash;

  ShiftActive copyWith({
    ShiftEntity? shift,
    double? theoreticalCashSales,
    double? cashIn,
    double? cashOut,
    double? declaredCash,
    List<CashDenominationCount>? denominations,
    Map<String, dynamic>? nonCashSummary,
    Map<String, dynamic>? xReadingData,
    Map<String, dynamic>? zReadingData,
    List<Map<String, dynamic>>? cashFundLogs,
    bool? hasOpenOrders,
    bool? shouldBlockTenderDecNoSales,
  }) {
    return ShiftActive(
      shift: shift ?? this.shift,
      theoreticalCashSales: theoreticalCashSales ?? this.theoreticalCashSales,
      cashIn: cashIn ?? this.cashIn,
      cashOut: cashOut ?? this.cashOut,
      declaredCash: declaredCash ?? this.declaredCash,
      denominations: denominations ?? this.denominations,
      nonCashSummary: nonCashSummary ?? this.nonCashSummary,
      xReadingData: xReadingData ?? this.xReadingData,
      zReadingData: zReadingData ?? this.zReadingData,
      cashFundLogs: cashFundLogs ?? this.cashFundLogs,
      hasOpenOrders: hasOpenOrders ?? this.hasOpenOrders,
      shouldBlockTenderDecNoSales:
          shouldBlockTenderDecNoSales ?? this.shouldBlockTenderDecNoSales,
    );
  }

  @override
  List<Object?> get props => [
        shift,
        theoreticalCashSales,
        cashIn,
        cashOut,
        declaredCash,
        denominations,
        nonCashSummary,
        xReadingData,
        zReadingData,
        cashFundLogs,
        hasOpenOrders,
        shouldBlockTenderDecNoSales,
      ];
}

class ShiftError extends ShiftState {
  final String message;
  const ShiftError(this.message);

  @override
  List<Object?> get props => [message];
}
