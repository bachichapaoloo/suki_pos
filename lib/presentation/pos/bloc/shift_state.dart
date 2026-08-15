import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/shift/cash_denomination_count.dart';
import 'package:suki_pos/domain/entities/shift/shift.dart';

abstract class ShiftState extends Equatable {
  const ShiftState();

  @override
  List<Object?> get props => [];
}

class ShiftInitial extends ShiftState {}

class ShiftLoading extends ShiftState {}

class ShiftInactive extends ShiftState {} // No open shift

class ShiftActive extends ShiftState {
  final ShiftEntity shift;
  final double theoreticalCashSales;
  final double? declaredCash;
  final List<CashDenominationCount> denominations;

  const ShiftActive({
    required this.shift,
    this.theoreticalCashSales = 0.0,
    this.declaredCash,
    this.denominations = const [],
  });

  double get expectedTotalCash => shift.beginningCash + theoreticalCashSales;
  double get variance => (declaredCash ?? 0.0) - expectedTotalCash;

  ShiftActive copyWith({
    ShiftEntity? shift,
    double? theoreticalCashSales,
    double? declaredCash,
    List<CashDenominationCount>? denominations,
  }) {
    return ShiftActive(
      shift: shift ?? this.shift,
      theoreticalCashSales: theoreticalCashSales ?? this.theoreticalCashSales,
      declaredCash: declaredCash ?? this.declaredCash,
      denominations: denominations ?? this.denominations,
    );
  }

  @override
  List<Object?> get props => [shift, theoreticalCashSales, declaredCash, denominations];
}

class ShiftError extends ShiftState {
  final String message;
  const ShiftError(this.message);

  @override
  List<Object?> get props => [message];
}
