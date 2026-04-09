import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/admin/role.dart';
import 'package:suki_pos/domain/repositories/admin/role_repository.dart';

/// [DOMAIN LAYER]
/// Use Cases represent specific actions the user can perform.
/// They orchestrate the flow of data to and from entities.

class GetRoles implements UseCase<List<Role>, NoParams> {
  const GetRoles(this.repository);
  final RoleRepository repository;

  @override
  Future<Either<Failure, List<Role>>> call(NoParams params) {
    return repository.getRoles();
  }
}

class SaveRole implements UseCase<Role, Role> {
  const SaveRole(this.repository);
  final RoleRepository repository;

  @override
  Future<Either<Failure, Role>> call(Role role) {
    return repository.saveRole(role);
  }
}

class DeleteRole implements UseCase<void, int> {
  const DeleteRole(this.repository);
  final RoleRepository repository;

  @override
  Future<Either<Failure, void>> call(int id) {
    return repository.deleteRole(id);
  }
}
