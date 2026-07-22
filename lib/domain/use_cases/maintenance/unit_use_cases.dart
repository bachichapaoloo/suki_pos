import 'package:dartz/dartz.dart' hide Unit;
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/unit.dart';
import 'package:suki_pos/domain/repositories/maintenance/unit_repository.dart';

class GetUnits {
  final UnitRepository repository;
  GetUnits(this.repository);

  Future<Either<Failure, List<Unit>>> call() async {
    return await repository.getUnits();
  }
}

class SaveUnit {
  final UnitRepository repository;
  SaveUnit(this.repository);

  Future<Either<Failure, Unit>> call(Unit unit) async {
    return await repository.saveUnit(unit);
  }
}

class DeleteUnit {
  final UnitRepository repository;
  DeleteUnit(this.repository);

  Future<Either<Failure, void>> call(int id) async {
    return await repository.deleteUnit(id);
  }
}
