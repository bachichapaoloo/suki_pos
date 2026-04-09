import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/use_cases/maintenance/category_use_cases.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object?> get props => [];
}

class GetCategoriesEvent extends CategoryEvent {}

class SaveCategoryEvent extends CategoryEvent {
  const SaveCategoryEvent(this.category);
  final Category category;
  @override
  List<Object?> get props => [category];
}

class DeleteCategoryEvent extends CategoryEvent {
  const DeleteCategoryEvent(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  const CategoryLoaded(this.categories);
  final List<Category> categories;
  @override
  List<Object?> get props => [categories];
}

class CategorySuccess extends CategoryState {
  const CategorySuccess(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class CategoryError extends CategoryState {
  const CategoryError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc({
    required this.getCategories,
    required this.saveCategory,
    required this.deleteCategory,
  }) : super(CategoryInitial()) {
    on<GetCategoriesEvent>(_onGetCategories);
    on<SaveCategoryEvent>(_onSaveCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
  }

  final GetCategories getCategories;
  final SaveCategory saveCategory;
  final DeleteCategory deleteCategory;

  Future<void> _onGetCategories(
    GetCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await getCategories(NoParams());
    result.fold(
      (failure) => emit(const CategoryError('Failed to load categories')),
      (categories) => emit(CategoryLoaded(categories)),
    );
  }

  Future<void> _onSaveCategory(
    SaveCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await saveCategory(event.category);
    result.fold(
      (failure) => emit(const CategoryError('Failed to save category')),
      (_) {
        emit(const CategorySuccess('Category saved successfully'));
        add(GetCategoriesEvent());
      },
    );
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await deleteCategory(event.id);
    result.fold(
      (failure) => emit(const CategoryError('Failed to delete category')),
      (_) {
        emit(const CategorySuccess('Category deleted successfully'));
        add(GetCategoriesEvent());
      },
    );
  }
}
