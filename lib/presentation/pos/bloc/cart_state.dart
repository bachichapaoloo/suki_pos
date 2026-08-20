import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';
import 'package:suki_pos/services/cart_calculator.dart';

class CartState extends Equatable {
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
  final String? remarks;
  final bool isSubmitting;
  final String? errorMessage;
  final int? completedOrderId;

  const CartState({
    this.items = const [],
    this.orderTypeId = 1,
    this.diningTableId,
    this.guestCount = 1,
    this.eligibleGuestCount = 0,
    this.manualDiscountPercentage = 0.0,
    this.manualDiscountFixed = 0.0,
    this.surchargeAmount = 0.0,
    this.surchargePercent = 0.0,
    this.appliedDiscount,
    this.remarks,
    this.isSubmitting = false,
    this.errorMessage,
    this.completedOrderId,
  });

  /// Computed financial & tax breakdown via CartCalculator
  TaxDiscountBreakdown get breakdown => CartCalculator.calculate(
        items: items,
        manualDiscountPercentage: manualDiscountPercentage,
        manualDiscountFixed: manualDiscountFixed,
        appliedDiscount: appliedDiscount,
        guestCount: guestCount,
        eligibleGuestCount: eligibleGuestCount,
        surchargeAmount: surchargeAmount,
      );

  CartState copyWith({
    List<CartItem>? items,
    int? orderTypeId,
    int? diningTableId,
    bool clearDiningTable = false,
    int? guestCount,
    int? eligibleGuestCount,
    double? manualDiscountPercentage,
    double? manualDiscountFixed,
    double? surchargeAmount,
    double? surchargePercent,
    Discount? appliedDiscount,
    bool clearAppliedDiscount = false,
    String? remarks,
    bool? isSubmitting,
    String? errorMessage,
    int? completedOrderId,
  }) {
    return CartState(
      items: items ?? this.items,
      orderTypeId: orderTypeId ?? this.orderTypeId,
      diningTableId: clearDiningTable ? null : (diningTableId ?? this.diningTableId),
      guestCount: guestCount ?? this.guestCount,
      eligibleGuestCount: eligibleGuestCount ?? this.eligibleGuestCount,
      manualDiscountPercentage: manualDiscountPercentage ?? this.manualDiscountPercentage,
      manualDiscountFixed: manualDiscountFixed ?? this.manualDiscountFixed,
      surchargeAmount: surchargeAmount ?? this.surchargeAmount,
      surchargePercent: surchargePercent ?? this.surchargePercent,
      appliedDiscount: clearAppliedDiscount ? null : (appliedDiscount ?? this.appliedDiscount),
      remarks: remarks ?? this.remarks,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      completedOrderId: completedOrderId,
    );
  }

  @override
  List<Object?> get props => [
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
        remarks,
        isSubmitting,
        errorMessage,
        completedOrderId,
      ];
}
