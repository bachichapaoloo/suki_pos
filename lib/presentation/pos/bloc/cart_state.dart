import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final int orderTypeId;
  final int guestCount;
  final String? remarks;
  final bool isSubmitting;
  final String? errorMessage;
  final int? completedOrderId;

  const CartState({
    this.items = const [],
    this.orderTypeId = 1,
    this.guestCount = 1,
    this.remarks,
    this.isSubmitting = false,
    this.errorMessage,
    this.completedOrderId,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalTax => 0.0; // Expandable for VAT calculation
  double get totalAmount => subtotal + totalTax;
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    int? orderTypeId,
    int? guestCount,
    String? remarks,
    bool? isSubmitting,
    String? errorMessage,
    int? completedOrderId,
  }) {
    return CartState(
      items: items ?? this.items,
      orderTypeId: orderTypeId ?? this.orderTypeId,
      guestCount: guestCount ?? this.guestCount,
      remarks: remarks ?? this.remarks,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      completedOrderId: completedOrderId ?? this.completedOrderId,
    );
  }

  @override
  List<Object?> get props => [
    items,
    orderTypeId,
    guestCount,
    remarks,
    isSubmitting,
    errorMessage,
    completedOrderId,
  ];
}
