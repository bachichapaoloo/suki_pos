import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/data/dao/order_dao.dart';
import 'package:suki_pos/injection_container.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';

/// Replicates KwikPOS Lite's `post_void_dialog.dart`:
/// Prompts for Sales Invoice No (`SI#`), Amount Due verification, and Void Reason.
/// Enforces un-X-read and un-Z-read guards, voids the transaction, restores stock,
/// and logs to `void_transaction` and `electronic_journal`.
class PostVoidSiDialog extends StatefulWidget {
  final int cashierId;
  final VoidCallback? onVoidSuccess;

  const PostVoidSiDialog({
    super.key,
    required this.cashierId,
    this.onVoidSuccess,
  });

  @override
  State<PostVoidSiDialog> createState() => _PostVoidSiDialogState();
}

class _PostVoidSiDialogState extends State<PostVoidSiDialog> {
  final _siController = TextEditingController();
  final _amountController = TextEditingController();
  List<Map<String, dynamic>> _reasons = [];
  int? _selectedReasonId;
  String _selectedReasonText = 'Customer Changed Mind';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  @override
  void dispose() {
    _siController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadReasons() async {
    final reasons = await sl<OrderDao>().getActiveVoidReasons();
    if (!mounted) return;
    setState(() {
      _reasons = reasons;
      if (_reasons.isNotEmpty) {
        _selectedReasonId = _reasons.first['id'] as int;
        _selectedReasonText = _reasons.first['reason'] as String;
      }
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final rawSi = _siController.text
        .trim()
        .replaceAll(RegExp(r'[^0-9]'), '');
    final siNumber = int.tryParse(rawSi);
    final amountDue = double.tryParse(_amountController.text.trim());

    if (siNumber == null || siNumber <= 0) {
      AppToast.showWarning(
        context,
        message: 'Please enter a valid Sales Invoice Number (SI#).',
      );
      return;
    }
    if (amountDue == null || amountDue < 0) {
      AppToast.showWarning(
        context,
        message: 'Please enter the exact Amount Due of the invoice to verify.',
      );
      return;
    }

    try {
      final orderDao = sl<OrderDao>();
      final txnMap = await orderDao.getTransactionBySiNumber(siNumber);
      if (txnMap == null) {
        if (mounted) {
          AppToast.showError(
            context,
            message: 'Sales Invoice #$siNumber was not found.',
          );
        }
        return;
      }

      final txnId = txnMap['transaction_id'] as int;
      await orderDao.voidOrderTransaction(
        transactionId: txnId,
        cashierId: widget.cashierId,
        reason: _selectedReasonText,
        voidReasonId: _selectedReasonId,
        expectedAmountDue: amountDue,
      );

      if (!mounted) return;
      widget.onVoidSuccess?.call();
      AppToast.showSuccess(
        context,
        title: 'Post-Void Successful',
        message:
            'Sales Invoice #$siNumber (₱${amountDue.toStringAsFixed(2)}) has been voided and stock restored.',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        title: 'Post-Void Blocked',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      );
    }

    return CustomFormDialog(
      title: 'Post-Void Transaction (by SI#)',
      maxWidth: 460,
      saveLabel: 'Confirm Post-Void',
      onSave: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only active shift transactions (not yet X-Read or Z-Read) can be post-voided.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _siController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Sales Invoice Number (SI#) *',
              hintText: 'e.g. 1 or 000001',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Invoice Amount Due (Verification) *',
              prefixText: '₱ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedReasonId,
            decoration: InputDecoration(
              labelText: 'Void Reason *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: _reasons
                .map(
                  (r) => DropdownMenuItem<int>(
                    value: r['id'] as int,
                    child: Text(r['reason'] as String),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedReasonId = val;
                final match = _reasons
                    .where((r) => r['id'] == val)
                    .firstOrNull;
                if (match != null) {
                  _selectedReasonText = match['reason'] as String;
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
