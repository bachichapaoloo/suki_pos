import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/models/maintenance/department_model.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/repositories/maintenance/department_repository.dart';

/// Implementation of [DepartmentRepository] using sqflite.
class DepartmentRepositoryImpl implements DepartmentRepository {
  /// Creates a [DepartmentRepositoryImpl].
  const DepartmentRepositoryImpl(this.databaseHelper);

  final DatabaseHelper databaseHelper;

  @override
  Future<Either<Failure, List<Department>>> getDepartments() async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'department',
        orderBy: 'name ASC',
      );
      return Right(maps.map(DepartmentModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Department>> saveDepartment(
    Department department,
  ) async {
    try {
      final db = await databaseHelper.database;
      final model = DepartmentModel.fromEntity(department);

      if (model.id == 0) {
        final id = await db.insert('department', model.toMap());
        return Right(model.copyWith(id: id));
      } else {
        await db.update(
          'department',
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
  Future<Either<Failure, void>> deleteDepartment(int id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        'department',
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
