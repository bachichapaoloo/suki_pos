import 'package:suki_pos/domain/entities/maintenance/order_type.dart';

class OrderTypeModel extends OrderType {
  const OrderTypeModel({
    required super.id,
    required super.name,
    super.hasServiceCharge = true,
    super.askGuestCount = false,
    super.askRefNo = false,
    super.isRental = false,
    super.isDelivery = false,
    super.isKiosk = false,
    super.noSurcharge = false,
    super.surChargeFormula = false,
    super.priceLevel = 'DEFAULT',
    super.requiresPassword = false,
    super.additionalPercentage = 0.0,
    super.printAdditionalCopy = false,
  });

  factory OrderTypeModel.fromMap(Map<String, dynamic> map) {
    return OrderTypeModel(
      id: map['id'] as int,
      name: map['name'] as String,
      hasServiceCharge: map['has_service_charge'] == null || map['has_service_charge'] == 1,
      askGuestCount: map['ask_guest_count'] == 1,
      askRefNo: map['ask_ref_no'] == 1,
      isRental: map['is_rental'] == 1,
      isDelivery: map['is_delivery'] == 1,
      isKiosk: map['is_kiosk'] == 1,
      noSurcharge: map['no_surcharge'] == 1,
      surChargeFormula: map['surcharge_formula'] == 1 || map['sur_charge_formula'] == 1,
      priceLevel: (map['price_level'] ?? 'DEFAULT') as String,
      requiresPassword: map['requires_password'] == 1,
      additionalPercentage: (map['additional_percentage'] is num) ? (map['additional_percentage'] as num).toDouble() : 0.0,
      printAdditionalCopy: map['print_additional_copy'] == 1,
    );
  }

  factory OrderTypeModel.fromEntity(OrderType entity) {
    return OrderTypeModel(
      id: entity.id,
      name: entity.name,
      hasServiceCharge: entity.hasServiceCharge,
      askGuestCount: entity.askGuestCount,
      askRefNo: entity.askRefNo,
      isRental: entity.isRental,
      isDelivery: entity.isDelivery,
      isKiosk: entity.isKiosk,
      noSurcharge: entity.noSurcharge,
      surChargeFormula: entity.surChargeFormula,
      priceLevel: entity.priceLevel,
      requiresPassword: entity.requiresPassword,
      additionalPercentage: entity.additionalPercentage,
      printAdditionalCopy: entity.printAdditionalCopy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'has_service_charge': hasServiceCharge ? 1 : 0,
      'ask_guest_count': askGuestCount ? 1 : 0,
      'ask_ref_no': askRefNo ? 1 : 0,
      'is_rental': isRental ? 1 : 0,
      'is_delivery': isDelivery ? 1 : 0,
      'is_kiosk': isKiosk ? 1 : 0,
      'no_surcharge': noSurcharge ? 1 : 0,
      'surcharge_formula': surChargeFormula ? 1 : 0,
      'price_level': priceLevel,
      'requires_password': requiresPassword ? 1 : 0,
      'additional_percentage': additionalPercentage,
      'print_additional_copy': printAdditionalCopy ? 1 : 0,
    };
  }
}
