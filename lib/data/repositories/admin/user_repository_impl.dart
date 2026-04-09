import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/models/admin/user_model.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';
import 'package:suki_pos/domain/repositories/admin/user_repository.dart';

/// [DATA LAYER]
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this.databaseHelper);

  final DatabaseHelper databaseHelper;

  @override
  Future<Either<Failure, List<User>>> getUsers() async {
    try {
      final db = await databaseHelper.database;
      // Fetch users with their role name using a JOIN.
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT u.*, r.name as role_name 
        FROM app_user u
        JOIN role r ON u.role_id = r.id
        ORDER BY u.name ASC
      ''');
      return Right(maps.map(UserModel.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> saveUser(User user) async {
    try {
      final db = await databaseHelper.database;
      final model = UserModel.fromEntity(user);

      if (model.id == 0) {
        final id = await db.insert('app_user', model.toMap());
        return Right(model.copyWith(id: id));
      } else {
        await db.update(
          'app_user',
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
  Future<Either<Failure, void>> deleteUser(int id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete('app_user', where: 'id = ?', whereArgs: [id]);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
