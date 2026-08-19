import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';
import 'package:suki_pos/services/cart_calculator.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final int orderTypeId;
  final int guestCount;
  final double manualDiscountPercentage;
  final double manualDiscountFixed;
  final Discount? appliedDiscount;
  final String? remarks;
  final bool isSubmitting;
  final String? errorMessage;
  final int? completedOrderId;

  const CartState({
    this.items = const [],
    this.orderTypeId = 1,
    this.guestCount = 1,
    this.manualDiscountPercentage = 0.0,
    this.manualDiscountFixed = 0.0,
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
  );

  CartState copyWith({
    List<CartItem>? items,
    int? orderTypeId,
    int? guestCount,
    double? manualDiscountPercentage,
    double? manualDiscountFixed,
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
      guestCount: guestCount ?? this.guestCount,
      manualDiscountPercentage: manualDiscountPercentage ?? this.manualDiscountPercentage,
      manualDiscountFixed: manualDiscountFixed ?? this.manualDiscountFixed,
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
    guestCount,
    manualDiscountPercentage,
    manualDiscountFixed,
    appliedDiscount,
    remarks,
    isSubmitting,
    errorMessage,
    completedOrderId,
  ];
}
