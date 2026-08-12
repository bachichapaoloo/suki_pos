import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:suki_pos/presentation/pos/widgets/void_order_dialog.dart';
import '../bloc/transaction_history_cubit.dart';
import '../bloc/transaction_history_state.dart';
import '../widgets/receipt_preview_dialog.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionHistoryCubit>().loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Inquiry & Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TransactionHistoryCubit>().loadHistory(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Txn No., Cashier, or Item Name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => context.read<TransactionHistoryCubit>().search(val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<TransactionHistoryCubit, TransactionHistoryState>(
                builder: (context, state) {
                  if (state is TransactionHistoryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is TransactionHistoryError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }

                  if (state is TransactionHistoryLoaded) {
                    final txns = state.filteredTransactions;

                    if (txns.isEmpty) {
                      return const Center(child: Text('No transactions recorded yet.'));
                    }

                    return ListView.separated(
                      itemCount: txns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final txn = txns[index];

                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.receipt),
                          ),
                          title: Text(
                            '${txn.transactionNo} — ₱${txn.grossAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${dateFormat.format(txn.transactionDate)} | ${txn.orderTypeName} | Cashier: ${txn.cashierName}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text('Receipt'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => ReceiptPreviewDialog(transaction: txn),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                tooltip: 'Void Transaction',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => VoidOrderDialog(
                                      transactionNo: txn.transactionNo,
                                      onConfirmVoid: (reason) {
                                        context.read<TransactionHistoryCubit>().voidTransaction(
                                          transactionId: txn.transactionId,
                                          cashierId: 1, // Logged in user ID
                                          reason: reason,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
