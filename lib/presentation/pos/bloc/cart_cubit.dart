import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/option_value.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/held_order.dart';
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
      (c) =>
          c.item.id == item.id &&
          _areOptionsEqual(c.selectedOptions, selectedOptions) &&
          c.notes == notes &&
          !c.hasItemDiscount &&
          !c.isDiscountExempt,
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
        isDiscountExempt: item.isDiscountExempt,
      );
      emit(state.copyWith(items: [...state.items, newItem]));
    }
  }

  /// Updates an existing line item in the cart
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

  // -------------------------------------------------------------
  // ITEM-LEVEL DISCOUNT & EXEMPTION FEATURES
  // -------------------------------------------------------------

  /// Toggles whether a specific item line is exempt from order-level discounts
  void toggleItemDiscountExempt(String cartItemId) {
    final updatedList = state.items.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(isDiscountExempt: !item.isDiscountExempt);
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updatedList));
  }

  /// Toggles 100% complimentary / Free Item on a specific cart line
  void toggleItemFree(String cartItemId) {
    final updatedList = state.items.map((item) {
      if (item.id == cartItemId) {
        final makeFree = !item.isFreeItem;
        return item.copyWith(
          isFreeItem: makeFree,
          itemDiscountAmount: makeFree ? 0.0 : item.itemDiscountAmount,
          itemDiscountPercent: makeFree ? 0.0 : item.itemDiscountPercent,
        );
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updatedList));
  }

  /// Applies a line-level percentage or fixed amount discount to a specific cart line
  void applyLineItemDiscount(String cartItemId, {double? percent, double? fixedAmount}) {
    final updatedList = state.items.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(
          isFreeItem: false,
          itemDiscountPercent: percent ?? 0.0,
          itemDiscountAmount: fixedAmount ?? 0.0,
        );
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updatedList));
  }

  /// Clears any line-level discount from a specific cart line
  void removeItemDiscount(String cartItemId) {
    final updatedList = state.items.map((item) {
      if (item.id == cartItemId) {
        return item.copyWith(
          isFreeItem: false,
          itemDiscountAmount: 0.0,
          itemDiscountPercent: 0.0,
        );
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updatedList));
  }

  // -------------------------------------------------------------
  // ORDER-LEVEL DISCOUNTS & METADATA
  // -------------------------------------------------------------

  void applyDiscount(
    Discount discount, {
    String? idNumber,
    String? cardholderName,
    int? guestCount,
    int? eligibleCount,
  }) {
    emit(
      state.copyWith(
        appliedDiscount: discount,
        manualDiscountPercentage: discount.isPercentage ? (discount.percentage ?? 0.0) : 0.0,
        manualDiscountFixed: !discount.isPercentage ? (discount.fixedAmount ?? 0.0) : 0.0,
        beneficiaryIdNo: idNumber,
        beneficiaryName: cardholderName,
        guestCount: guestCount ?? state.guestCount,
        eligibleGuestCount: eligibleCount ?? state.eligibleGuestCount,
      ),
    );
  }

  void applyDiscountPercentage(double percent) {
    emit(
      state.copyWith(
        clearAppliedDiscount: true,
        clearBeneficiary: true,
        manualDiscountPercentage: percent,
        manualDiscountFixed: 0.0,
      ),
    );
  }

  void applyDiscountFixed(double amount) {
    emit(
      state.copyWith(
        clearAppliedDiscount: true,
        clearBeneficiary: true,
        manualDiscountFixed: amount,
        manualDiscountPercentage: 0.0,
      ),
    );
  }

  void removeDiscount() {
    emit(
      state.copyWith(
        clearAppliedDiscount: true,
        clearBeneficiary: true,
        manualDiscountPercentage: 0.0,
        manualDiscountFixed: 0.0,
      ),
    );
  }

  void setBeneficiary({required String name, required String idNumber}) {
    emit(state.copyWith(beneficiaryName: name, beneficiaryIdNo: idNumber));
  }

  void setCustomerName(String? name) {
    emit(state.copyWith(customerName: name, clearCustomerName: name == null || name.isEmpty));
  }

  void setTableName(String? tableName, {int? tableId}) {
    emit(
      state.copyWith(
        tableName: tableName,
        diningTableId: tableId,
        clearTableName: tableName == null || tableName.isEmpty,
        clearDiningTable: tableId == null,
      ),
    );
  }

  void setOrderType(int typeId) => emit(state.copyWith(orderTypeId: typeId));
  void setDiningTable(int? tableId) => emit(state.copyWith(diningTableId: tableId, clearDiningTable: tableId == null));
  void setGuestCount(int count) => emit(state.copyWith(guestCount: count));
  void setEligibleGuestCount(int count) => emit(state.copyWith(eligibleGuestCount: count));
  void setRemarks(String remarks) => emit(state.copyWith(remarks: remarks));

  void setSurcharge({required double amount, double percent = 0.0}) {
    emit(state.copyWith(surchargeAmount: amount, surchargePercent: percent));
  }

  void setServiceChargeConfig({
    required double ratePercent,
    required bool isActive,
    required bool computeBeforeDiscount,
  }) {
    emit(
      state.copyWith(
        serviceChargeRate: ratePercent,
        isServiceChargeActive: isActive,
        computeServiceChargeBeforeDiscount: computeBeforeDiscount,
      ),
    );
  }

  void toggleServiceChargeWaived() {
    emit(state.copyWith(isServiceChargeWaived: !state.isServiceChargeWaived));
  }

  void setServiceChargeWaived(bool waived) {
    emit(state.copyWith(isServiceChargeWaived: waived));
  }

  // -------------------------------------------------------------
  // HOLD / SUSPEND & RECALL ORDER SYSTEM
  // -------------------------------------------------------------

  /// Holds the current cart as a parked/suspended order
  String? holdCurrentOrder({String? label}) {
    if (state.items.isEmpty) return null;

    final heldId = _uuid.v4();
    final defaultLabel =
        label ??
        (state.tableName != null && state.tableName!.isNotEmpty
            ? state.tableName!
            : (state.customerName != null && state.customerName!.isNotEmpty
                  ? state.customerName!
                  : 'Order #${state.heldOrders.length + 1}'));

    final heldOrder = HeldOrder(
      id: heldId,
      orderLabel: defaultLabel,
      items: state.items,
      orderTypeId: state.orderTypeId,
      diningTableId: state.diningTableId,
      guestCount: state.guestCount,
      eligibleGuestCount: state.eligibleGuestCount,
      manualDiscountPercentage: state.manualDiscountPercentage,
      manualDiscountFixed: state.manualDiscountFixed,
      surchargeAmount: state.surchargeAmount,
      surchargePercent: state.surchargePercent,
      appliedDiscount: state.appliedDiscount,
      beneficiaryName: state.beneficiaryName,
      beneficiaryIdNo: state.beneficiaryIdNo,
      remarks: state.remarks,
      heldAt: DateTime.now(),
    );

    final updatedHeldList = [...state.heldOrders, heldOrder];

    // Clear active cart while preserving held orders list
    emit(
      CartState(
        orderTypeId: state.orderTypeId,
        heldOrders: updatedHeldList,
      ),
    );

    return heldId;
  }

  /// Recalls a held order and loads it into active cart
  void recallHeldOrder(String heldOrderId) {
    final matchIndex = state.heldOrders.indexWhere((h) => h.id == heldOrderId);
    if (matchIndex == -1) return;

    final held = state.heldOrders[matchIndex];
    final updatedHeldList = List<HeldOrder>.from(state.heldOrders)..removeAt(matchIndex);

    emit(
      CartState(
        items: held.items,
        orderTypeId: held.orderTypeId,
        diningTableId: held.diningTableId,
        tableName: held.orderLabel.startsWith('Table') ? held.orderLabel : null,
        customerName: !held.orderLabel.startsWith('Table') ? held.orderLabel : null,
        guestCount: held.guestCount,
        eligibleGuestCount: held.eligibleGuestCount,
        manualDiscountPercentage: held.manualDiscountPercentage,
        manualDiscountFixed: held.manualDiscountFixed,
        surchargeAmount: held.surchargeAmount,
        surchargePercent: held.surchargePercent,
        appliedDiscount: held.appliedDiscount,
        beneficiaryName: held.beneficiaryName,
        beneficiaryIdNo: held.beneficiaryIdNo,
        remarks: held.remarks,
        heldOrders: updatedHeldList,
      ),
    );
  }

  /// Discards a held order
  void deleteHeldOrder(String heldOrderId) {
    final updatedHeldList = state.heldOrders.where((h) => h.id != heldOrderId).toList();
    emit(state.copyWith(heldOrders: updatedHeldList));
  }

  void clearCart() {
    emit(
      CartState(
        orderTypeId: state.orderTypeId,
        diningTableId: state.diningTableId,
        tableName: state.tableName,
        customerName: state.customerName,
        guestCount: state.guestCount,
        eligibleGuestCount: state.eligibleGuestCount,
        heldOrders: state.heldOrders,
      ),
    );
  }

  Future<TransactionDetail?> submitOrder({
    required int cashierId,
    required int paymentMethodId,
    required double cashTendered,
    int? bankId,
    String? referenceNumber,
    int? chargeAccountId,
  }) async {
    if (state.items.isEmpty) return null;

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final breakdown = state.breakdown;

    final order = SalesOrderAggregate(
      diningTableId: state.diningTableId,
      orderTypeId: state.orderTypeId,
      cashierId: cashierId,
      guestCount: state.guestCount,
      eligibleGuestCount: state.eligibleGuestCount,
      items: state.items,
      discountId: state.appliedDiscount?.id,
      discPercentage: state.manualDiscountPercentage,
      discFixedAmount: state.manualDiscountFixed,
      surchargeAmount: state.surchargeAmount,
      surchargePercent: state.surchargePercent,
      beneficiaryName: state.beneficiaryName,
      beneficiaryIdNo: state.beneficiaryIdNo,
      beneficiaryDiscountTypeId: state.appliedDiscount?.discountTypeId,
      remarks: state.remarks,
      createdAt: DateTime.now(),
    );

    final totalAmount = breakdown.netTotal;
    final changeGiven = cashTendered - totalAmount;

    final result = await processCheckout(
      order: order,
      paymentMethodId: paymentMethodId,
      cashTendered: cashTendered,
      changeGiven: changeGiven >= 0 ? changeGiven : 0.0,
      manualDiscountPercentage: state.manualDiscountPercentage,
      manualDiscountFixed: state.manualDiscountFixed,
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
          paymentMethodName: paymentMethodId == 1 ? 'Cash' : (paymentMethodId == 2 ? 'Card' : 'E-Wallet / Bank'),
          cashierName: 'Admin',
          orderTypeName: state.orderTypeId == 1 ? 'Dine-In' : 'Take-Out',
          guestCount: state.guestCount,
          eligibleGuestCount: state.eligibleGuestCount,
          discountName: state.appliedDiscount?.name,
          itemDiscountAmount: breakdown.itemDiscountAmount,
          orderDiscountAmount: breakdown.manualDiscountAmount,
          vatableSales: breakdown.vatableSales,
          vatAmount: breakdown.vatAmount,
          vatExemptSales: breakdown.vatExemptSales,
          zeroRatedSales: breakdown.zeroRatedSales,
          beneficiaryName: state.beneficiaryName,
          beneficiaryIdNo: state.beneficiaryIdNo,
          transactionDate: DateTime.now(),
          lines: state.items
              .map(
                (item) => TransactionLineDetail(
                  itemId: item.item.id ?? 0,
                  itemName: item.item.name,
                  barcode: item.item.barcode ?? item.item.itemCode,
                  quantity: item.quantity,
                  unitPrice: item.effectiveUnitPrice,
                  amount: item.effectiveTotalPrice,
                  lineDiscount: item.totalLineDiscount,
                  isFreeItem: item.isFreeItem,
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
