import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/domain/use_cases/inventory/stock_use_cases.dart';
import 'package:suki_pos/presentation/inventory/stock_state.dart';

class StockCubit extends Cubit<StockState> {
  final GetStockWithDetails getStockWithDetails;
  final UpdateStockQuantity updateStockQuantity;

  StockCubit({
    required this.getStockWithDetails,
    required this.updateStockQuantity,
  }) : super(StockInitial());

  Future<void> loadStockList() async {
    emit(StockLoading());
    final result = await getStockWithDetails();
    result.fold(
      (failure) => emit(const StockError('Failed to load stock list')),
      (stocks) => emit(StockLoaded(stockList: stocks)),
    );
  }

  void filterSearch(String query) {
    if (state is StockLoaded) {
      final current = state as StockLoaded;
      emit(StockLoaded(stockList: current.filteredList, searchQuery: query));
    }
  }

  Future<bool> adjustStock({
    required int itemId,
    required double delta,
    required String remarks,
  }) async {
    final result = await updateStockQuantity(
      itemId: itemId,
      quantityDelta: delta,
      remarks: remarks,
    );

    return result.fold(
      (failure) {
        emit(StockError('Failed to update stock'));
        return false;
      },
      (_) {
        loadStockList(); // Refresh list after adjustment
        return true;
      },
    );
  }
}
