import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/orders/sales_order.dart';
import 'package:suki_pos/domain/repositories/orders/order_repository.dart';

class ProcessCheckout {
  final OrderRepository repository;

  ProcessCheckout(this.repository);

  Future<Either<Failure, int>> call({
    required SalesOrderAggregate order,
    required int paymentMethodId,
    required double cashTendered,
    required double changeGiven,
  }) async {
    return await repository.processCheckout(
      order: order,
      paymentMethodId: paymentMethodId,
      cashTendered: cashTendered,
      changeGiven: changeGiven,
    );
  }
}
