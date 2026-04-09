import 'package:suki_pos/domain/entities/maintenance/department.dart';

/// Data model for [Department].
class DepartmentModel extends Department {
  /// Creates a [DepartmentModel].
  const DepartmentModel({
    required super.id,
    required super.code,
    required super.name,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  /// Creates a [DepartmentModel] from a database map.
  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: map['id'] as int,
      code: map['code'] as String,
      name: map['name'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Converts a [Department] entity to a [DepartmentModel].
  factory DepartmentModel.fromEntity(Department entity) {
    return DepartmentModel(
      id: entity.id,
      code: entity.code,
      name: entity.name,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts this model to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'code': code,
      'name': name,
      'is_active': isActive ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
