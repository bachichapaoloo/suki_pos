import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/models/maintenance/product_model.dart';
import 'package:suki_pos/domain/entities/maintenance/product.dart';
import 'package:suki_pos/domain/repositories/maintenance/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this.databaseHelper);
  final DatabaseHelper databaseHelper;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'item',
        orderBy: 'name ASC',
      );
      return Right(maps.map(ProductModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    int categoryId,
  ) async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'item',
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'name ASC',
      );
      return Right(maps.map(ProductModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> saveProduct(Product product) async {
    try {
      final db = await databaseHelper.database;
      final model = ProductModel.fromEntity(product);

      if (model.id == 0) {
        final id = await db.insert('item', model.toMap());
        return Right(model.copyWith(id: id));
      } else {
        await db.update(
          'item',
          model.toMap(),
          where: 'id = ?',
          whereArgs: [model.id],
        );
        return Right(model);
      }
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete('item', where: 'id = ?', whereArgs: [id]);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
