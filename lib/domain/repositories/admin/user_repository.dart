import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';

/// [DOMAIN LAYER]
abstract class UserRepository {
  Future<Either<Failure, List<User>>> getUsers();
  Future<Either<Failure, User>> saveUser(User user);
  Future<Either<Failure, void>> deleteUser(int id);
}
