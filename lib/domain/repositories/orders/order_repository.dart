import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/orders/sales_order.dart';

abstract class OrderRepository {
  Future<Either<Failure, int>> processCheckout({
    required SalesOrderAggregate order,
    required int paymentMethodId,
    required double cashTendered,
    required double changeGiven,
  });
}
