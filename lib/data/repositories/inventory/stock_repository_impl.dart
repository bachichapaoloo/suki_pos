import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/stock_dao.dart';
import 'package:suki_pos/data/models/inventory/stock_model.dart';
import 'package:suki_pos/domain/entities/inventory/stock.dart';
import 'package:suki_pos/domain/repositories/inventory/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  final StockDao stockDao;

  StockRepositoryImpl({required this.stockDao});

  @override
  Future<Either<Failure, Stock?>> getStockByItemId(int itemId) async {
    try {
      final map = await stockDao.getStockByItemId(itemId);
      if (map == null) return const Right(null);
      return Right(StockModel.fromMap(map));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Stock>>> getAllStock() async {
    try {
      final maps = await stockDao.getAllStock();
      final stocks = maps.map((m) => StockModel.fromMap(m)).toList();
      return Right(stocks);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStockQuantity({
    required int itemId,
    required double quantityDelta,
    String? remarks,
  }) async {
    try {
      await stockDao.updateQuantityDelta(itemId, quantityDelta, remarks: remarks);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> adjustStock(Stock stock) async {
    try {
      final model = StockModel(
        id: stock.id,
        itemId: stock.itemId,
        quantity: stock.quantity,
        reorderLevel: stock.reorderLevel,
        beginningInv: stock.beginningInv,
        minLevel: stock.minLevel,
        maxLevel: stock.maxLevel,
        cost: stock.cost,
        physicalCount: stock.physicalCount,
        prevPhysicalCount: stock.prevPhysicalCount,
        lastPhysicalCount: stock.lastPhysicalCount,
        variance: stock.variance,
        remarks: stock.remarks,
        supplierId: stock.supplierId,
        location: stock.location,
        updatedAt: DateTime.now(),
      );

      await stockDao.upsertStock(model.toMap());
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
