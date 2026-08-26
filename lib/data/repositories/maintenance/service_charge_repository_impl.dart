import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/service_charge_dao.dart';
import 'package:suki_pos/domain/entities/maintenance/service_charge_config.dart';
import 'package:suki_pos/domain/repositories/maintenance/service_charge_repository.dart';

class ServiceChargeRepositoryImpl implements ServiceChargeRepository {
  final ServiceChargeDao serviceChargeDao;

  ServiceChargeRepositoryImpl({required this.serviceChargeDao});

  @override
  Future<Either<Failure, ServiceChargeConfig>> getServiceChargeConfig() async {
    try {
      final map = await serviceChargeDao.getServiceChargeConfig();
      if (map != null) {
        final amount = (map['amount'] is num) ? (map['amount'] as num).toDouble() : 10.0;
        final isActive = (map['is_active'] ?? 1) == 1;

        return Right(
          ServiceChargeConfig(
            id: map['id'] as int? ?? 1,
            ratePercent: amount,
            isActive: isActive,
            computeBeforeDiscount: true,
          ),
        );
      }
      return const Right(ServiceChargeConfig());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceChargeConfig>> saveServiceChargeConfig(ServiceChargeConfig config) async {
    try {
      await serviceChargeDao.saveServiceChargeConfig(
        amount: config.ratePercent,
        isActive: config.isActive,
      );
      return Right(config);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
