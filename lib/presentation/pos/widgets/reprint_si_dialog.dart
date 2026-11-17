import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/data/dao/order_dao.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';
import 'package:suki_pos/injection_container.dart';
import 'package:suki_pos/presentation/pos/widgets/receipt_preview_dialog.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';

/// Allows reprinting any Sales Invoice by entering its `SI#` or picking from recent transactions.
class ReprintSiDialog extends StatefulWidget {
  const ReprintSiDialog({super.key});

  @override
  State<ReprintSiDialog> createState() => _ReprintSiDialogState();
}

class _ReprintSiDialogState extends State<ReprintSiDialog> {
  final _siController = TextEditingController();
  List<Map<String, dynamic>> _recentTxns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _siController.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final rows = await sl<OrderDao>().getTransactionHistory(limit: 10);
    if (!mounted) return;
    setState(() {
      _recentTxns = rows;
      if (_recentTxns.isNotEmpty) {
        final latestSi =
            (_recentTxns.first['si_number'] as num?)?.toInt() ??
            (_recentTxns.first['transaction_id'] as int);
        _siController.text = latestSi.toString();
      }
      _loading = false;
    });
  }

  Future<void> _openReceiptForSi(int siNumber) async {
    final orderDao = sl<OrderDao>();
    final map = await orderDao.getTransactionBySiNumber(siNumber);
    if (map == null) {
      if (mounted) {
        AppToast.showError(
          context,
          message: 'Sales Invoice #$siNumber not found.',
        );
      }
      return;
    }

    final txnId = map['transaction_id'] as int;
    final resolvedSi = (map['si_number'] as num?)?.toInt() ?? txnId;
    final lineMaps = await orderDao.getTransactionLineDetails(txnId);
    final List<TransactionLineDetail> lines = [];

    for (final line in lineMaps) {
      final soiId = line['sales_order_item_id'] as int?;
      List<String> options = [];
      if (soiId != null) {
        options = await orderDao.getOrderItemOptions(soiId);
      }
      lines.add(
        TransactionLineDetail(
          itemId: line['item_id'] as int? ?? 0,
          itemName: line['item_name'] as String? ?? 'Item',
          barcode: line['barcode'] as String? ?? '',
          quantity: (line['quantity'] as num? ?? 1).toInt(),
          unitPrice: (line['unit_price'] as num? ?? 0.0).toDouble(),
          amount: (line['amount'] as num? ?? 0.0).toDouble(),
          lineDiscount: (line['line_discount'] as num? ?? 0.0).toDouble(),
          isFreeItem:
              (line['amount'] as num? ?? 1) == 0 &&
              (line['quantity'] as num? ?? 0) > 0,
          selectedOptions: options,
        ),
      );
    }

    final detail = TransactionDetail(
      transactionId: txnId,
      salesOrderId: map['sales_order_id'] as int? ?? 0,
      transactionNo: 'SI-${resolvedSi.toString().padLeft(6, '0')}',
      grossAmount: (map['gross_amount'] as num? ?? 0.0).toDouble(),
      netAmount: (map['net_amount'] as num? ?? 0.0).toDouble(),
      cashTendered: (map['cash_tendered'] as num? ?? 0.0).toDouble(),
      changeGiven: (map['change_given'] as num? ?? 0.0).toDouble(),
      paymentMethodName: map['payment_method_name'] as String? ?? 'Cash',
      cashierName: map['cashier_name'] as String? ?? 'Admin',
      orderTypeName: map['order_type_name'] as String? ?? 'Dine-In',
      guestCount: (map['guest_count'] as num? ?? 1).toInt(),
      eligibleGuestCount: (map['eligible_guest_count'] as num? ?? 0).toInt(),
      discountName: map['discount_name'] as String?,
      itemDiscountAmount:
          (map['item_discount_amount'] as num? ?? 0.0).toDouble(),
      orderDiscountAmount:
          (map['order_discount_amount'] as num? ?? 0.0).toDouble(),
      surchargeAmount: (map['surcharge_amount'] as num? ?? 0.0).toDouble(),
      vatableSales: (map['vatable_sales'] as num? ?? 0.0).toDouble(),
      vatAmount: (map['vat_amount'] as num? ?? 0.0).toDouble(),
      vatExemptSales: (map['vat_exempt_sales'] as num? ?? 0.0).toDouble(),
      zeroRatedSales: (map['zero_rated_sales'] as num? ?? 0.0).toDouble(),
      beneficiaryName: map['beneficiary_name'] as String?,
      beneficiaryIdNo: map['beneficiary_id_no'] as String?,
      referenceNumber: map['reference_number'] as String?,
      bankName: map['bank_name'] as String?,
      transactionDate: DateTime.parse(map['transaction_date'] as String),
      lines: lines,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (_) => ReceiptPreviewDialog(transaction: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      );
    }

    return CustomFormDialog(
      title: 'Reprint Sales Invoice (by SI#)',
      maxWidth: 480,
      saveLabel: 'Preview & Reprint',
      onSave: () {
        final raw = _siController.text
            .trim()
            .replaceAll(RegExp(r'[^0-9]'), '');
        final si = int.tryParse(raw);
        if (si != null && si > 0) {
          _openReceiptForSi(si);
        }
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _siController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Sales Invoice Number (SI#)',
              hintText: 'Enter SI# to reprint',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (_recentTxns.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Recent Sales Invoices',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _recentTxns.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = _recentTxns[index];
                  final si =
                      (row['si_number'] as num?)?.toInt() ??
                      (row['transaction_id'] as int);
                  final net = (row['net_amount'] as num? ?? 0.0).toDouble();
                  final isVoid = (row['is_voided'] as num? ?? 0).toInt() == 1;
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    title: Text(
                      'SI-${si.toString().padLeft(6, '0')}${isVoid ? " (VOIDED)" : ""}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isVoid
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      '${row['payment_method_name'] ?? 'Cash'} • ${(row['transaction_date'] as String).substring(0, 16)}',
                      style: GoogleFonts.inter(fontSize: 11.5),
                    ),
                    trailing: Text(
                      '₱${net.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () => _openReceiptForSi(si),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
