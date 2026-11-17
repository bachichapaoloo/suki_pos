import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/orders/sales_order.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';
import 'package:suki_pos/domain/entities/pos/tender_payment_leg.dart';

abstract class OrderRepository {
  Future<Either<Failure, int>> processCheckout({
    required SalesOrderAggregate order,
    required int paymentMethodId,
    required double cashTendered,
    required double changeGiven,
    double manualDiscountPercentage = 0.0,
    double manualDiscountFixed = 0.0,
    int? bankId,
    String? referenceNumber,
    int? chargeAccountId,
    List<TenderPaymentLeg>? payments,
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
