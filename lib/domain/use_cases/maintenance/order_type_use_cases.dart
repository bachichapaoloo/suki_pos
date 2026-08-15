import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/order_type.dart';
import 'package:suki_pos/domain/repositories/maintenance/order_type_repository.dart';

class GetOrderTypes {
  final OrderTypeRepository repository;
  GetOrderTypes(this.repository);

  Future<Either<Failure, List<OrderType>>> call() async {
    return repository.getOrderTypes();
  }
}

class GetOrderTypeById {
  final OrderTypeRepository repository;
  GetOrderTypeById(this.repository);

  Future<Either<Failure, OrderType?>> call(int id) async {
    return repository.getOrderTypeById(id);
  }
}

class SaveOrderType {
  final OrderTypeRepository repository;
  SaveOrderType(this.repository);

  Future<Either<Failure, OrderType>> call(OrderType orderType) async {
    return repository.saveOrderType(orderType);
  }
}

class DeleteOrderType {
  final OrderTypeRepository repository;
  DeleteOrderType(this.repository);

  Future<Either<Failure, void>> call(int id) async {
    return repository.deleteOrderType(id);
  }
}
