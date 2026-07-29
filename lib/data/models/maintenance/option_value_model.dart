import '../../../domain/entities/maintenance/option_value.dart';

class OptionValueModel extends OptionValue {
  const OptionValueModel({
    super.id,
    required super.optionGroupId,
    super.itemId,
    super.alias,
    super.priceDelta,
    super.costPriceDelta,
    super.quantity,
    super.unitId,
    super.displayOrder,
  });

  factory OptionValueModel.fromMap(Map<String, dynamic> map) {
    return OptionValueModel(
      id: map['id'] as int?,
      optionGroupId: map['option_group_id'] as int,
      itemId: map['item_id'] as int?,
      alias: map['alias'] as String?,
      priceDelta: (map['price_delta'] as num? ?? 0.0).toDouble(),
      costPriceDelta: (map['cost_price_delta'] as num? ?? 0.0).toDouble(),
      quantity: (map['quantity'] as num? ?? 1.0).toDouble(),
      unitId: map['unit_id'] as int?,
      displayOrder: map['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap(int groupKey) {
    return {
      'option_group_id': groupKey,
      'item_id': itemId,
      'alias': alias,
      'price_delta': priceDelta,
      'cost_price_delta': costPriceDelta,
      'quantity': quantity,
      'unit_id': unitId,
      'display_order': displayOrder,
    };
  }
}
