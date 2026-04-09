import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';
import 'package:suki_pos/domain/repositories/admin/user_repository.dart';

/// [DOMAIN LAYER]

class GetUsers implements UseCase<List<User>, NoParams> {
  const GetUsers(this.repository);
  final UserRepository repository;

  @override
  Future<Either<Failure, List<User>>> call(NoParams params) {
    return repository.getUsers();
  }
}

class SaveUser implements UseCase<User, User> {
  const SaveUser(this.repository);
  final UserRepository repository;

  @override
  Future<Either<Failure, User>> call(User user) {
    return repository.saveUser(user);
  }
}

class DeleteUser implements UseCase<void, int> {
  const DeleteUser(this.repository);
  final UserRepository repository;

  @override
  Future<Either<Failure, void>> call(int id) {
    return repository.deleteUser(id);
  }
}
