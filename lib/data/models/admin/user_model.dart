import 'package:suki_pos/domain/entities/admin/user.dart';

/// [DATA LAYER]
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.roleId,
    required super.name,
    required super.passwordHash,
    super.isActive,
    super.createdAt,
    super.updatedAt,
    super.roleName,
    super.canSalesEntry,
    super.canSalesOrder,
    super.canSalesReading,
    super.canSalesInquiry,
    super.canFileMaintenance,
    super.canAdminMode,
    super.canInventory,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      roleId: map['role_id'] as int,
      name: map['name'] as String,
      passwordHash: map['password_hash'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      roleName: map['role_name'] as String?,
      canSalesEntry: (map['can_sales_entry'] as int? ?? 1) == 1,
      canSalesOrder: (map['can_sales_order'] as int? ?? 1) == 1,
      canSalesReading: (map['can_sales_reading'] as int? ?? 1) == 1,
      canSalesInquiry: (map['can_sales_inquiry'] as int? ?? 1) == 1,
      canFileMaintenance: (map['can_file_maintenance'] as int? ?? 1) == 1,
      canAdminMode: (map['can_admin_mode'] as int? ?? 1) == 1,
      canInventory: (map['can_inventory'] as int? ?? 1) == 1,
    );
  }

  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      roleId: entity.roleId,
      name: entity.name,
      passwordHash: entity.passwordHash,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      roleName: entity.roleName,
      canSalesEntry: entity.canSalesEntry,
      canSalesOrder: entity.canSalesOrder,
      canSalesReading: entity.canSalesReading,
      canSalesInquiry: entity.canSalesInquiry,
      canFileMaintenance: entity.canFileMaintenance,
      canAdminMode: entity.canAdminMode,
      canInventory: entity.canInventory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'role_id': roleId,
      'name': name,
      'password_hash': passwordHash,
      'is_active': isActive ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
