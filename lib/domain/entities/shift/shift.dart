import 'package:equatable/equatable.dart';

class ShiftEntity extends Equatable {
  final int? id;
  final int cashierId;
  final double beginningCash;
  final double? endingCash;
  final double? cashVariance;
  final int status; // 1 = Open, 2 = Closed
  final DateTime startTime;
  final DateTime? endTime;

  const ShiftEntity({
    this.id,
    required this.cashierId,
    required this.beginningCash,
    this.endingCash,
    this.cashVariance,
    this.status = 1,
    required this.startTime,
    this.endTime,
  });

  bool get isOpen => status == 1;

  @override
  List<Object?> get props => [id, cashierId, beginningCash, endingCash, cashVariance, status, startTime, endTime];
}
