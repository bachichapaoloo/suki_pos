import 'package:dartz/dartz.dart' hide Unit;
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/unit.dart';

abstract class UnitRepository {
  Future<Either<Failure, List<Unit>>> getUnits();
  Future<Either<Failure, Unit>> saveUnit(Unit unit);
  Future<Either<Failure, void>> deleteUnit(int id);
}
