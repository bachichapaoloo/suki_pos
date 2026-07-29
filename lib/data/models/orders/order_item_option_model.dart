class OrderItemOptionModel {
  final int? id;
  final int? salesOrderItemId;
  final int? optionGroupId;
  final int? optionValueId;
  final String optionGroupName;
  final String optionValueName;
  final double priceDelta;

  const OrderItemOptionModel({
    this.id,
    this.salesOrderItemId,
    this.optionGroupId,
    this.optionValueId,
    required this.optionGroupName,
    required this.optionValueName,
    required this.priceDelta,
  });

  Map<String, dynamic> toMap(int orderItemId) {
    return {
      'sales_order_item_id': orderItemId,
      'option_group_id': optionGroupId,
      'option_value_id': optionValueId,
      'option_group_name': optionGroupName,
      'option_value_name': optionValueName,
      'price_delta': priceDelta,
      'quantity': 1.0,
    };
  }
}
