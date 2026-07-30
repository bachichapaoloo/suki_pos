import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';

abstract class TransactionHistoryState extends Equatable {
  const TransactionHistoryState();

  @override
  List<Object?> get props => [];
}

class TransactionHistoryInitial extends TransactionHistoryState {}

class TransactionHistoryLoading extends TransactionHistoryState {}

class TransactionHistoryLoaded extends TransactionHistoryState {
  final List<TransactionDetail> transactions;
  final String searchQuery;

  const TransactionHistoryLoaded({
    required this.transactions,
    this.searchQuery = '',
  });

  List<TransactionDetail> get filteredTransactions {
    if (searchQuery.isEmpty) return transactions;
    final q = searchQuery.toLowerCase();
    return transactions.where((t) {
      return t.transactionNo.toLowerCase().contains(q) ||
          t.cashierName.toLowerCase().contains(q) ||
          t.lines.any((l) => l.itemName.toLowerCase().contains(q));
    }).toList();
  }

  @override
  List<Object?> get props => [transactions, searchQuery];
}

class TransactionHistoryError extends TransactionHistoryState {
  final String message;
  const TransactionHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
