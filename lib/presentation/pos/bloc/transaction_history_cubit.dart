import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/use_cases/orders/get_transaction_history.dart';
import '../../../../domain/use_cases/orders/void_order_transaction.dart';
import 'transaction_history_state.dart';

class TransactionHistoryCubit extends Cubit<TransactionHistoryState> {
  final GetTransactionHistory getTransactionHistory;
  final VoidOrderTransaction voidOrderTransaction;

  TransactionHistoryCubit({
    required this.getTransactionHistory,
    required this.voidOrderTransaction,
  }) : super(TransactionHistoryInitial());

  Future<void> loadHistory() async {
    emit(TransactionHistoryLoading());
    final result = await getTransactionHistory();
    result.fold(
      (failure) => emit(const TransactionHistoryError('Failed to load transaction history..')),
      (transactions) => emit(TransactionHistoryLoaded(transactions: transactions)),
    );
  }

  void search(String query) {
    if (state is TransactionHistoryLoaded) {
      final current = state as TransactionHistoryLoaded;
      emit(
        TransactionHistoryLoaded(
          transactions: current.transactions,
          searchQuery: query,
        ),
      );
    }
  }

  Future<bool> voidTransaction({
    required int transactionId,
    required int cashierId,
    required String reason,
  }) async {
    final result = await voidOrderTransaction(
      transactionId: transactionId,
      cashierId: cashierId,
      reason: reason,
    );

    return result.fold(
      (failure) {
        emit(const TransactionHistoryError('Failed to void transaction'));
        return false;
      },
      (_) async {
        await loadHistory(); // Reload list to reflect voided status and restored stock
        return true;
      },
    );
  }
}
