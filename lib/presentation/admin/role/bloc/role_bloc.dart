import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/admin/role.dart';
import 'package:suki_pos/domain/use_cases/admin/role_use_cases.dart';

/// [PRESENTATION LAYER]
/// Events are "actions" dispatched from the UI.
abstract class RoleEvent extends Equatable {
  const RoleEvent();
  @override
  List<Object?> get props => [];
}

class GetRolesEvent extends RoleEvent {}

class SaveRoleEvent extends RoleEvent {
  const SaveRoleEvent(this.role);
  final Role role;
  @override
  List<Object?> get props => [role];
}

class DeleteRoleEvent extends RoleEvent {
  const DeleteRoleEvent(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

/// [PRESENTATION LAYER]
/// States represent the current UI condition (loading, success, etc.).
abstract class RoleState extends Equatable {
  const RoleState();
  @override
  List<Object?> get props => [];
}

class RoleInitial extends RoleState {}

class RoleLoading extends RoleState {}

class RoleLoaded extends RoleState {
  const RoleLoaded(this.roles);
  final List<Role> roles;
  @override
  List<Object?> get props => [roles];
}

class RoleSuccess extends RoleState {
  const RoleSuccess(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class RoleError extends RoleState {
  const RoleError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

/// [PRESENTATION LAYER]
/// The BLoC (Business Logic Component) transforms Events into States.
/// It uses the Domain layer (Use Cases) to fulfill the requests.
class RoleBloc extends Bloc<RoleEvent, RoleState> {
  RoleBloc({
    required this.getRoles,
    required this.saveRole,
    required this.deleteRole,
  }) : super(RoleInitial()) {
    // Map events to handler functions.
    on<GetRolesEvent>(_onGetRoles);
    on<SaveRoleEvent>(_onSaveRole);
    on<DeleteRoleEvent>(_onDeleteRole);
  }

  final GetRoles getRoles;
  final SaveRole saveRole;
  final DeleteRole deleteRole;

  Future<void> _onGetRoles(GetRolesEvent event, Emitter<RoleState> emit) async {
    emit(RoleLoading());
    final result = await getRoles(NoParams());
    result.fold(
      (failure) => emit(const RoleError('Failed to load roles')),
      (roles) => emit(RoleLoaded(roles)),
    );
  }

  Future<void> _onSaveRole(SaveRoleEvent event, Emitter<RoleState> emit) async {
    emit(RoleLoading());
    final result = await saveRole(event.role);
    result.fold(
      (failure) => emit(const RoleError('Failed to save role')),
      (_) {
        emit(const RoleSuccess('Role saved successfully'));
        // Refresh the list after saving.
        add(GetRolesEvent());
      },
    );
  }

  Future<void> _onDeleteRole(
    DeleteRoleEvent event,
    Emitter<RoleState> emit,
  ) async {
    emit(RoleLoading());
    final result = await deleteRole(event.id);
    result.fold(
      (failure) => emit(const RoleError('Failed to delete role')),
      (_) {
        emit(const RoleSuccess('Role deleted successfully'));
        // Refresh the list after deleting.
        add(GetRolesEvent());
      },
    );
  }
}
