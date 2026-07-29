import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/option_value.dart';

class CartItem extends Equatable {
  final String id;
  final Item item;
  final List<OptionValue> selectedOptions;
  final int quantity;
  final String? notes;

  const CartItem({
    required this.id,
    required this.item,
    this.selectedOptions = const [],
    this.quantity = 1,
    this.notes,
  });

  double get unitPrice {
    final basePrice = item.prices.isNotEmpty
        ? item.prices.firstWhere((p) => p.priceLevel == 'default', orElse: () => item.prices.first).price
        : item.costPrice;
    final optionsDelta = selectedOptions.fold<double>(0.0, (sum, opt) => sum + opt.priceDelta);
    return basePrice + optionsDelta;
  }

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity, List<OptionValue>? selectedOptions, String? notes}) {
    return CartItem(
      id: id,
      item: item,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, item, selectedOptions, quantity, notes];
}
