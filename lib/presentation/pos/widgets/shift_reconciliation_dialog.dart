import 'package:flutter/material.dart';

class ShiftReconciliationDialog extends StatefulWidget {
  final double startingFund;
  final double expectedSales;
  final Function(double actualCash, String remarks) onSubmitDeclaration;

  const ShiftReconciliationDialog({
    super.key,
    required this.startingFund,
    required this.expectedSales,
    required this.onSubmitDeclaration,
  });

  @override
  State<ShiftReconciliationDialog> createState() => _ShiftReconciliationDialogState();
}

class _ShiftReconciliationDialogState extends State<ShiftReconciliationDialog> {
  final _cashController = TextEditingController();
  final _remarksController = TextEditingController();
  double _actualCash = 0.0;

  double get _expectedTotal => widget.startingFund + widget.expectedSales;
  double get _variance => _actualCash - _expectedTotal;

  @override
  void initState() {
    super.initState();
    _cashController.text = _expectedTotal.toStringAsFixed(2);
    _actualCash = _expectedTotal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.point_of_sale_rounded),
          SizedBox(width: 8),
          Text('End of Shift Cash Declaration'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildRow('Starting Cash Fund:', '₱${widget.startingFund.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildRow('Total Cash Sales Today:', '₱${widget.expectedSales.toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    _buildRow(
                      'Expected Total Cash:',
                      '₱${_expectedTotal.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Actual Cash Counted (Cash Drawer)',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    _actualCash = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _variance == 0
                      ? Colors.green.withOpacity(0.1)
                      : (_variance > 0 ? Colors.blue.withOpacity(0.1) : colorScheme.errorContainer),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _variance == 0 ? 'Balanced' : (_variance > 0 ? 'Over Cash:' : 'Short Cash:'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _variance == 0
                            ? Colors.green[800]
                            : (_variance > 0 ? Colors.blue[800] : colorScheme.onErrorContainer),
                      ),
                    ),
                    Text(
                      '₱${_variance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _variance == 0
                            ? Colors.green[800]
                            : (_variance > 0 ? Colors.blue[800] : colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Shift Remarks / Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
          onPressed: () {
            widget.onSubmitDeclaration(_actualCash, _remarksController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Submit & Close Shift'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}
