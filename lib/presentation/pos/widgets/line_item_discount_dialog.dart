import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';

class LineItemDiscountDialog extends StatefulWidget {
  final CartItem cartItem;
  final Function({double? percent, double? fixedAmount}) onApplyDiscount;
  final VoidCallback onToggleFreeItem;
  final VoidCallback onToggleDiscountExempt;
  final VoidCallback onRemoveDiscount;

  const LineItemDiscountDialog({
    super.key,
    required this.cartItem,
    required this.onApplyDiscount,
    required this.onToggleFreeItem,
    required this.onToggleDiscountExempt,
    required this.onRemoveDiscount,
  });

  @override
  State<LineItemDiscountDialog> createState() => _LineItemDiscountDialogState();
}

class _LineItemDiscountDialogState extends State<LineItemDiscountDialog> {
  final _amountController = TextEditingController();
  bool _isPercentage = true;
  late bool _isFreeItem;
  late bool _isDiscountExempt;

  final List<double> _quickPercentages = [5, 10, 15, 20, 50];

  @override
  void initState() {
    super.initState();
    _isFreeItem = widget.cartItem.isFreeItem;
    _isDiscountExempt = widget.cartItem.isDiscountExempt;

    if (widget.cartItem.itemDiscountPercent > 0) {
      _isPercentage = true;
      _amountController.text = widget.cartItem.itemDiscountPercent.toStringAsFixed(0);
    } else if (widget.cartItem.itemDiscountAmount > 0) {
      _isPercentage = false;
      _amountController.text = widget.cartItem.itemDiscountAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _applyQuickPercent(double percent) {
    widget.onApplyDiscount(percent: percent);
    AppToast.showSuccess(
      context,
      message: '${percent.toStringAsFixed(0)}% discount applied to ${widget.cartItem.item.name}',
      title: 'Line Discount Applied',
    );
    Navigator.of(context).pop();
  }

  void _submitCustom() {
    if (_isFreeItem) {
      Navigator.of(context).pop();
      return;
    }

    final text = _amountController.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final value = double.tryParse(text);
    if (value == null || value <= 0) {
      AppToast.showWarning(context, message: 'Please enter a valid positive discount value');
      return;
    }

    if (_isPercentage) {
      if (value > 100) {
        AppToast.showWarning(context, message: 'Percentage discount cannot exceed 100%');
        return;
      }
      widget.onApplyDiscount(percent: value);
      AppToast.showSuccess(
        context,
        message: '${value.toStringAsFixed(0)}% discount applied to ${widget.cartItem.item.name}',
        title: 'Line Discount Applied',
      );
    } else {
      if (value > widget.cartItem.totalPrice) {
        AppToast.showWarning(context, message: 'Fixed discount cannot exceed item total (₱${widget.cartItem.totalPrice.toStringAsFixed(2)})');
        return;
      }
      widget.onApplyDiscount(fixedAmount: value);
      AppToast.showSuccess(
        context,
        message: '₱${value.toStringAsFixed(2)} discount applied to ${widget.cartItem.item.name}',
        title: 'Line Discount Applied',
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = widget.cartItem;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.discount_rounded, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Line Discount & Promo',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        '${item.quantity}x ${item.item.name} • ₱${item.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Percentage Presets
            Text(
              'QUICK PERCENTAGE',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickPercentages.map((percent) {
                final isSelected = item.itemDiscountPercent == percent && !_isFreeItem;
                return ActionChip(
                  label: Text('${percent.toStringAsFixed(0)}% OFF'),
                  backgroundColor: isSelected ? colorScheme.primary : const Color(0xFFF1F5F9),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  ),
                  side: BorderSide(
                    color: isSelected ? colorScheme.primary : const Color(0xFFE2E8F0),
                  ),
                  onPressed: () => _applyQuickPercent(percent),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Custom Discount Mode
            Text(
              'CUSTOM AMOUNT / PERCENTAGE',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Percent (%)')),
                      ButtonSegment(value: false, label: Text('Fixed (₱)')),
                    ],
                    selected: {_isPercentage},
                    onSelectionChanged: (set) => setState(() => _isPercentage = set.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isFreeItem,
              decoration: InputDecoration(
                labelText: _isPercentage ? 'Discount Percentage (%)' : 'Discount Amount (₱)',
                prefixText: _isPercentage ? null : '₱ ',
                suffixText: _isPercentage ? '%' : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: _isFreeItem ? const Color(0xFFF1F5F9) : Colors.white,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Special Toggles: 100% Free / Complimentary & Order Discount Exemption
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '100% Free / Complimentary Item',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
              ),
              subtitle: Text(
                'Marks line total as ₱0.00 (Owner / Promo meal)',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              value: _isFreeItem,
              activeColor: Colors.green.shade600,
              onChanged: (val) {
                setState(() => _isFreeItem = val);
                widget.onToggleFreeItem();
                if (val) {
                  AppToast.showSuccess(context, message: '${item.item.name} marked as 100% Complimentary');
                  Navigator.of(context).pop();
                }
              },
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Exempt from Order Discounts',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
              ),
              subtitle: Text(
                'Protects item price when applying global SC/PWD/Promo discounts',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              value: _isDiscountExempt,
              activeColor: colorScheme.primary,
              onChanged: (val) {
                setState(() => _isDiscountExempt = val);
                widget.onToggleDiscountExempt();
              },
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.hasItemDiscount)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    label: Text(
                      'Remove Discount',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent),
                    ),
                    onPressed: () {
                      widget.onRemoveDiscount();
                      AppToast.showInfo(context, message: 'Line discount removed');
                      Navigator.of(context).pop();
                    },
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submitCustom,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
