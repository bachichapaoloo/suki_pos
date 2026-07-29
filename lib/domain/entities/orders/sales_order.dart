import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';

class SalesOrderAggregate extends Equatable {
  final int? id;
  final int? diningTableId;
  final int orderTypeId;
  final int cashierId;
  final int guestCount;
  final List<CartItem> items;
  final int paymentStatus;
  final String? remarks;
  final DateTime createdAt;

  const SalesOrderAggregate({
    this.id,
    this.diningTableId,
    required this.orderTypeId,
    required this.cashierId,
    this.guestCount = 1,
    required this.items,
    this.paymentStatus = 0,
    this.remarks,
    required this.createdAt,
  });

  double get grossAmount => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  @override
  List<Object?> get props => [
    id,
    diningTableId,
    orderTypeId,
    cashierId,
    guestCount,
    items,
    paymentStatus,
    remarks,
    createdAt,
  ];
}
