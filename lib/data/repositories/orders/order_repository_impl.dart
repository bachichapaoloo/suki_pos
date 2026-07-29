import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/order_dao.dart';
import 'package:suki_pos/domain/entities/orders/sales_order.dart';
import 'package:suki_pos/domain/repositories/orders/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderDao orderDao;

  OrderRepositoryImpl({required this.orderDao});

  @override
  Future<Either<Failure, int>> processCheckout({
    required SalesOrderAggregate order,
    required int paymentMethodId,
    required double cashTendered,
    required double changeGiven,
  }) async {
    try {
      final orderId = await orderDao.checkoutOrderTransaction(
        order: order,
        paymentMethodId: paymentMethodId,
        cashTendered: cashTendered,
        changeGiven: changeGiven,
      );
      return Right(orderId);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
