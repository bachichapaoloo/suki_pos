import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/held_order.dart';
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';
import 'package:suki_pos/services/cart_calculator.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final int orderTypeId;
  final int? diningTableId;
  final String? tableName;
  final String? customerName;
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
  final List<HeldOrder> heldOrders;
  final bool isSubmitting;
  final String? errorMessage;
  final int? completedOrderId;

  const CartState({
    this.items = const [],
    this.orderTypeId = 1,
    this.diningTableId,
    this.tableName,
    this.customerName,
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
    this.heldOrders = const [],
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
    String? tableName,
    bool clearTableName = false,
    String? customerName,
    bool clearCustomerName = false,
    int? guestCount,
    int? eligibleGuestCount,
    double? manualDiscountPercentage,
    double? manualDiscountFixed,
    double? surchargeAmount,
    double? surchargePercent,
    Discount? appliedDiscount,
    bool clearAppliedDiscount = false,
    String? beneficiaryName,
    String? beneficiaryIdNo,
    bool clearBeneficiary = false,
    String? remarks,
    bool clearRemarks = false,
    List<HeldOrder>? heldOrders,
    bool? isSubmitting,
    String? errorMessage,
    int? completedOrderId,
  }) {
    return CartState(
      items: items ?? this.items,
      orderTypeId: orderTypeId ?? this.orderTypeId,
      diningTableId: clearDiningTable ? null : (diningTableId ?? this.diningTableId),
      tableName: clearTableName ? null : (tableName ?? this.tableName),
      customerName: clearCustomerName ? null : (customerName ?? this.customerName),
      guestCount: guestCount ?? this.guestCount,
      eligibleGuestCount: eligibleGuestCount ?? this.eligibleGuestCount,
      manualDiscountPercentage: manualDiscountPercentage ?? this.manualDiscountPercentage,
      manualDiscountFixed: manualDiscountFixed ?? this.manualDiscountFixed,
      surchargeAmount: surchargeAmount ?? this.surchargeAmount,
      surchargePercent: surchargePercent ?? this.surchargePercent,
      appliedDiscount: clearAppliedDiscount ? null : (appliedDiscount ?? this.appliedDiscount),
      beneficiaryName: clearBeneficiary ? null : (beneficiaryName ?? this.beneficiaryName),
      beneficiaryIdNo: clearBeneficiary ? null : (beneficiaryIdNo ?? this.beneficiaryIdNo),
      remarks: clearRemarks ? null : (remarks ?? this.remarks),
      heldOrders: heldOrders ?? this.heldOrders,
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
        tableName,
        customerName,
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
        heldOrders,
        isSubmitting,
        errorMessage,
        completedOrderId,
      ];
}
