import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/option_value.dart';

class CartItem extends Equatable {
  final String id;
  final Item item;
  final List<OptionValue> selectedOptions;
  final int quantity;
  final String? notes;

  // Item-level Discount & Exemption Features
  final bool isDiscountExempt;
  final bool isFreeItem;
  final double itemDiscountAmount; // Fixed amount discount (₱)
  final double itemDiscountPercent; // Percentage discount (%)

  const CartItem({
    required this.id,
    required this.item,
    this.selectedOptions = const [],
    this.quantity = 1,
    this.notes,
    this.isDiscountExempt = false,
    this.isFreeItem = false,
    this.itemDiscountAmount = 0.0,
    this.itemDiscountPercent = 0.0,
  });

  /// Undiscounted Unit Price including selected options
  double get unitPrice {
    final basePrice = item.prices.isNotEmpty
        ? item.prices.firstWhere((p) => p.priceLevel == 'default', orElse: () => item.prices.first).price
        : item.costPrice;
    final optionsDelta = selectedOptions.fold<double>(0.0, (sum, opt) => sum + opt.priceDelta);
    return basePrice + optionsDelta;
  }

  /// Undiscounted Total Price (unitPrice * quantity)
  double get totalPrice => unitPrice * quantity;

  /// Effective Unit Price after line-level discount or free item status
  double get effectiveUnitPrice {
    if (isFreeItem) return 0.0;
    double price = unitPrice;
    if (itemDiscountPercent > 0) {
      price -= (unitPrice * (itemDiscountPercent / 100));
    }
    if (itemDiscountAmount > 0) {
      price -= (itemDiscountAmount / quantity);
    }
    return price > 0 ? price : 0.0;
  }

  /// Effective Total Price (what the customer actually owes for this line)
  double get effectiveTotalPrice {
    if (isFreeItem) return 0.0;
    double total = totalPrice;
    if (itemDiscountPercent > 0) {
      total -= (totalPrice * (itemDiscountPercent / 100));
    }
    if (itemDiscountAmount > 0) {
      total -= itemDiscountAmount;
    }
    return total > 0 ? total : 0.0;
  }

  /// Total deduction/discount on this item line
  double get totalLineDiscount => totalPrice - effectiveTotalPrice;

  /// Whether this item has any line-level discount applied
  bool get hasItemDiscount => isFreeItem || itemDiscountAmount > 0 || itemDiscountPercent > 0;

  CartItem copyWith({
    int? quantity,
    List<OptionValue>? selectedOptions,
    String? notes,
    bool? isDiscountExempt,
    bool? isFreeItem,
    double? itemDiscountAmount,
    double? itemDiscountPercent,
  }) {
    return CartItem(
      id: id,
      item: item,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      isDiscountExempt: isDiscountExempt ?? this.isDiscountExempt,
      isFreeItem: isFreeItem ?? this.isFreeItem,
      itemDiscountAmount: itemDiscountAmount ?? this.itemDiscountAmount,
      itemDiscountPercent: itemDiscountPercent ?? this.itemDiscountPercent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        item,
        selectedOptions,
        quantity,
        notes,
        isDiscountExempt,
        isFreeItem,
        itemDiscountAmount,
        itemDiscountPercent,
      ];
}
