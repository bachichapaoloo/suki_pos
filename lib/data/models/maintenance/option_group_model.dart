import '../../../domain/entities/maintenance/option_group.dart';
import 'option_value_model.dart';

class OptionGroupModel extends OptionGroup {
  const OptionGroupModel({
    super.id,
    required super.name,
    super.isRequired,
    super.selectionType,
    super.minSelect,
    super.maxSelect,
    super.displayOrder,
    super.values,
  });

  factory OptionGroupModel.fromRelationalMaps({
    required Map<String, dynamic> groupMap,
    required List<Map<String, dynamic>> valueMaps,
  }) {
    return OptionGroupModel(
      id: groupMap['id'] as int?,
      name: groupMap['name'] as String,
      isRequired: (groupMap['is_required'] as int? ?? 0) == 1,
      selectionType: groupMap['selection_type'] as int? ?? 0,
      minSelect: groupMap['min_select'] as int? ?? 0,
      maxSelect: groupMap['max_select'] as int?,
      displayOrder: groupMap['display_order'] as int? ?? 0,
      values: valueMaps.map((v) => OptionValueModel.fromMap(v)).toList(),
    );
  }

  Map<String, dynamic> toMasterMap() {
    return {
      'name': name,
      'is_required': isRequired ? 1 : 0,
      'selection_type': selectionType,
      'min_select': minSelect,
      'max_select': maxSelect,
      'display_order': displayOrder,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
