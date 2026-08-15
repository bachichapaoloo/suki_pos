import 'package:equatable/equatable.dart';

class CashDenominationCount extends Equatable {
  final double denomination; // e.g., 1000.0, 500.0, 200.0, 100.0, 50.0, 20.0, 10.0, 5.0, 1.0, 0.25
  final int count;

  const CashDenominationCount({
    required this.denomination,
    required this.count,
  });

  double get total => denomination * count;

  @override
  List<Object?> get props => [denomination, count];
}
