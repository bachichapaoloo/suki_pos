import 'package:flutter/material.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(int paymentMethodId, double cashTendered) onPay;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onPay,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _cashController = TextEditingController();
  int _selectedMethod = 1; // 1 = Cash, 2 = Card, 3 = E-Wallet
  double _change = 0.0;

  @override
  void initState() {
    super.initState();
    _cashController.text = widget.totalAmount.toStringAsFixed(2);
    _calculateChange();
  }

  void _calculateChange() {
    final tendered = double.tryParse(_cashController.text) ?? 0.0;
    setState(() {
      _change = tendered - widget.totalAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Payment & Checkout'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount Due:'),
                  Text(
                    '₱${widget.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Cash')),
                ButtonSegment(value: 2, label: Text('Card')),
                ButtonSegment(value: 3, label: Text('GCash')),
              ],
              selected: {_selectedMethod},
              onSelectionChanged: (set) => setState(() => _selectedMethod = set.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount Tendered',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculateChange(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Change:'),
                Text(
                  '₱${_change >= 0 ? _change.toStringAsFixed(2) : "0.00"}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _change < 0 ? theme.colorScheme.error : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _change < 0 && _selectedMethod == 1
              ? null
              : () {
                  final tendered = double.tryParse(_cashController.text) ?? widget.totalAmount;
                  widget.onPay(_selectedMethod, tendered);
                  Navigator.of(context).pop();
                },
          child: const Text('Complete Sale'),
        ),
      ],
    );
  }
}
