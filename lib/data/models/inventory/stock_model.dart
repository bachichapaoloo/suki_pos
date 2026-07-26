import 'package:suki_pos/domain/entities/inventory/stock.dart';

class StockModel extends Stock {
  StockModel({
    super.id,
    required super.itemId,
    super.quantity,
    super.reorderLevel,
    super.beginningInv,
    super.minLevel,
    super.maxLevel,
    super.cost,
    super.physicalCount,
    super.prevPhysicalCount,
    super.lastPhysicalCount,
    super.variance,
    super.remarks,
    super.supplierId,
    super.location,
    required super.updatedAt,
  });

  factory StockModel.fromMap(Map<String, dynamic> map) {
    return StockModel(
      id: map['id'] as int?,
      itemId: map['item_id'] as int,
      quantity: (map['quantity'] as num? ?? 0.0).toDouble(),
      reorderLevel: (map['reorder_level'] as num? ?? 0.0).toDouble(),
      beginningInv: (map['beginning_inv'] as num? ?? 0.0).toDouble(),
      minLevel: (map['min_level'] as num? ?? 0.0).toDouble(),
      maxLevel: (map['max_level'] as num? ?? 0.0).toDouble(),
      cost: (map['cost'] as num?)?.toDouble(),
      physicalCount: (map['physical_count'] as num?)?.toDouble(),
      prevPhysicalCount: (map['prev_physical_count'] as num?)?.toDouble(),
      lastPhysicalCount: (map['last_physical_count'] as num?)?.toDouble(),
      variance: (map['variance'] as num?)?.toDouble(),
      remarks: map['remarks'] as String?,
      supplierId: map['supplier_id'] as int?,
      location: map['location'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'quantity': quantity,
      'reorder_level': reorderLevel,
      'beginning_inv': beginningInv,
      'min_level': minLevel,
      'max_level': maxLevel,
      'cost': cost,
      'physical_count': physicalCount,
      'prev_physical_count': prevPhysicalCount,
      'last_physical_count': lastPhysicalCount,
      'variance': variance,
      'remarks': remarks,
      'supplier_id': supplierId,
      'location': location,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
