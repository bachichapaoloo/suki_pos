import 'package:equatable/equatable.dart';

class ServiceChargeConfig extends Equatable {
  final int id;
  final double ratePercent;
  final bool isActive;
  final bool computeBeforeDiscount; // true = % of Gross Subtotal; false = % of Net Subtotal (after discount)

  const ServiceChargeConfig({
    this.id = 1,
    this.ratePercent = 10.0,
    this.isActive = true,
    this.computeBeforeDiscount = true,
  });

  ServiceChargeConfig copyWith({
    int? id,
    double? ratePercent,
    bool? isActive,
    bool? computeBeforeDiscount,
  }) {
    return ServiceChargeConfig(
      id: id ?? this.id,
      ratePercent: ratePercent ?? this.ratePercent,
      isActive: isActive ?? this.isActive,
      computeBeforeDiscount: computeBeforeDiscount ?? this.computeBeforeDiscount,
    );
  }

  @override
  List<Object?> get props => [id, ratePercent, isActive, computeBeforeDiscount];
}
