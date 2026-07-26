import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/inventory/stock.dart';

abstract class StockRepository {
  Future<Either<Failure, Stock?>> getStockByItemId(int itemId);
  Future<Either<Failure, List<Stock>>> getAllStock();
  Future<Either<Failure, void>> updateStockQuantity({
    required int itemId,
    required double quantityDelta,
    String? remarks,
  });
  Future<Either<Failure, void>> adjustStock(Stock stock);
}
