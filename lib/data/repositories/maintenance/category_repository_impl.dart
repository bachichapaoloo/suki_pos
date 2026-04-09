import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/models/maintenance/category_model.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/repositories/maintenance/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this.databaseHelper);
  final DatabaseHelper databaseHelper;

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'category',
        orderBy: 'display_order ASC, name ASC',
      );
      return Right(maps.map(CategoryModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategoriesByDepartment(
    int departmentId,
  ) async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'category',
        where: 'department_id = ?',
        whereArgs: [departmentId],
        orderBy: 'display_order ASC, name ASC',
      );
      return Right(maps.map(CategoryModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> saveCategory(Category category) async {
    try {
      final db = await databaseHelper.database;
      final model = CategoryModel.fromEntity(category);

      if (model.id == 0) {
        final id = await db.insert('category', model.toMap());
        return Right(model.copyWith(id: id));
      } else {
        await db.update(
          'category',
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
  Future<Either<Failure, void>> deleteCategory(int id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete('category', where: 'id = ?', whereArgs: [id]);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
