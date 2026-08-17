import 'package:flutter/material.dart';
import 'package:suki_pos/core/enums/enums.dart';

class DiscountSelectionDialog extends StatefulWidget {
  final double currentPercentage;
  final double currentFixed;
  final Function(double percent) onApplyPercentage;
  final Function(double amount) onApplyFixed;
  final VoidCallback onRemoveDiscount;

  const DiscountSelectionDialog({
    required this.currentPercentage,
    required this.currentFixed,
    required this.onApplyPercentage,
    required this.onApplyFixed,
    required this.onRemoveDiscount,
    super.key,
  });

  @override
  State<DiscountSelectionDialog> createState() => _DiscountSelectionDialogState();
}

class _DiscountSelectionDialogState extends State<DiscountSelectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DiscountType _type = DiscountType.percentage;

  @override
  void initState() {
    super.initState();
    if (widget.currentFixed > 0) {
      _type = DiscountType.fixed;
      _amountController.text = widget.currentFixed.toStringAsFixed(2);
    } else if (widget.currentPercentage > 0) {
      _type = DiscountType.percentage;
      _amountController.text = widget.currentPercentage.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _applyQuickPercent(double percent) {
    widget.onApplyPercentage(percent);
    Navigator.of(context).pop();
  }

  void _submitCustom() {
    if (_formKey.currentState!.validate()) {
      final val = double.parse(_amountController.text);
      if (_type == DiscountType.percentage) {
        widget.onApplyPercentage(val);
      } else {
        widget.onApplyFixed(val);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Apply Manual Discount'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Percentage', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [5.0, 10.0, 15.0, 20.0].map((p) {
                return ActionChip(
                  label: Text('${p.toInt()}%'),
                  onPressed: () => _applyQuickPercent(p),
                );
              }).toList(),
            ),
            const Divider(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  SegmentedButton<DiscountType>(
                    segments: const [
                      ButtonSegment(value: DiscountType.percentage, label: Text('Percent (%)')),
                      ButtonSegment(value: DiscountType.fixed, label: Text('Fixed (₱)')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (set) => setState(() => _type = set.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _type == DiscountType.percentage ? 'Discount Percentage' : 'Discount Amount',
                      prefixText: _type == DiscountType.fixed ? '₱ ' : null,
                      suffixText: _type == DiscountType.percentage ? '%' : null,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter a value';
                      final parsed = double.tryParse(val);
                      if (parsed == null || parsed <= 0) return 'Invalid value';
                      if (_type == DiscountType.percentage && parsed > 100) {
                        return 'Cannot exceed 100%';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentPercentage > 0 || widget.currentFixed > 0)
          TextButton(
            onPressed: () {
              widget.onRemoveDiscount();
              Navigator.of(context).pop();
            },
            child: Text('Remove Discount', style: TextStyle(color: theme.colorScheme.error)),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitCustom,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
