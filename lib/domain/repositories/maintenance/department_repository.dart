import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';

/// Repository interface for department maintenance.
abstract class DepartmentRepository {
  /// Fetches all departments.
  Future<Either<Failure, List<Department>>> getDepartments();

  /// Saves a department (create if id is 0, update otherwise).
  Future<Either<Failure, Department>> saveDepartment(Department department);

  /// Deletes a department by ID.
  Future<Either<Failure, void>> deleteDepartment(int id);
}
