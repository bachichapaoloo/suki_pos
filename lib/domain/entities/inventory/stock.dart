import 'package:equatable/equatable.dart';

class Stock extends Equatable {
  final int? id;
  final int itemId;
  final double quantity;
  final double reorderLevel;
  final double beginningInv;
  final double minLevel;
  final double maxLevel;
  final double? cost;
  final double? physicalCount;
  final double? prevPhysicalCount;
  final double? lastPhysicalCount;
  final double? variance;
  final String? remarks;
  final int? supplierId;
  final String? location;
  final DateTime updatedAt;

  const Stock({
    this.id,
    required this.itemId,
    this.quantity = 0.0,
    this.reorderLevel = 0.0,
    this.beginningInv = 0.0,
    this.minLevel = 0.0,
    this.maxLevel = 0.0,
    this.cost,
    this.physicalCount,
    this.prevPhysicalCount,
    this.lastPhysicalCount,
    this.variance,
    this.remarks,
    this.supplierId,
    this.location,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    itemId,
    quantity,
    reorderLevel,
    beginningInv,
    minLevel,
    maxLevel,
    cost,
    physicalCount,
    prevPhysicalCount,
    lastPhysicalCount,
    variance,
    remarks,
    supplierId,
    location,
    updatedAt,
  ];
}
