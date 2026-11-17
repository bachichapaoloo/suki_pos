import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_cubit.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';

/// Replicates KwikPOS Lite's `cash_fund_operations.dart`:
/// Allows recording mid-shift **Cash In (Deposit)** (`movement_type = 1`)
/// and **Cash Out (Withdraw)** (`movement_type = 0`) into `cash_fund_log`.
class CashFundOperationsDialog extends StatefulWidget {
  final int cashierId;
  final String cashierName;

  const CashFundOperationsDialog({
    super.key,
    required this.cashierId,
    required this.cashierName,
  });

  @override
  State<CashFundOperationsDialog> createState() =>
      _CashFundOperationsDialogState();
}

class _CashFundOperationsDialogState extends State<CashFundOperationsDialog> {
  bool _isCashIn = true;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final reason = _reasonController.text.trim();

    if (amount <= 0) {
      AppToast.showWarning(
        context,
        message: 'Please enter a valid amount greater than ₱0.00.',
      );
      return;
    }
    if (reason.isEmpty) {
      AppToast.showWarning(
        context,
        message: 'Please enter a reason or description for this cash movement.',
      );
      return;
    }

    final ok = await context.read<ShiftCubit>().recordCashFundMovement(
      cashierId: widget.cashierId,
      isCashIn: _isCashIn,
      amount: amount,
      reason: reason,
    );

    if (!mounted) return;
    if (ok) {
      AppToast.showSuccess(
        context,
        title: _isCashIn ? 'Cash In Recorded' : 'Cash Out Recorded',
        message:
            '${_isCashIn ? "Added" : "Withdrawn"} ₱${amount.toStringAsFixed(2)} ($reason)',
      );
      Navigator.of(context).pop(true);
    } else {
      AppToast.showError(
        context,
        message: 'Failed to save cash fund movement.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormDialog(
      title: 'Cash Fund Operations (Cash In / Cash Out)',
      maxWidth: 480,
      saveLabel: _isCashIn ? 'Record Cash In' : 'Record Cash Out',
      onSave: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Operation Type',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isCashIn = true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isCashIn
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isCashIn
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE2E8F0),
                        width: _isCashIn ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.south_west_rounded,
                          size: 18,
                          color: _isCashIn
                              ? const Color(0xFF15803D)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cash In (Deposit)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isCashIn
                                ? const Color(0xFF15803D)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isCashIn = false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isCashIn
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !_isCashIn
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFE2E8F0),
                        width: !_isCashIn ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.north_east_rounded,
                          size: 18,
                          color: !_isCashIn
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cash Out (Withdraw)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: !_isCashIn
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
            decoration: InputDecoration(
              labelText: 'Amount *',
              prefixText: '₱ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'Reason / Purpose *',
              hintText: _isCashIn
                  ? 'e.g. Additional change bills from safe'
                  : 'e.g. Petty cash / Ice delivery / Cash drop',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isCashIn
                        ? 'Cash In increases your Expected Drawer Cash for X-Reading & Z-Reading.'
                        : 'Cash Out reduces your Expected Drawer Cash for X-Reading & Z-Reading.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
