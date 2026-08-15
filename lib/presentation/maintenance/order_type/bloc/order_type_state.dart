import 'package:suki_pos/domain/entities/maintenance/order_type.dart';

abstract class OrderTypeState {}

class OrderTypeInitial extends OrderTypeState {}

class OrderTypeLoading extends OrderTypeState {}

class OrderTypeLoaded extends OrderTypeState {
  final List<OrderType> orderTypes;

  OrderTypeLoaded({required this.orderTypes});
}

class OrderTypeError extends OrderTypeState {
  final String message;

  OrderTypeError({required this.message});
}
