import 'package:flutter/material.dart';

class VoidOrderDialog extends StatefulWidget {
  final String transactionNo;
  final Function(String reason) onConfirmVoid;

  const VoidOrderDialog({
    super.key,
    required this.transactionNo,
    required this.onConfirmVoid,
  });

  @override
  State<VoidOrderDialog> createState() => _VoidOrderDialogState();
}

class _VoidOrderDialogState extends State<VoidOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onConfirmVoid(_reasonController.text.trim());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Text('Void Transaction ${widget.transactionNo}'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voiding this transaction will cancel the sales record, restore all items back to inventory, and log an Electronic Journal audit entry.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Void Reason / Manager Remarks*',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a valid reason for voiding.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: _submit,
          child: const Text('Confirm Void'),
        ),
      ],
    );
  }
}
