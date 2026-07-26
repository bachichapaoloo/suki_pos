import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/inventory/stock.dart';

class StockWithItem extends Equatable {
  final Stock stock;
  final String itemName;
  final String itemCode;
  final String? barcode;
  final String? unitName;

  const StockWithItem({
    required this.stock,
    required this.itemName,
    required this.itemCode,
    this.barcode,
    this.unitName,
  });

  bool get isLowStock => stock.quantity <= stock.minLevel && stock.minLevel > 0;

  @override
  List<Object?> get props => [stock, itemName, itemCode, barcode, unitName];
}
