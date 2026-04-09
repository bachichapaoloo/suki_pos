import 'package:suki_pos/domain/entities/maintenance/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.departmentId,
    required super.name,
    super.code,
    super.displayOrder,
    super.isAvailableOnline,
    super.recommendedCategoryId,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int,
      departmentId: map['department_id'] as int,
      code: map['code'] as String?,
      name: map['name'] as String,
      displayOrder: map['display_order'] as int,
      isAvailableOnline: (map['is_available_online'] as int) == 1,
      recommendedCategoryId: map['recommended_category_id'] as int?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      departmentId: entity.departmentId,
      code: entity.code,
      name: entity.name,
      displayOrder: entity.displayOrder,
      isAvailableOnline: entity.isAvailableOnline,
      recommendedCategoryId: entity.recommendedCategoryId,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'department_id': departmentId,
      'code': code,
      'name': name,
      'display_order': displayOrder,
      'is_available_online': isAvailableOnline ? 1 : 0,
      'recommended_category_id': recommendedCategoryId,
      'is_active': isActive ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
