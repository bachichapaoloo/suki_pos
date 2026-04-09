import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/product.dart';
import 'package:suki_pos/domain/use_cases/maintenance/product_use_cases.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class GetProductsEvent extends ProductEvent {}

class SaveProductEvent extends ProductEvent {
  const SaveProductEvent(this.product);
  final Product product;
  @override
  List<Object?> get props => [product];
}

class DeleteProductEvent extends ProductEvent {
  const DeleteProductEvent(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  const ProductLoaded(this.products);
  final List<Product> products;
  @override
  List<Object?> get props => [products];
}

class ProductSuccess extends ProductState {
  const ProductSuccess(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ProductError extends ProductState {
  const ProductError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc({
    required this.getProducts,
    required this.saveProduct,
    required this.deleteProduct,
  }) : super(ProductInitial()) {
    on<GetProductsEvent>(_onGetProducts);
    on<SaveProductEvent>(_onSaveProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
  }

  final GetProducts getProducts;
  final SaveProduct saveProduct;
  final DeleteProduct deleteProduct;

  Future<void> _onGetProducts(
    GetProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await getProducts(NoParams());
    result.fold(
      (failure) => emit(const ProductError('Failed to load products')),
      (products) => emit(ProductLoaded(products)),
    );
  }

  Future<void> _onSaveProduct(
    SaveProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await saveProduct(event.product);
    result.fold(
      (failure) => emit(const ProductError('Failed to save product')),
      (_) {
        emit(const ProductSuccess('Product saved successfully'));
        add(GetProductsEvent());
      },
    );
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final result = await deleteProduct(event.id);
    result.fold(
      (failure) => emit(const ProductError('Failed to delete product')),
      (_) {
        emit(const ProductSuccess('Product deleted successfully'));
        add(GetProductsEvent());
      },
    );
  }
}
