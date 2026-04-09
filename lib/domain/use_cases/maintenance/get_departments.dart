import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/repositories/maintenance/department_repository.dart';

/// Use case to fetch all departments.
class GetDepartments implements UseCase<List<Department>, NoParams> {
  /// Creates a [GetDepartments].
  const GetDepartments(this.repository);

  final DepartmentRepository repository;

  @override
  Future<Either<Failure, List<Department>>> call(NoParams params) {
    return repository.getDepartments();
  }
}
