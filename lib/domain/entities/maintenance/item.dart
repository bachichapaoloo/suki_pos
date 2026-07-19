import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/item_price.dart';

class Item extends Equatable {
  final int? id;
  final String itemCode;
  final String name;
  final String printName;
  final int categoryId;
  final int departmentId;
  final double costPrice;
  final bool isActive;
  final List<ItemPrice> prices;

  const Item({
    this.id,
    required this.itemCode,
    required this.name,
    required this.printName,
    required this.categoryId,
    required this.departmentId,
    required this.costPrice,
    this.isActive = true,
    this.prices = const [],
  });

  @override
  List<Object?> get props => [
    id,
    itemCode,
    name,
    printName,
    categoryId,
    departmentId,
    costPrice,
    isActive,
    prices,
  ];
}
