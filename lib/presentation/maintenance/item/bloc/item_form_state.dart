import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/entities/maintenance/unit.dart';

abstract class ItemFormState extends Equatable {
  const ItemFormState();

  @override
  List<Object> get props => [];
}

class ItemFormLoading extends ItemFormState {}

class ItemFormLoaded extends ItemFormState {
  final List<Department> departments;
  final List<Category> categories;
  final List<Unit> units;

  const ItemFormLoaded({
    required this.departments,
    required this.categories,
    required this.units,
  });

  @override
  List<Object> get props => [departments, categories, units];
}

class ItemFormError extends ItemFormState {
  final String message;
  const ItemFormError(this.message);

  @override
  List<Object> get props => [message];
}
