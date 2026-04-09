import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/repositories/maintenance/department_repository.dart';

/// Use case to delete a department.
class DeleteDepartment implements UseCase<void, int> {
  /// Creates a [DeleteDepartment].
  const DeleteDepartment(this.repository);

  final DepartmentRepository repository;

  @override
  Future<Either<Failure, void>> call(int id) {
    return repository.deleteDepartment(id);
  }
}
