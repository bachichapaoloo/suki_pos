import 'package:flutter/material.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/injection_container.dart';

class PaymentDialog extends StatefulWidget {
  final double totalDue;
  final Function(int methodId, String methodName, double tendered, double change) onComplete;

  const PaymentDialog({super.key, required this.totalDue, required this.onComplete});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  List<Map<String, dynamic>> _methods = [];
  int? _selectedMethodId;
  String _selectedMethodName = 'Cash';
  final _tenderController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    final db = await sl<DatabaseHelper>().database;
    final results = await db.query(
      SchemaConstants.paymentMethod,
      where: 'is_active = 1',
      orderBy: 'id ASC',
    );
    setState(() {
      _methods = results;
      if (results.isNotEmpty) {
        _selectedMethodId = results.first['id'] as int;
        _selectedMethodName = results.first['name'] as String;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(content: Center(child: CircularProgressIndicator()));
    }

    final tendered = double.tryParse(_tenderController.text) ?? 0.0;
    final change = tendered >= widget.totalDue ? tendered - widget.totalDue : 0.0;

    return AlertDialog(
      title: const Text('Process Payment'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Payment Method:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _methods.map((m) {
                final isSelected = m['id'] == _selectedMethodId;
                return ChoiceChip(
                  label: Text(m['name'] as String),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedMethodId = m['id'] as int;
                        _selectedMethodName = m['name'] as String;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tenderController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount Tendered',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Change Due:'),
                Text(
                  '₱ ${change.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tendered >= widget.totalDue ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: tendered >= widget.totalDue && _selectedMethodId != null
              ? () {
                  widget.onComplete(_selectedMethodId!, _selectedMethodName, tendered, change);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Complete Payment'),
        ),
      ],
    );
  }
}
