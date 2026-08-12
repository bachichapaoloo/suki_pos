import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/order_dao.dart';
import 'package:suki_pos/domain/entities/orders/sales_order.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';
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

  Future<Either<Failure, List<TransactionDetail>>> getTransactionHistory({int limit = 50}) async {
    try {
      final txnMaps = await orderDao.getTransactionHistory(limit: limit);
      final List<TransactionDetail> detailsList = [];

      for (final map in txnMaps) {
        final txnId = map['transaction_id'] as int;
        final lineMaps = await orderDao.getTransactionLineDetails(txnId);

        final List<TransactionLineDetail> lineDetails = [];
        for (final line in lineMaps) {
          final soiId = line['sales_order_item_id'] as int?;
          List<String> options = [];
          if (soiId != null) {
            options = await orderDao.getOrderItemOptions(soiId);
          }

          lineDetails.add(
            TransactionLineDetail(
              itemId: line['item_id'] as int,
              itemName: line['item_name'] as String,
              barcode: line['barcode'] as String,
              quantity: (line['quantity'] as num).toInt(),
              unitPrice: (line['unit_price'] as num).toDouble(),
              amount: (line['amount'] as num).toDouble(),
              selectedOptions: options,
            ),
          );
        }

        detailsList.add(
          TransactionDetail(
            transactionId: txnId,
            salesOrderId: map['sales_order_id'] as int,
            transactionNo: 'TXN-${txnId.toString().padLeft(6, '0')}',
            grossAmount: (map['gross_amount'] as num).toDouble(),
            netAmount: (map['net_amount'] as num).toDouble(),
            cashTendered: (map['cash_tendered'] as num? ?? 0.0).toDouble(),
            changeGiven: (map['change_given'] as num? ?? 0.0).toDouble(),
            paymentMethodName: map['payment_method_name'] as String? ?? 'Cash',
            cashierName: map['cashier_name'] as String? ?? 'Admin',
            orderTypeName: map['order_type_name'] as String? ?? 'Dine-In',
            guestCount: 1,
            transactionDate: DateTime.parse(map['transaction_date'] as String),
            lines: lineDetails,
          ),
        );
      }

      return Right(detailsList);
    } catch (e) {
      return Left(
        DatabaseFailure(
          e.toString(),
        ),
      );
    }
  }

  Future<Either<Failure, void>> voidOrderTransaction({
    required int transactionId,
    required int cashierId,
    required String reason,
  }) async {
    try {
      await orderDao.voidOrderTransaction(
        transactionId: transactionId,
        cashierId: cashierId,
        reason: reason,
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
