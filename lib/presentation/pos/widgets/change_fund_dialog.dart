import 'package:flutter/material.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';

class ChangeFundDialog extends StatefulWidget {
  final Function(double amount) onConfirm;

  const ChangeFundDialog({super.key, required this.onConfirm});

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
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: 'Enter Change Fund',
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
                  labelText: 'Starting Cash Float*',
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
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
