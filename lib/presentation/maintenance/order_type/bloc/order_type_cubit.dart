import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/domain/entities/maintenance/order_type.dart';
import 'package:suki_pos/domain/use_cases/maintenance/order_type_use_cases.dart';
import 'package:suki_pos/presentation/maintenance/order_type/bloc/order_type_state.dart';

class OrderTypeCubit extends Cubit<OrderTypeState> {
  OrderTypeCubit({
    required this.getOrderTypes,
    required this.getOrderTypeById,
    required this.saveOrderType,
    required this.deleteOrderType,
  }) : super(OrderTypeInitial());

  final GetOrderTypes getOrderTypes;
  final SaveOrderType saveOrderType;
  final DeleteOrderType deleteOrderType;
  final GetOrderTypeById getOrderTypeById;

  Future<bool> loadOrderTypes() async {
    emit(OrderTypeLoading());
    final result = await getOrderTypes();
    return result.fold(
      (failure) => false,
      (orderTypes) {
        emit(OrderTypeLoaded(orderTypes: orderTypes));
        return true;
      },
    );
  }

  Future<OrderType?> loadOrderTypeById(int id) async {
    final result = await getOrderTypeById(id);
    return result.fold(
      (failure) => null,
      (orderType) => orderType,
    );
  }

  Future<bool> save(OrderType orderType) async {
    final result = await saveOrderType(orderType);
    return result.fold(
      (failure) {
        emit(OrderTypeError(message: 'Failed to save order type'));
        return false;
      },
      (_) {
        loadOrderTypes();
        return true;
      },
    );
  }

  Future<bool> delete(int id) async {
    final result = await deleteOrderType(id);
    return result.fold(
      (failure) {
        emit(OrderTypeError(message: 'Failed to delete order type'));
        return false;
      },
      (_) {
        loadOrderTypes();
        return true;
      },
    );
  }
}
