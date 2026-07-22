import 'package:dartz/dartz.dart' hide Unit;
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/unit_dao.dart';
import 'package:suki_pos/data/models/maintenance/unit_model.dart';
import 'package:suki_pos/domain/entities/maintenance/unit.dart';
import 'package:suki_pos/domain/repositories/maintenance/unit_repository.dart';

class UnitRepositoryImpl implements UnitRepository {
  final UnitDao unitDao;

  UnitRepositoryImpl({required this.unitDao});

  @override
  Future<Either<Failure, List<Unit>>> getUnits() async {
    try {
      final unitMaps = await unitDao.getAllUnits();
      final units = unitMaps.map((map) => UnitModel.fromMap(map)).toList();
      return Right(units);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveUnit(Unit unit) async {
    try {
      final unitModel = UnitModel(
        id: unit.id,
        name: unit.name,
        abbreviation: unit.abbreviation,
        unitValue: unit.unitValue,
        baseUnit: unit.baseUnit,
        isGrams: unit.isGrams,
        isPcs: unit.isPcs,
        isMl: unit.isMl,
        isActive: unit.isActive,
      );

      if (unit.id == null || unit.id == 0) {
        final newId = await unitDao.insertUnit(unitModel.toMap());
        return Right(
          UnitModel(
            id: newId,
            name: unit.name,
            abbreviation: unit.abbreviation,
            unitValue: unit.unitValue,
            baseUnit: unit.baseUnit,
            isGrams: unit.isGrams,
            isPcs: unit.isPcs,
            isMl: unit.isMl,
            isActive: unit.isActive,
          ),
        );
      } else {
        await unitDao.updateUnit(unit.id!, unitModel.toMap());
        return Right(unit);
      }
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUnit(int id) async {
    try {
      await unitDao.deleteUnit(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
