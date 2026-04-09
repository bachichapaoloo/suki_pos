import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/models/admin/role_model.dart';
import 'package:suki_pos/domain/entities/admin/role.dart';
import 'package:suki_pos/domain/repositories/admin/role_repository.dart';

/// [DATA LAYER]
/// The Repository Implementation is responsible for the actual data logic.
/// It uses the DatabaseHelper to perform CRUD operations on the 'role' table.
class RoleRepositoryImpl implements RoleRepository {
  const RoleRepositoryImpl(this.databaseHelper);

  final DatabaseHelper databaseHelper;

  @override
  Future<Either<Failure, List<Role>>> getRoles() async {
    try {
      final db = await databaseHelper.database;
      // Fetch all rows from the 'role' table, sorted by name.
      final List<Map<String, dynamic>> maps = await db.query(
        'role',
        orderBy: 'name ASC',
      );
      // Map each row to a RoleModel (which is also a Role entity).
      return Right(maps.map(RoleModel.fromMap).toList());
    } catch (e) {
      // In case of any database error, return a DatabaseFailure.
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Role>> saveRole(Role role) async {
    try {
      final db = await databaseHelper.database;
      final model = RoleModel.fromEntity(role);

      if (model.id == 0) {
        // If ID is 0, it's a new record. Insert it.
        final id = await db.insert('role', model.toMap());
        return Right(model.copyWith(id: id));
      } else {
        // If ID is not 0, update the existing record.
        await db.update(
          'role',
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
  Future<Either<Failure, void>> deleteRole(int id) async {
    try {
      final db = await databaseHelper.database;
      // Delete the role by ID. Note: SQL 'ON DELETE RESTRICT' in the schema
      // will prevent deleting roles that are still assigned to users.
      await db.delete(
        'role',
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
