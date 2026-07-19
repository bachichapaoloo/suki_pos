import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/department_dao.dart';
import 'package:suki_pos/data/models/maintenance/department_model.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/repositories/maintenance/department_repository.dart';

class DepartmentRepositoryImpl implements DepartmentRepository {
  final DepartmentDao departmentDao;

  DepartmentRepositoryImpl({required this.departmentDao});

  @override
  Future<Either<Failure, List<Department>>> getDepartments() async {
    try {
      final departmentMaps = await departmentDao.getAllDepartments();
      final departments = departmentMaps.map((map) => DepartmentModel.fromMap(map)).toList();
      return Right(departments);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Department>> saveDepartment(Department department) async {
    try {
      final departmentModel = DepartmentModel(
        id: department.id ?? 0,
        code: department.code,
        name: department.name,
        isActive: department.isActive,
      );

      if (department.id == null || department.id == 0) {
        final newId = await departmentDao.insertDepartment(departmentModel.toMap());
        return Right(department.copyWith(id: newId));
      } else {
        await departmentDao.updateDepartment(department.id!, departmentModel.toMap());
        return Right(department);
      }
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDepartment(int id) async {
    try {
      await departmentDao.deleteDepartment(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
