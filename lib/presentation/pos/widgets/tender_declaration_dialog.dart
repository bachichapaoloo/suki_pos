import 'package:flutter/material.dart';
import '../../../../domain/entities/shift/cash_denomination_count.dart';

class TenderDeclarationDialog extends StatefulWidget {
  final Function(List<CashDenominationCount> denominations, double totalCash) onConfirm;

  const TenderDeclarationDialog({super.key, required this.onConfirm});

  @override
  State<TenderDeclarationDialog> createState() => _TenderDeclarationDialogState();
}

class _TenderDeclarationDialogState extends State<TenderDeclarationDialog> {
  final Map<double, TextEditingController> _controllers = {};

  static const List<double> _denominations = [1000.0, 500.0, 200.0, 100.0, 50.0, 20.0, 10.0, 5.0, 1.0, 0.25];

  @override
  void initState() {
    super.initState();
    for (final d in _denominations) {
      _controllers[d] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalAmount {
    double sum = 0.0;
    _controllers.forEach((denom, controller) {
      final count = int.tryParse(controller.text) ?? 0;
      sum += (denom * count);
    });
    return sum;
  }

  void _submit() {
    final List<CashDenominationCount> list = [];
    _controllers.forEach((denom, controller) {
      final count = int.tryParse(controller.text) ?? 0;
      list.add(CashDenominationCount(denomination: denom, count: count));
    });

    widget.onConfirm(list, _totalAmount);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Cash Drawer Count / Tender Declaration'),
      content: SizedBox(
        width: 450,
        height: 480,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _denominations.length,
                itemBuilder: (context, index) {
                  final denom = _denominations[index];
                  final ctrl = _controllers[denom]!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            '₱${denom >= 1 ? denom.toInt() : denom.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text('x'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: Text(
                            '₱${((int.tryParse(ctrl.text) ?? 0) * denom).toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Declared Cash Total:', style: theme.textTheme.titleMedium),
                  Text(
                    '₱${_totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
          onPressed: _submit,
          child: const Text('Save Declaration'),
        ),
      ],
    );
  }
}
