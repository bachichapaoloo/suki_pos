import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';
import 'package:suki_pos/domain/repositories/auth/auth_repository.dart';

/// [DOMAIN LAYER]
/// Orchestrates the login process.
class Login implements UseCase<User, String> {
  const Login(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(String pin) {
    return repository.login(pin);
  }
}
