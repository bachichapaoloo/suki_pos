import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/entities/maintenance/unit.dart';
import '../../../../../domain/use_cases/maintenance/category_use_cases.dart';
import '../../../../../domain/use_cases/maintenance/get_departments.dart';
import '../../../../../domain/use_cases/maintenance/unit_use_cases.dart';
import 'item_form_state.dart';

class ItemFormCubit extends Cubit<ItemFormState> {
  final GetDepartments getDepartments;
  final GetCategories getCategories;
  final GetUnits getUnits;

  ItemFormCubit({
    required this.getDepartments,
    required this.getCategories,
    required this.getUnits,
  }) : super(ItemFormLoading());

  /// Fetches all lookup tables concurrently.
  Future<void> loadLookups() async {
    emit(ItemFormLoading());

    // Execute all three local SQLite queries concurrently for maximum speed
    final responses = await Future.wait([
      getDepartments(NoParams()),
      getCategories(NoParams()),
      getUnits(),
    ]);

    final deptResult = responses[0];
    final catResult = responses[1];
    final unitResult = responses[2];

    // If any query failed, emit an error state
    if (deptResult.isLeft() || catResult.isLeft() || unitResult.isLeft()) {
      emit(const ItemFormError('Failed to load form lookup data.'));
      return;
    }

    // Otherwise, unpack the Right values and emit the loaded state
    emit(
      ItemFormLoaded(
        // The cast is needed because Future.wait returns a List of dynamic Either types
        departments: deptResult.getOrElse(() => []) as List<Department>,
        categories: catResult.getOrElse(() => []) as List<Category>,
        units: unitResult.getOrElse(() => []) as List<Unit>,
      ),
    );
  }
}
