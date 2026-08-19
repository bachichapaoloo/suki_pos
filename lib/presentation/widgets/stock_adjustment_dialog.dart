import 'package:flutter/material.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/domain/entities/inventory/stock_with_item.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final StockWithItem stockItem;
  final Function(double delta, String remarks) onConfirm;

  const StockAdjustmentDialog({
    required this.stockItem,
    required this.onConfirm,
    super.key,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _remarksController = TextEditingController();
  AdjustmentType _type = AdjustmentType.stockIn;

  @override
  void dispose() {
    _qtyController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final inputQty = double.parse(_qtyController.text);
      final delta = _type == AdjustmentType.stockIn ? inputQty : -inputQty;
      final remarks = _remarksController.text.trim().isEmpty
          ? (_type == AdjustmentType.stockIn ? 'Stock Receiving' : 'Spoiled / Damaged')
          : _remarksController.text.trim();

      widget.onConfirm(delta, remarks);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = widget.stockItem.unitName ?? 'units';

    return ConfirmationDialog(
      title: 'Stock Adjustment',
      variant: DialogVariant.info,
      confirmLabel: 'Confirm Adjustment',
      cancelLabel: 'Cancel',
      onConfirm: _submit,
      onCancel: () => Navigator.of(context).pop(),
      body: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.stockItem.itemName} (${widget.stockItem.itemCode})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current On-Hand:'),
                    Text(
                      '${widget.stockItem.stock.quantity} $unitLabel',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<AdjustmentType>(
                segments: const [
                  ButtonSegment(
                    value: AdjustmentType.stockIn, // 👈 Fixed: was stockOut
                    label: Text('Stock-In (+)'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                  ButtonSegment(
                    value: AdjustmentType.stockOut,
                    label: Text('Stock-Out (-)'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (set) {
                  setState(() => _type = set.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _type == AdjustmentType.stockIn ? 'Quantity Received*' : 'Quantity Removed*',
                  border: const OutlineInputBorder(),
                  suffixText: unitLabel,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter quantity';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'Enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Reference (PO#, Reason)', // 👈 Fixed: typo
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
