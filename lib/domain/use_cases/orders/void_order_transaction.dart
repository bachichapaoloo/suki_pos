import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/repositories/orders/order_repository.dart';

class VoidOrderTransaction {
  final OrderRepository repository;

  VoidOrderTransaction(this.repository);

  Future<Either<Failure, void>> call({
    required int transactionId,
    required int cashierId,
    required String reason,
  }) async {
    return repository.voidOrderTransaction(
      transactionId: transactionId,
      cashierId: cashierId,
      reason: reason,
    );
  }
}
