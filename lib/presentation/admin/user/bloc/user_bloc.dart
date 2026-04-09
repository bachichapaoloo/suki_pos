import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';
import 'package:suki_pos/domain/use_cases/admin/user_use_cases.dart';

/// [PRESENTATION LAYER]
abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object?> get props => [];
}

class GetUsersEvent extends UserEvent {}

class SaveUserEvent extends UserEvent {
  const SaveUserEvent(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}

class DeleteUserEvent extends UserEvent {
  const DeleteUserEvent(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  const UserLoaded(this.users);
  final List<User> users;
  @override
  List<Object?> get props => [users];
}

class UserSuccess extends UserState {
  const UserSuccess(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class UserError extends UserState {
  const UserError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({
    required this.getUsers,
    required this.saveUser,
    required this.deleteUser,
  }) : super(UserInitial()) {
    on<GetUsersEvent>(_onGetUsers);
    on<SaveUserEvent>(_onSaveUser);
    on<DeleteUserEvent>(_onDeleteUser);
  }

  final GetUsers getUsers;
  final SaveUser saveUser;
  final DeleteUser deleteUser;

  Future<void> _onGetUsers(GetUsersEvent event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final result = await getUsers(NoParams());
    result.fold(
      (failure) => emit(const UserError('Failed to load users')),
      (users) => emit(UserLoaded(users)),
    );
  }

  Future<void> _onSaveUser(SaveUserEvent event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final result = await saveUser(event.user);
    result.fold(
      (failure) => emit(const UserError('Failed to save user')),
      (_) {
        emit(const UserSuccess('User saved successfully'));
        add(GetUsersEvent());
      },
    );
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    final result = await deleteUser(event.id);
    result.fold(
      (failure) => emit(const UserError('Failed to delete user')),
      (_) {
        emit(const UserSuccess('User deleted successfully'));
        add(GetUsersEvent());
      },
    );
  }
}
