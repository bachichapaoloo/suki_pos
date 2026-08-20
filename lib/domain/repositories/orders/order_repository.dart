import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/orders/sales_order.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';

abstract class OrderRepository {
  Future<Either<Failure, int>> processCheckout({
    required SalesOrderAggregate order,
    required int paymentMethodId,
    required double cashTendered,
    required double changeGiven,
    double manualDiscountPercentage = 0.0,
    double manualDiscountFixed = 0.0,
  });

  Future<Either<Failure, List<TransactionDetail>>> getTransactionHistory({
    int limit = 50,
  });

  Future<Either<Failure, void>> voidOrderTransaction({
    required int transactionId,
    required int cashierId,
    required String reason,
  });
}
