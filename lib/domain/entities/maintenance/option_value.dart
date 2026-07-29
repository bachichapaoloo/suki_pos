import 'package:equatable/equatable.dart';

class OptionValue extends Equatable {
  final int? id;
  final int optionGroupId;
  final int? itemId; // Optional link to a raw material/item for inventory deduction
  final String? alias;
  final double priceDelta;
  final double costPriceDelta;
  final double quantity;
  final int? unitId;
  final int displayOrder;

  const OptionValue({
    this.id,
    required this.optionGroupId,
    this.itemId,
    this.alias,
    this.priceDelta = 0.0,
    this.costPriceDelta = 0.0,
    this.quantity = 1.0,
    this.unitId,
    this.displayOrder = 0,
  });

  @override
  List<Object?> get props => [
    id,
    optionGroupId,
    itemId,
    alias,
    priceDelta,
    costPriceDelta,
    quantity,
    unitId,
    displayOrder,
  ];
}
