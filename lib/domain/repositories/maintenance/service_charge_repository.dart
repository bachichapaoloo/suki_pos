import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/service_charge_config.dart';

abstract class ServiceChargeRepository {
  Future<Either<Failure, ServiceChargeConfig>> getServiceChargeConfig();
  Future<Either<Failure, ServiceChargeConfig>> saveServiceChargeConfig(ServiceChargeConfig config);
}
