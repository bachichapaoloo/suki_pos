import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/models/admin/user_model.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';
import 'package:suki_pos/domain/repositories/auth/auth_repository.dart';

/// [DATA LAYER]
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.databaseHelper);
  final DatabaseHelper databaseHelper;

  @override
  Future<Either<Failure, User>> login(String pin) async {
    try {
      final db = await databaseHelper.database;
      
      // Look for a user where the password_hash matches the entered pin
      // and the user is active.
      final List<Map<String, dynamic>> maps = await db.query(
        'app_user',
        where: 'password_hash = ? AND is_active = 1',
        whereArgs: [pin],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Right(UserModel.fromMap(maps.first));
      } else {
        return Left(NotFoundFailure());
      }
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
