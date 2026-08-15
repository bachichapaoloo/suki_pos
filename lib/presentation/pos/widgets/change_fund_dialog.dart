import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.monetization_on_outlined, color: Color(0xFF355C8F)),
          SizedBox(width: 8),
          Text('Enter Change Fund'),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Declare starting cash float to open the POS register shift:'),
              const SizedBox(height: 16),
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
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _submit,
              child: const Text('Open Register Shift'),
            ),
          ],
        ),
      ],
    );
  }
}
