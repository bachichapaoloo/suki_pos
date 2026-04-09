import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';

/// Repository interface for category maintenance.
abstract class CategoryRepository {
  /// Fetches all categories.
  Future<Either<Failure, List<Category>>> getCategories();

  /// Fetches categories by department.
  Future<Either<Failure, List<Category>>> getCategoriesByDepartment(
    int departmentId,
  );

  /// Saves a category (create if id is 0, update otherwise).
  Future<Either<Failure, Category>> saveCategory(Category category);

  /// Deletes a category by ID.
  Future<Either<Failure, void>> deleteCategory(int id);
}
