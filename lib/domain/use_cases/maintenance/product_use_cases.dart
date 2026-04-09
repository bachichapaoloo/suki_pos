import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/product.dart';
import 'package:suki_pos/domain/repositories/maintenance/product_repository.dart';

class GetProducts implements UseCase<List<Product>, NoParams> {
  const GetProducts(this.repository);
  final ProductRepository repository;

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) {
    return repository.getProducts();
  }
}

class SaveProduct implements UseCase<Product, Product> {
  const SaveProduct(this.repository);
  final ProductRepository repository;

  @override
  Future<Either<Failure, Product>> call(Product product) {
    return repository.saveProduct(product);
  }
}

class DeleteProduct implements UseCase<void, int> {
  const DeleteProduct(this.repository);
  final ProductRepository repository;

  @override
  Future<Either<Failure, void>> call(int id) {
    return repository.deleteProduct(id);
  }
}
