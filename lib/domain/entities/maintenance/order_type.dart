import 'package:equatable/equatable.dart';

class OrderType extends Equatable {
  final int id;
  final String name;
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

  @override
  List<Object?> get props => [
    id,
    name,
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
