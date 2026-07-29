import 'package:suki_pos/data/models/orders/order_item_option_model.dart';

class SalesOrderItemModel {
  final int? id;
  final int? salesOrderId;
  final int itemId;
  final String itemBarcode;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double amount;
  final String? notes;
  final List<OrderItemOptionModel> options;

  const SalesOrderItemModel({
    this.id,
    this.salesOrderId,
    required this.itemId,
    required this.itemBarcode,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.notes,
    this.options = const [],
  });

  Map<String, dynamic> toMap(int orderId) {
    return {
      'sales_order_id': orderId,
      'item_id': itemId,
      'item_barcode': itemBarcode,
      'item_name': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'amount': amount,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
