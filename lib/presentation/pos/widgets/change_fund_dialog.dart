import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_cubit.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';

class ChangeFundDialog extends StatefulWidget {
  final Function(double amount) onConfirm;

  const ChangeFundDialog({super.key, required this.onConfirm});

  static Future<bool?> show(BuildContext context, {required int cashierId}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ChangeFundDialog(
        onConfirm: (amount) async {
          final success = await context.read<ShiftCubit>().openShift(
            cashierId,
            amount,
          );
          if (context.mounted) {
            if (success) {
              AppToast.showSuccess(
                context,
                message:
                    'Shift opened with ₱${amount.toStringAsFixed(2)} starting cash float',
                title: 'Register Shift Started',
              );
            } else {
              AppToast.showError(
                context,
                message: 'Failed to open register shift.',
                title: 'Shift Error',
              );
            }
          }
        },
      ),
    );
  }

  @override
  State<ChangeFundDialog> createState() => _ChangeFundDialogState();
}

class _ChangeFundDialogState extends State<ChangeFundDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '1000.00');
  bool _useDenominations = false;
  final Map<double, TextEditingController> _denomControllers = {};

  static const List<double> _denominations = [
    1000,
    500,
    200,
    100,
    50,
    20,
    10,
    5,
    1,
  ];

  @override
  void initState() {
    super.initState();
    for (final d in _denominations) {
      _denomControllers[d] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    for (final c in _denomControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _recalcFromDenominations() {
    double sum = 0.0;
    _denomControllers.forEach((denom, ctrl) {
      final qty = int.tryParse(ctrl.text) ?? 0;
      sum += denom * qty;
    });
    _amountController.text = sum.toStringAsFixed(2);
    setState(() {});
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      widget.onConfirm(amount);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: 'Enter Opening Change Fund (Cash Float)',
      body: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                readOnly: _useDenominations,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Starting Cash Float *',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter amount';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _useDenominations = !_useDenominations;
                      if (_useDenominations) {
                        _recalcFromDenominations();
                      }
                    });
                  },
                  icon: Icon(
                    _useDenominations
                        ? Icons.edit_rounded
                        : Icons.calculate_outlined,
                    size: 16,
                  ),
                  label: Text(
                    _useDenominations
                        ? 'Enter Direct Total Instead'
                        : 'Count by Bill / Coin Denominations',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_useDenominations) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _denominations.map((d) {
                        final ctrl = _denomControllers[d]!;
                        final count = int.tryParse(ctrl.text) ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '₱${d.toInt()}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                height: 34,
                                child: TextField(
                                  controller: ctrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (_) => _recalcFromDenominations(),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '₱${(d * count).toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      confirmLabel: 'Open Register Shift',
      onConfirm: _submit,
      variant: DialogVariant.info,
      contentAlignment: TextAlign.center,
      showCancel: true,
      onCancel: () => Navigator.of(context).pop(false),
    );
  }
}
