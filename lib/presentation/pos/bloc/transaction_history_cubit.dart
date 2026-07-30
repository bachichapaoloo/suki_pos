import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/domain/use_cases/orders/get_transaction_history.dart';
import 'package:suki_pos/presentation/pos/bloc/transaction_history_state.dart';

class TransactionHistoryCubit extends Cubit<TransactionHistoryState> {
  final GetTransactionHistory getTransactionHistory;

  TransactionHistoryCubit({required this.getTransactionHistory}) : super(TransactionHistoryInitial());

  Future<void> loadHistory() async {
    emit(TransactionHistoryLoading());
    final result = await getTransactionHistory();
    result.fold(
      (failure) => emit(TransactionHistoryError('Failed to load transaction history..')),
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
}
