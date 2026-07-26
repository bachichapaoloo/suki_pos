import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/inventory/stock_with_item.dart';

abstract class StockState extends Equatable {
  const StockState();

  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<StockWithItem> stockList;
  final String searchQuery;

  const StockLoaded({
    required this.stockList,
    this.searchQuery = '',
  });

  List<StockWithItem> get filteredList {
    if (searchQuery.isEmpty) return stockList;
    final query = searchQuery.toLowerCase();
    return stockList.where((item) {
      return item.itemName.toLowerCase().contains(query) ||
          item.itemCode.toLowerCase().contains(query) ||
          (item.barcode?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  List<Object?> get props => [stockList, searchQuery];
}

class StockError extends StockState {
  final String message;
  const StockError(this.message);

  @override
  List<Object?> get props => [message];
}
