import 'package:equatable/equatable.dart';

/// [DOMAIN LAYER]
/// The Entity is the core business object. It should be independent of any
/// external layers (data, UI). We use Equatable to simplify comparisons.
class Role extends Equatable {
  /// Creates a [Role].
  const Role({
    required this.id,
    required this.name,
    this.canSalesEntry = false,
    this.canSalesOrder = false,
    this.canSalesReading = false,
    this.canSalesInquiry = false,
    this.canFileMaintenance = false,
    this.canAdminMode = false,
    this.canDtrMenu = false,
    this.canKiosk = false,
    this.canInventory = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;

  // High-level module permissions mapped from the schema
  final bool canSalesEntry;
  final bool canSalesOrder;
  final bool canSalesReading;
  final bool canSalesInquiry;
  final bool canFileMaintenance;
  final bool canAdminMode;
  final bool canDtrMenu;
  final bool canKiosk;
  final bool canInventory;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    canSalesEntry,
    canSalesOrder,
    canSalesReading,
    canSalesInquiry,
    canFileMaintenance,
    canAdminMode,
    canDtrMenu,
    canKiosk,
    canInventory,
    isActive,
    createdAt,
    updatedAt,
  ];

  /// Creates a copy of this [Role] with the given fields replaced.
  /// This is useful for state management and updates.
  Role copyWith({
    int? id,
    String? name,
    bool? canSalesEntry,
    bool? canSalesOrder,
    bool? canSalesReading,
    bool? canSalesInquiry,
    bool? canFileMaintenance,
    bool? canAdminMode,
    bool? canDtrMenu,
    bool? canKiosk,
    bool? canInventory,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      canSalesEntry: canSalesEntry ?? this.canSalesEntry,
      canSalesOrder: canSalesOrder ?? this.canSalesOrder,
      canSalesReading: canSalesReading ?? this.canSalesReading,
      canSalesInquiry: canSalesInquiry ?? this.canSalesInquiry,
      canFileMaintenance: canFileMaintenance ?? this.canFileMaintenance,
      canAdminMode: canAdminMode ?? this.canAdminMode,
      canDtrMenu: canDtrMenu ?? this.canDtrMenu,
      canKiosk: canKiosk ?? this.canKiosk,
      canInventory: canInventory ?? this.canInventory,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
