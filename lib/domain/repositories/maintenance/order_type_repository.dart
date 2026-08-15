import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/order_type.dart';

abstract class OrderTypeRepository {
  Future<Either<Failure, List<OrderType>>> getOrderTypes();
  Future<Either<Failure, OrderType?>> getOrderTypeById(int id);
  Future<Either<Failure, OrderType>> saveOrderType(OrderType orderType);
  Future<Either<Failure, void>> deleteOrderType(int id);
}
