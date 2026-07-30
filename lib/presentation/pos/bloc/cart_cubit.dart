import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../domain/entities/maintenance/item.dart';
import '../../../../domain/entities/maintenance/option_value.dart';
import '../../../../domain/entities/orders/cart_item.dart';
import '../../../../domain/entities/orders/sales_order.dart';
import '../../../../domain/use_cases/orders/process_checkout.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final ProcessCheckout processCheckout;
  final _uuid = const Uuid();

  CartCubit({required this.processCheckout}) : super(const CartState());

  void addItem(Item item, {List<OptionValue> selectedOptions = const [], String? notes}) {
    final existingIndex = state.items.indexWhere(
      (c) => c.item.id == item.id && _areOptionsEqual(c.selectedOptions, selectedOptions) && c.notes == notes,
    );

    if (existingIndex != -1) {
      final updatedList = List<CartItem>.from(state.items);
      final existing = updatedList[existingIndex];
      updatedList[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
      emit(state.copyWith(items: updatedList));
    } else {
      final newItem = CartItem(
        id: _uuid.v4(),
        item: item,
        selectedOptions: selectedOptions,
        quantity: 1,
        notes: notes,
      );
      emit(state.copyWith(items: [...state.items, newItem]));
    }
  }

  void updateQuantity(String cartItemId, int delta) {
    final updatedList = state.items
        .map((cartItem) {
          if (cartItem.id == cartItemId) {
            final newQty = cartItem.quantity + delta;
            return newQty > 0 ? cartItem.copyWith(quantity: newQty) : null;
          }
          return cartItem;
        })
        .whereType<CartItem>()
        .toList();

    emit(state.copyWith(items: updatedList));
  }

  void removeItem(String cartItemId) {
    final updatedList = state.items.where((item) => item.id != cartItemId).toList();
    emit(state.copyWith(items: updatedList));
  }

  void setOrderType(int typeId) => emit(state.copyWith(orderTypeId: typeId));
  void setGuestCount(int count) => emit(state.copyWith(guestCount: count));

  void clearCart() {
    emit(
      CartState(
        orderTypeId: state.orderTypeId,
        guestCount: state.guestCount,
      ),
    );
  }

  Future<bool> submitOrder({
    required int cashierId,
    required int paymentMethodId,
    required double cashTendered,
  }) async {
    if (state.items.isEmpty) return false;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final order = SalesOrderAggregate(
      orderTypeId: state.orderTypeId,
      cashierId: cashierId,
      guestCount: state.guestCount,
      items: state.items,
      remarks: state.remarks,
      createdAt: DateTime.now(),
    );

    final changeGiven = cashTendered - state.totalAmount;

    final result = await processCheckout(
      order: order,
      paymentMethodId: paymentMethodId,
      cashTendered: cashTendered,
      changeGiven: changeGiven >= 0 ? changeGiven : 0.0,
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(isSubmitting: false, errorMessage: 'Failed to process checkout'));
        return false;
      },
      (orderId) {
        emit(state.copyWith(isSubmitting: false, completedOrderId: orderId));
        clearCart();
        return true;
      },
    );
  }

  bool _areOptionsEqual(List<OptionValue> list1, List<OptionValue> list2) {
    if (list1.length != list2.length) return false;
    final ids1 = list1.map((e) => e.id).toSet();
    final ids2 = list2.map((e) => e.id).toSet();
    return ids1.difference(ids2).isEmpty;
  }
}
