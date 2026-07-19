import '../../../domain/entities/maintenance/item.dart';
import 'item_price_model.dart';

class ItemModel extends Item {
  const ItemModel({
    super.id,
    required super.itemCode,
    required super.name,
    required super.printName,
    required super.categoryId,
    required super.departmentId,
    required super.costPrice,
    super.isActive,
    super.prices,
  });

  /// Constructs an ItemModel by combining the master row and its child rows.
  factory ItemModel.fromRelationalMaps({
    required Map<String, dynamic> itemMap,
    required List<Map<String, dynamic>> priceMaps,
  }) {
    return ItemModel(
      id: itemMap['id'] as int?,
      itemCode: itemMap['item_code'] as String,
      name: itemMap['name'] as String,
      printName: itemMap['print_name'] as String,
      categoryId: itemMap['category_id'] as int,
      departmentId: itemMap['department_id'] as int,
      costPrice: (itemMap['cost_price'] as num).toDouble(),
      isActive: (itemMap['is_active'] as int? ?? 1) == 1,
      prices: priceMaps.map((m) => ItemPriceModel.fromMap(m)).toList(),
    );
  }

  /// Extracts ONLY the fields belonging to the core `item` table.
  Map<String, dynamic> toMasterTableMap() {
    return {
      'item_code': itemCode,
      'name': name,
      'print_name': printName,
      'category_id': categoryId,
      'department_id': departmentId,
      'cost_price': costPrice,
      'is_active': isActive ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
