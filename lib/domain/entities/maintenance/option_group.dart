import 'package:equatable/equatable.dart';
import 'option_value.dart';

class OptionGroup extends Equatable {
  final int? id;
  final String name;
  final bool isRequired;
  final int selectionType; // 0 = Single choice (Radio), 1 = Multi choice (Checkbox)
  final int minSelect;
  final int? maxSelect;
  final int displayOrder;
  final List<OptionValue> values;

  const OptionGroup({
    this.id,
    required this.name,
    this.isRequired = false,
    this.selectionType = 0,
    this.minSelect = 0,
    this.maxSelect,
    this.displayOrder = 0,
    this.values = const [],
  });

  @override
  List<Object?> get props => [id, name, isRequired, selectionType, minSelect, maxSelect, displayOrder, values];
}
