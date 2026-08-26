import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/order_type_dao.dart';
import 'package:suki_pos/data/models/maintenance/order_type_model.dart';
import 'package:suki_pos/domain/entities/maintenance/order_type.dart';
import 'package:suki_pos/domain/repositories/maintenance/order_type_repository.dart';

class OrderTypeRepositoryImpl implements OrderTypeRepository {
  final OrderTypeDao orderTypeDao;

  OrderTypeRepositoryImpl({required this.orderTypeDao});

  @override
  Future<Either<Failure, List<OrderType>>> getOrderTypes() async {
    try {
      final maps = await orderTypeDao.getOrderTypes();
      final orderTypes = maps.map(OrderTypeModel.fromMap).toList();
      return Right(orderTypes);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderType?>> getOrderTypeById(int id) async {
    try {
      final map = await orderTypeDao.getOrderTypeById(id);
      if (map != null) {
        return Right(OrderTypeModel.fromMap(map));
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderType>> saveOrderType(OrderType orderType) async {
    try {
      final model = OrderTypeModel.fromEntity(orderType);
      if (model.id == 0) {
        final id = await orderTypeDao.insertOrderType(model.toMap());
        return Right(
          OrderTypeModel(
            id: id,
            name: orderType.name,
            hasServiceCharge: orderType.hasServiceCharge,
            askGuestCount: orderType.askGuestCount,
            askRefNo: orderType.askRefNo,
            isRental: orderType.isRental,
            isDelivery: orderType.isDelivery,
            isKiosk: orderType.isKiosk,
            noSurcharge: orderType.noSurcharge,
            surChargeFormula: orderType.surChargeFormula,
            priceLevel: orderType.priceLevel,
            requiresPassword: orderType.requiresPassword,
            additionalPercentage: orderType.additionalPercentage,
            printAdditionalCopy: orderType.printAdditionalCopy,
          ),
        );
      } else {
        await orderTypeDao.updateOrderType(model.id, model.toMap());
        return Right(orderType);
      }
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOrderType(int id) async {
    try {
      await orderTypeDao.deleteOrderType(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
