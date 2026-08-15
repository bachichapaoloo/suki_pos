import 'package:suki_pos/domain/entities/maintenance/order_type.dart';

class OrderTypeModel extends OrderType {
  OrderTypeModel({
    required super.id,
    required super.name,
    required super.askGuestCount,
    required super.askRefNo,
    required super.isRental,
    required super.isDelivery,
    required super.isKiosk,
    required super.noSurcharge,
    required super.surChargeFormula,
    required super.priceLevel,
    required super.requiresPassword,
    required super.additionalPercentage,
    required super.printAdditionalCopy,
  });

  factory OrderTypeModel.fromMap(Map<String, dynamic> map) {
    return OrderTypeModel(
      id: map['id'] as int,
      name: map['name'] as String,
      askGuestCount: map['ask_guest_count'] == 1,
      askRefNo: map['ask_ref_no'] == 1,
      isRental: map['is_rental'] == 1,
      isDelivery: map['is_delivery'] == 1,
      isKiosk: map['is_kiosk'] == 1,
      noSurcharge: map['no_surcharge'] == 1,
      surChargeFormula: map['sur_charge_formula'] == 1,
      priceLevel: (map['price_level'] ?? 'DEFAULT') as String,
      requiresPassword: map['requires_password'] == 1,
      additionalPercentage: (map['additional_percentage'] ?? 0.0) as double,
      printAdditionalCopy: map['print_additional_copy'] == 1,
    );
  }

  factory OrderTypeModel.fromEntity(OrderType entity) {
    return OrderTypeModel(
      id: entity.id,
      name: entity.name,
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
      'print_additional_copy': printAdditionalCopy,
    };
  }
}
