import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/option_group.dart';

abstract class OptionGroupState extends Equatable {
  const OptionGroupState();

  @override
  List<Object?> get props => [];
}

class OptionGroupInitial extends OptionGroupState {}

class OptionGroupLoading extends OptionGroupState {}

class OptionGroupLoaded extends OptionGroupState {
  final List<OptionGroup> optionGroups;

  const OptionGroupLoaded(this.optionGroups);

  @override
  List<Object?> get props => [optionGroups];
}

class OptionGroupError extends OptionGroupState {
  final String message;
  const OptionGroupError(this.message);

  @override
  List<Object?> get props => [message];
}
