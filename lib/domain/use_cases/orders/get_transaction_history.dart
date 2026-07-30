import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';
import 'package:suki_pos/domain/repositories/orders/order_repository.dart';

class GetTransactionHistory {
  final OrderRepository repository;

  GetTransactionHistory(this.repository);

  Future<Either<Failure, List<TransactionDetail>>> call({int limit = 50}) async {
    return await repository.getTransactionHistory(limit: limit);
  }
}
