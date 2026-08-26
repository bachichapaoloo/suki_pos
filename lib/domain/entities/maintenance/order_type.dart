import 'package:equatable/equatable.dart';

class OrderType extends Equatable {
  final int id;
  final String name;
  final bool hasServiceCharge;
  final bool askGuestCount;
  final bool askRefNo;
  final bool isRental;
  final bool isDelivery;
  final bool isKiosk;
  final bool noSurcharge;
  final bool surChargeFormula;
  final String priceLevel;
  final bool requiresPassword;
  final double additionalPercentage;
  final bool printAdditionalCopy;

  const OrderType({
    required this.id,
    required this.name,
    this.hasServiceCharge = true,
    this.askGuestCount = false,
    this.askRefNo = false,
    this.isRental = false,
    this.isDelivery = false,
    this.isKiosk = false,
    this.noSurcharge = false,
    this.surChargeFormula = false,
    this.priceLevel = 'DEFAULT',
    this.requiresPassword = false,
    this.additionalPercentage = 0.0,
    this.printAdditionalCopy = false,
  });

  OrderType copyWith({
    int? id,
    String? name,
    bool? hasServiceCharge,
    bool? askGuestCount,
    bool? askRefNo,
    bool? isRental,
    bool? isDelivery,
    bool? isKiosk,
    bool? noSurcharge,
    bool? surChargeFormula,
    String? priceLevel,
    bool? requiresPassword,
    double? additionalPercentage,
    bool? printAdditionalCopy,
  }) {
    return OrderType(
      id: id ?? this.id,
      name: name ?? this.name,
      hasServiceCharge: hasServiceCharge ?? this.hasServiceCharge,
      askGuestCount: askGuestCount ?? this.askGuestCount,
      askRefNo: askRefNo ?? this.askRefNo,
      isRental: isRental ?? this.isRental,
      isDelivery: isDelivery ?? this.isDelivery,
      isKiosk: isKiosk ?? this.isKiosk,
      noSurcharge: noSurcharge ?? this.noSurcharge,
      surChargeFormula: surChargeFormula ?? this.surChargeFormula,
      priceLevel: priceLevel ?? this.priceLevel,
      requiresPassword: requiresPassword ?? this.requiresPassword,
      additionalPercentage: additionalPercentage ?? this.additionalPercentage,
      printAdditionalCopy: printAdditionalCopy ?? this.printAdditionalCopy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        hasServiceCharge,
        askGuestCount,
        askRefNo,
        isRental,
        isDelivery,
        isKiosk,
        noSurcharge,
        surChargeFormula,
        priceLevel,
        requiresPassword,
        additionalPercentage,
        printAdditionalCopy,
      ];
}
