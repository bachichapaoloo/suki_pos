import 'package:suki_pos/domain/entities/admin/role.dart';

/// [DATA LAYER]
/// The Model extends the Entity and adds data-specific logic like JSON/DB mapping.
/// This keeps the Entity pure and independent of database-specific keys.
class RoleModel extends Role {
  const RoleModel({
    required super.id,
    required super.name,
    super.canSalesEntry,
    super.canSalesOrder,
    super.canSalesReading,
    super.canSalesInquiry,
    super.canFileMaintenance,
    super.canAdminMode,
    super.canDtrMenu,
    super.canKiosk,
    super.canInventory,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  /// Maps a database row (Map) to a [RoleModel].
  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      id: map['id'] as int,
      name: map['name'] as String,
      canSalesEntry: (map['can_sales_entry'] as int) == 1,
      canSalesOrder: (map['can_sales_order'] as int) == 1,
      canSalesReading: (map['can_sales_reading'] as int) == 1,
      canSalesInquiry: (map['can_sales_inquiry'] as int) == 1,
      canFileMaintenance: (map['can_file_maintenance'] as int) == 1,
      canAdminMode: (map['can_admin_mode'] as int) == 1,
      canDtrMenu: (map['can_dtr_menu'] as int) == 1,
      canKiosk: (map['can_kiosk'] as int) == 1,
      canInventory: (map['can_inventory'] as int) == 1,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Maps a [Role] entity to a [RoleModel].
  factory RoleModel.fromEntity(Role entity) {
    return RoleModel(
      id: entity.id,
      name: entity.name,
      canSalesEntry: entity.canSalesEntry,
      canSalesOrder: entity.canSalesOrder,
      canSalesReading: entity.canSalesReading,
      canSalesInquiry: entity.canSalesInquiry,
      canFileMaintenance: entity.canFileMaintenance,
      canAdminMode: entity.canAdminMode,
      canDtrMenu: entity.canDtrMenu,
      canKiosk: entity.canKiosk,
      canInventory: entity.canInventory,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Maps the [RoleModel] back to a database row (Map).
  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'can_sales_entry': canSalesEntry ? 1 : 0,
      'can_sales_order': canSalesOrder ? 1 : 0,
      'can_sales_reading': canSalesReading ? 1 : 0,
      'can_sales_inquiry': canSalesInquiry ? 1 : 0,
      'can_file_maintenance': canFileMaintenance ? 1 : 0,
      'can_admin_mode': canAdminMode ? 1 : 0,
      'can_dtr_menu': canDtrMenu ? 1 : 0,
      'can_kiosk': canKiosk ? 1 : 0,
      'can_inventory': canInventory ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
