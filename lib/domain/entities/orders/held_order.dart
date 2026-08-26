import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';

class HeldOrder extends Equatable {
  final String id;
  final String orderLabel; // e.g. "Table 4" or "Customer John" or "Order #3"
  final List<CartItem> items;
  final int orderTypeId;
  final int? diningTableId;
  final int guestCount;
  final int eligibleGuestCount;
  final double manualDiscountPercentage;
  final double manualDiscountFixed;
  final double surchargeAmount;
  final double surchargePercent;
  final Discount? appliedDiscount;
  final String? beneficiaryName;
  final String? beneficiaryIdNo;
  final String? remarks;
  final DateTime heldAt;

  const HeldOrder({
    required this.id,
    required this.orderLabel,
    required this.items,
    this.orderTypeId = 1,
    this.diningTableId,
    this.guestCount = 1,
    this.eligibleGuestCount = 0,
    this.manualDiscountPercentage = 0.0,
    this.manualDiscountFixed = 0.0,
    this.surchargeAmount = 0.0,
    this.surchargePercent = 0.0,
    this.appliedDiscount,
    this.beneficiaryName,
    this.beneficiaryIdNo,
    this.remarks,
    required this.heldAt,
  });

  double get grossSubtotal => items.fold(0.0, (sum, i) => sum + i.effectiveTotalPrice);
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [
        id,
        orderLabel,
        items,
        orderTypeId,
        diningTableId,
        guestCount,
        eligibleGuestCount,
        manualDiscountPercentage,
        manualDiscountFixed,
        surchargeAmount,
        surchargePercent,
        appliedDiscount,
        beneficiaryName,
        beneficiaryIdNo,
        remarks,
        heldAt,
      ];
}
