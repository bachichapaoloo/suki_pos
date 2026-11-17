import 'package:equatable/equatable.dart';

/// [DOMAIN LAYER]
class User extends Equatable {
  const User({
    required this.id,
    required this.roleId,
    required this.name,
    required this.passwordHash,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.roleName,
    this.canSalesEntry = true,
    this.canSalesOrder = true,
    this.canSalesReading = true,
    this.canSalesInquiry = true,
    this.canFileMaintenance = true,
    this.canAdminMode = true,
    this.canInventory = true,
  });

  final int id;
  final int roleId;
  final String name;
  final String passwordHash;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Non-persisted fields from joined Role table
  final String? roleName;
  final bool canSalesEntry;
  final bool canSalesOrder;
  final bool canSalesReading;
  final bool canSalesInquiry;
  final bool canFileMaintenance;
  final bool canAdminMode;
  final bool canInventory;

  @override
  List<Object?> get props => [
    id,
    roleId,
    name,
    passwordHash,
    isActive,
    createdAt,
    updatedAt,
    roleName,
    canSalesEntry,
    canSalesOrder,
    canSalesReading,
    canSalesInquiry,
    canFileMaintenance,
    canAdminMode,
    canInventory,
  ];

  User copyWith({
    int? id,
    int? roleId,
    String? name,
    String? passwordHash,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? roleName,
    bool? canSalesEntry,
    bool? canSalesOrder,
    bool? canSalesReading,
    bool? canSalesInquiry,
    bool? canFileMaintenance,
    bool? canAdminMode,
    bool? canInventory,
  }) {
    return User(
      id: id ?? this.id,
      roleId: roleId ?? this.roleId,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roleName: roleName ?? this.roleName,
      canSalesEntry: canSalesEntry ?? this.canSalesEntry,
      canSalesOrder: canSalesOrder ?? this.canSalesOrder,
      canSalesReading: canSalesReading ?? this.canSalesReading,
      canSalesInquiry: canSalesInquiry ?? this.canSalesInquiry,
      canFileMaintenance: canFileMaintenance ?? this.canFileMaintenance,
      canAdminMode: canAdminMode ?? this.canAdminMode,
      canInventory: canInventory ?? this.canInventory,
    );
  }
}
