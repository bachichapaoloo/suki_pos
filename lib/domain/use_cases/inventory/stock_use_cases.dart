import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/inventory/stock.dart';
import 'package:suki_pos/domain/entities/inventory/stock_with_item.dart';
import 'package:suki_pos/domain/repositories/inventory/stock_repository.dart';

class GetStockByItemId {
  final StockRepository repository;
  GetStockByItemId(this.repository);

  Future<Either<Failure, Stock?>> call(int itemId) async {
    return repository.getStockByItemId(itemId);
  }
}

class GetStockWithDetails {
  final StockRepository repository;
  GetStockWithDetails(this.repository);

  Future<Either<Failure, List<StockWithItem>>> call() async {
    return await repository.getAllStockWithDetails();
  }
}

class UpdateStockQuantity {
  final StockRepository repository;
  UpdateStockQuantity(this.repository);

  Future<Either<Failure, void>> call({
    required int itemId,
    required double quantityDelta,
    String? remarks,
  }) async {
    return await repository.updateStockQuantity(
      itemId: itemId,
      quantityDelta: quantityDelta,
      remarks: remarks,
    );
  }
}
