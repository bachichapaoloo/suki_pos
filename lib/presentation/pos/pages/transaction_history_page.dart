import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/pos/bloc/transaction_history_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/transaction_history_state.dart';
import 'package:suki_pos/presentation/pos/widgets/receipt_preview_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/void_order_dialog.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/responsive_data_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  String _searchQuery = '';
  final _dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    context.read<TransactionHistoryCubit>().loadHistory();
  }

  int _getActiveCashierId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<TransactionHistoryCubit, TransactionHistoryState>(
      listener: (context, state) {
        if (state is TransactionHistoryError) {
          AppToast.showError(context, message: state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is TransactionHistoryLoading;
        List<TransactionDetail> txns = [];
        String? errorMessage;

        if (state is TransactionHistoryLoaded) {
          txns = state.filteredTransactions;
        } else if (state is TransactionHistoryError) {
          errorMessage = state.message;
        }

        return ResponsiveDataPage<TransactionDetail>(
          title: 'Sales Inquiry & History',
          parentHubTitle: 'POS Terminal',
          parentHubRoute: '/pos',
          currentTab: MainTab.sales,
          items: txns,
          isLoading: isLoading,
          errorMessage: errorMessage,
          searchQuery: _searchQuery,
          searchHint: 'Search by Txn No., Cashier, or Item Name...',
          onSearchChanged: (query) {
            setState(() => _searchQuery = query);
            context.read<TransactionHistoryCubit>().search(query);
          },
          onRefresh: () async {
            context.read<TransactionHistoryCubit>().loadHistory();
            AppToast.showInfo(context, message: 'Transaction history refreshed');
          },
          columns: [
            ResponsiveTableColumn<TransactionDetail>(
              title: 'TRANSACTION NO.',
              flex: 2,
              cellBuilder: (txn) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.receipt_long_rounded, size: 16, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        txn.transactionNo,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  if (txn.beneficiaryName != null && txn.beneficiaryName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          'SC/PWD: ${txn.beneficiaryName}',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ResponsiveTableColumn<TransactionDetail>(
              title: 'DATE & TIME',
              flex: 2,
              cellBuilder: (txn) => Text(
                _dateFormat.format(txn.transactionDate),
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
              ),
            ),
            ResponsiveTableColumn<TransactionDetail>(
              title: 'ORDER TYPE',
              flex: 1,
              cellBuilder: (txn) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  txn.orderTypeName,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                ),
              ),
            ),
            ResponsiveTableColumn<TransactionDetail>(
              title: 'CASHIER',
              flex: 1,
              cellBuilder: (txn) => Text(
                txn.cashierName,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
              ),
            ),
            ResponsiveTableColumn<TransactionDetail>(
              title: 'GROSS AMOUNT',
              flex: 1,
              numeric: true,
              cellBuilder: (txn) => Text(
                '₱${txn.grossAmount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
            ),
            ResponsiveTableColumn<TransactionDetail>(
              title: 'ACTIONS',
              flex: 2,
              alignment: Alignment.centerRight,
              cellBuilder: (txn) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_rounded, size: 16),
                    label: Text('Receipt', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ReceiptPreviewDialog(transaction: txn),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                    tooltip: 'Void Transaction',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => VoidOrderDialog(
                          transactionNo: txn.transactionNo,
                          onConfirmVoid: (reason) {
                            final cashierId = _getActiveCashierId(context);
                            context.read<TransactionHistoryCubit>().voidTransaction(
                              transactionId: txn.transactionId,
                              cashierId: cashierId,
                              reason: reason,
                            );
                            AppToast.showSuccess(context, message: 'Transaction #${txn.transactionNo} voided');
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          mobileCardBuilder: (context, txn) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          txn.transactionNo,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    Text(
                      '₱${txn.grossAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_dateFormat.format(txn.transactionDate)} • ${txn.orderTypeName} • Cashier: ${txn.cashierName}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.receipt_rounded, size: 16),
                      label: Text('View Receipt', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ReceiptPreviewDialog(transaction: txn),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                      tooltip: 'Void',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => VoidOrderDialog(
                            transactionNo: txn.transactionNo,
                            onConfirmVoid: (reason) {
                              final cashierId = _getActiveCashierId(context);
                              context.read<TransactionHistoryCubit>().voidTransaction(
                                transactionId: txn.transactionId,
                                cashierId: cashierId,
                                reason: reason,
                              );
                              AppToast.showSuccess(context, message: 'Transaction #${txn.transactionNo} voided');
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
