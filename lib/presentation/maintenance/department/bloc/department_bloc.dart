import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/use_cases/maintenance/delete_department.dart';
import 'package:suki_pos/domain/use_cases/maintenance/get_departments.dart';
import 'package:suki_pos/domain/use_cases/maintenance/save_department.dart';

/// Base class for all department events.
abstract class DepartmentEvent extends Equatable {
  const DepartmentEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch all departments.
class GetDepartmentsEvent extends DepartmentEvent {}

/// Event to save a department.
class SaveDepartmentEvent extends DepartmentEvent {
  const SaveDepartmentEvent(this.department);
  final Department department;

  @override
  List<Object?> get props => [department];
}

/// Event to delete a department.
class DeleteDepartmentEvent extends DepartmentEvent {
  const DeleteDepartmentEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

/// Base class for all department states.
abstract class DepartmentState extends Equatable {
  const DepartmentState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class DepartmentInitial extends DepartmentState {}

/// State while fetching/saving data.
class DepartmentLoading extends DepartmentState {}

/// State when departments are loaded.
class DepartmentLoaded extends DepartmentState {
  const DepartmentLoaded(this.departments);
  final List<Department> departments;

  @override
  List<Object?> get props => [departments];
}

/// State when an operation is successful.
class DepartmentSuccess extends DepartmentState {
  const DepartmentSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// State when an error occurs.
class DepartmentError extends DepartmentState {
  const DepartmentError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// BLoC for managing department maintenance.
class DepartmentBloc extends Bloc<DepartmentEvent, DepartmentState> {
  DepartmentBloc({
    required this.getDepartments,
    required this.saveDepartment,
    required this.deleteDepartment,
  }) : super(DepartmentInitial()) {
    on<GetDepartmentsEvent>(_onGetDepartments);
    on<SaveDepartmentEvent>(_onSaveDepartment);
    on<DeleteDepartmentEvent>(_onDeleteDepartment);
  }

  final GetDepartments getDepartments;
  final SaveDepartment saveDepartment;
  final DeleteDepartment deleteDepartment;

  Future<void> _onGetDepartments(
    GetDepartmentsEvent event,
    Emitter<DepartmentState> emit,
  ) async {
    emit(DepartmentLoading());
    final result = await getDepartments(NoParams());
    result.fold(
      (failure) => emit(const DepartmentError('Failed to load departments')),
      (departments) => emit(DepartmentLoaded(departments)),
    );
  }

  Future<void> _onSaveDepartment(
    SaveDepartmentEvent event,
    Emitter<DepartmentState> emit,
  ) async {
    emit(DepartmentLoading());
    final result = await saveDepartment(event.department);
    result.fold(
      (failure) => emit(const DepartmentError('Failed to save department')),
      (department) {
        emit(const DepartmentSuccess('Department saved successfully'));
        add(GetDepartmentsEvent());
      },
    );
  }

  Future<void> _onDeleteDepartment(
    DeleteDepartmentEvent event,
    Emitter<DepartmentState> emit,
  ) async {
    emit(DepartmentLoading());
    final result = await deleteDepartment(event.id);
    result.fold(
      (failure) => emit(const DepartmentError('Failed to delete department')),
      (_) {
        emit(const DepartmentSuccess('Department deleted successfully'));
        add(GetDepartmentsEvent());
      },
    );
  }
}
