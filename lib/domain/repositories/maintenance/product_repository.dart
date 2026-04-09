import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/product.dart';

/// Repository interface for product maintenance.
abstract class ProductRepository {
  /// Fetches all products.
  Future<Either<Failure, List<Product>>> getProducts();

  /// Fetches products by category.
  Future<Either<Failure, List<Product>>> getProductsByCategory(int categoryId);

  /// Saves a product.
  Future<Either<Failure, Product>> saveProduct(Product product);

  /// Deletes a product by ID.
  Future<Either<Failure, void>> deleteProduct(int id);
}
