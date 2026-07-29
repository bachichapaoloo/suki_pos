import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/domain/entities/maintenance/option_group.dart';
import 'package:suki_pos/domain/use_cases/maintenance/option_group_use_cases.dart';
import 'package:suki_pos/presentation/maintenance/option_group/bloc/option_group_state.dart';

class OptionGroupCubit extends Cubit<OptionGroupState> {
  final GetOptionGroups getOptionGroups;
  final SaveOptionGroup saveOptionGroup;

  OptionGroupCubit({
    required this.getOptionGroups,
    required this.saveOptionGroup,
  }) : super(OptionGroupInitial());

  Future<void> loadOptionGroups() async {
    emit(OptionGroupLoading());

    final result = await getOptionGroups();
    result.fold(
      (failure) => emit(OptionGroupError('Failed to load option groups')),
      (groups) => emit(OptionGroupLoaded(groups)),
    );
  }

  Future<bool> saveGroup(OptionGroup group) async {
    final result = await saveOptionGroup(group);
    return result.fold(
      (failure) {
        emit(OptionGroupError('Failed to save option group'));
        return false;
      },
      (_) {
        loadOptionGroups();
        return true;
      },
    );
  }
}
