import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          final success = await context.read<ShiftCubit>().openShift(cashierId, amount);
          if (context.mounted) {
            if (success) {
              AppToast.showSuccess(
                context,
                message: 'Shift opened with ₱${amount.toStringAsFixed(2)} starting cash float',
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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
      title: 'Enter Change Fund Float',
      body: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Starting Cash Float *',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter amount';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed < 0) return 'Enter a valid amount';
                  return null;
                },
              ),
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
