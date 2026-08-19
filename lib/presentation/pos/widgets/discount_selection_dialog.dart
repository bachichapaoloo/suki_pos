import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart' as domain;
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_bloc.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_state.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';

class DiscountSelectionDialog extends StatefulWidget {
  final domain.Discount? currentDiscount;
  final double currentPercentage;
  final double currentFixed;
  final Function(domain.Discount discount) onApplyDiscount;
  final Function(double percent) onApplyPercentage;
  final Function(double amount) onApplyFixed;
  final VoidCallback onRemoveDiscount;

  const DiscountSelectionDialog({
    required this.onApplyDiscount,
    required this.currentDiscount,
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
    final hasActiveDiscount = widget.currentDiscount != null || widget.currentPercentage > 0 || widget.currentFixed > 0;

    return ConfirmationDialog(
      title: 'Apply Discount',
      variant: DialogVariant.info,
      confirmLabel: 'Apply',
      cancelLabel: 'Cancel',
      // Custom content widget:
      body: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Configured Store Discounts
            Text(
              'STORE DISCOUNTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            BlocBuilder<DiscountBloc, DiscountState>(
              builder: (context, state) {
                if (state is DiscountLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (state is DiscountLoaded) {
                  final activeDiscounts = state.discounts.where((d) => d.isActive).toList();
                  if (activeDiscounts.isEmpty) {
                    return const Text(
                      'No active discounts configured.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activeDiscounts.map((discount) {
                      final isSelected = widget.currentDiscount?.id == discount.id;
                      final rateText = discount.isPercentage
                          ? '${discount.percentage?.toStringAsFixed(0)}%'
                          : '₱${discount.fixedAmount?.toStringAsFixed(0)}';

                      return ChoiceChip(
                        label: Text('${discount.name} ($rateText)'),
                        selected: isSelected,
                        onSelected: (_) {
                          widget.onApplyDiscount(discount);
                          Navigator.of(context).pop();
                        },
                      );
                    }).toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),

            // 2. Manual Custom Input
            Text(
              'MANUAL OVERRIDE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

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
                  const SizedBox(height: 12),
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

            // 3. Remove Discount Option
            if (hasActiveDiscount) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[300]!),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove Current Discount'),
                  onPressed: () {
                    widget.onRemoveDiscount();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      onConfirm: _submitCustom,
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
