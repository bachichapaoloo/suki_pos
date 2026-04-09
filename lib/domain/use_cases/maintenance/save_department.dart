import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/repositories/maintenance/department_repository.dart';

/// Use case to save (create or update) a department.
class SaveDepartment implements UseCase<Department, Department> {
  /// Creates a [SaveDepartment].
  const SaveDepartment(this.repository);

  final DepartmentRepository repository;

  @override
  Future<Either<Failure, Department>> call(Department department) {
    return repository.saveDepartment(department);
  }
}
