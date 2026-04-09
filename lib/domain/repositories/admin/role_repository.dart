import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/admin/role.dart';

/// [DOMAIN LAYER]
/// The Repository Interface defines the "contract" for what the data layer
/// must provide. Use Cases will call these methods.
abstract class RoleRepository {
  /// Fetches all roles.
  Future<Either<Failure, List<Role>>> getRoles();

  /// Saves a role (create if id is 0, update otherwise).
  Future<Either<Failure, Role>> saveRole(Role role);

  /// Deletes a role by ID.
  Future<Either<Failure, void>> deleteRole(int id);
}
