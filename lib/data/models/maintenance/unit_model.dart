import 'package:suki_pos/domain/entities/maintenance/unit.dart';

class UnitModel extends Unit {
  const UnitModel({
    super.id,
    required super.name,
    super.abbreviation,
    super.unitValue,
    super.baseUnit,
    super.isGrams,
    super.isPcs,
    super.isMl,
    super.isActive,
  });

  factory UnitModel.fromMap(Map<String, dynamic> map) {
    return UnitModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      abbreviation: map['abbreviation'] as String?,
      unitValue: (map['unit_value'] as num?)?.toDouble(),
      baseUnit: map['base_unit'] as String?,
      isGrams: (map['is_grams'] as int? ?? 0) == 1,
      isPcs: (map['is_pcs'] as int? ?? 0) == 1,
      isMl: (map['is_ml'] as int? ?? 0) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'unit_value': unitValue,
      'base_unit': baseUnit,
      'is_grams': isGrams ? 1 : 0,
      'is_pcs': isPcs ? 1 : 0,
      'is_ml': isMl ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
