import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';

class SalesOrderAggregate extends Equatable {
  final int? id;
  final int? diningTableId;
  final int orderTypeId;
  final int cashierId;
  final int guestCount;
  final int eligibleGuestCount;
  final List<CartItem> items;
  final int? discountId;
  final double discPercentage;
  final double discFixedAmount;
  final double surchargeAmount;
  final double surchargePercent;
  final int paymentStatus;
  final String? beneficiaryName;
  final String? beneficiaryIdNo;
  final int? beneficiaryDiscountTypeId;
  final String? remarks;
  final DateTime createdAt;

  const SalesOrderAggregate({
    this.id,
    this.diningTableId,
    required this.orderTypeId,
    required this.cashierId,
    this.guestCount = 1,
    this.eligibleGuestCount = 0,
    required this.items,
    this.discountId,
    this.discPercentage = 0.0,
    this.discFixedAmount = 0.0,
    this.surchargeAmount = 0.0,
    this.surchargePercent = 0.0,
    this.paymentStatus = 0,
    this.beneficiaryName,
    this.beneficiaryIdNo,
    this.beneficiaryDiscountTypeId,
    this.remarks,
    required this.createdAt,
  });

  double get grossAmount => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get effectiveAmount => items.fold(0.0, (sum, item) => sum + item.effectiveTotalPrice);

  @override
  List<Object?> get props => [
        id,
        diningTableId,
        orderTypeId,
        cashierId,
        guestCount,
        eligibleGuestCount,
        items,
        discountId,
        discPercentage,
        discFixedAmount,
        surchargeAmount,
        surchargePercent,
        paymentStatus,
        beneficiaryName,
        beneficiaryIdNo,
        beneficiaryDiscountTypeId,
        remarks,
        createdAt,
      ];
}
