import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/option_value.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/sales_order.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';
import 'package:suki_pos/domain/use_cases/orders/process_checkout.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_state.dart';
import 'package:uuid/uuid.dart';

class CartCubit extends Cubit<CartState> {
  final ProcessCheckout processCheckout;
  final _uuid = const Uuid();

  CartCubit({required this.processCheckout}) : super(const CartState());

  void addItem({
    required Item item,
    List<OptionValue> selectedOptions = const [],
    int quantity = 1,
    String? notes,
  }) {
    final existingIndex = state.items.indexWhere(
      (c) => c.item.id == item.id && _areOptionsEqual(c.selectedOptions, selectedOptions) && c.notes == notes,
    );

    if (existingIndex != -1) {
      final updatedList = List<CartItem>.from(state.items);
      final existing = updatedList[existingIndex];
      updatedList[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
      emit(state.copyWith(items: updatedList));
    } else {
      final newItem = CartItem(
        id: _uuid.v4(),
        item: item,
        selectedOptions: selectedOptions,
        quantity: quantity,
        notes: notes,
      );
      emit(state.copyWith(items: [...state.items, newItem]));
    }
  }

  /// Updates an existing line item in the cart (e.g., when editing options or quantity)
  void updateCartItem(String cartItemId, CartItem updatedItem) {
    final updatedList = state.items.map((cartItem) {
      return cartItem.id == cartItemId ? updatedItem : cartItem;
    }).toList();

    emit(state.copyWith(items: updatedList));
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

  void applyDiscountPercentage(double percent) {
    emit(
      state.copyWith(
        manualDiscountPercentage: percent,
        manualDiscountFixed: 0.0,
      ),
    );
  }

  void applyDiscountFixed(double amount) {
    emit(
      state.copyWith(
        manualDiscountFixed: amount,
        manualDiscountPercentage: 0.0,
      ),
    );
  }

  void removeDiscount() {
    emit(
      state.copyWith(
        manualDiscountPercentage: 0.0,
        manualDiscountFixed: 0.0,
      ),
    );
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

  Future<TransactionDetail?> submitOrder({
    required int cashierId,
    required int paymentMethodId,
    required double cashTendered,
  }) async {
    if (state.items.isEmpty) return null;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final order = SalesOrderAggregate(
      orderTypeId: state.orderTypeId,
      cashierId: cashierId,
      guestCount: state.guestCount,
      items: state.items,
      remarks: state.remarks,
      createdAt: DateTime.now(),
    );

    final breakdown = state.breakdown;
    final totalAmount = breakdown.netTotal;
    final changeGiven = cashTendered - totalAmount;

    final result = await processCheckout(
      order: order,
      paymentMethodId: paymentMethodId,
      cashTendered: cashTendered,
      changeGiven: changeGiven >= 0 ? changeGiven : 0.0,
    );

    return result.fold(
      (failure) {
        final errorMsg = failure is DatabaseFailure && failure.message.isNotEmpty
            ? failure.message
            : 'Failed to process checkout';
        emit(state.copyWith(isSubmitting: false, errorMessage: errorMsg));
        return null;
      },
      (txnId) {
        final completedDetail = TransactionDetail(
          transactionId: txnId,
          salesOrderId: 0,
          transactionNo: 'TXN-${txnId.toString().padLeft(6, '0')}',
          grossAmount: breakdown.grossSubtotal,
          netAmount: breakdown.netTotal,
          cashTendered: cashTendered,
          changeGiven: changeGiven >= 0 ? changeGiven : 0.0,
          paymentMethodName: paymentMethodId == 1 ? 'Cash' : (paymentMethodId == 2 ? 'Card' : 'E-Wallet'),
          cashierName: 'Admin',
          orderTypeName: state.orderTypeId == 1 ? 'Dine-In' : 'Take-Out',
          guestCount: state.guestCount,
          transactionDate: DateTime.now(),
          lines: state.items
              .map(
                (item) => TransactionLineDetail(
                  itemId: item.item.id ?? 0,
                  itemName: item.item.name,
                  barcode: item.item.barcode ?? item.item.itemCode,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  amount: item.totalPrice,
                  selectedOptions: item.selectedOptions.map((o) => o.alias ?? '').toList(),
                ),
              )
              .toList(),
        );

        emit(state.copyWith(isSubmitting: false, completedOrderId: txnId));
        clearCart();
        return completedDetail;
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
