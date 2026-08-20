import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/maintenance/option_group.dart';
import 'package:suki_pos/domain/entities/maintenance/option_value.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';

class LineItemActionDialog extends StatefulWidget {
  final CartItem cartItem;
  final List<OptionGroup> optionGroups;
  final Function(CartItem updatedItem) onSave;
  final VoidCallback onRemove;

  const LineItemActionDialog({
    super.key,
    required this.cartItem,
    required this.optionGroups,
    required this.onSave,
    required this.onRemove,
  });

  static Future<void> show(
    BuildContext context, {
    required CartItem cartItem,
    required List<OptionGroup> optionGroups,
    required Function(CartItem updatedItem) onSave,
    required VoidCallback onRemove,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LineItemActionDialog(
        cartItem: cartItem,
        optionGroups: optionGroups,
        onSave: onSave,
        onRemove: onRemove,
      ),
    );
  }

  @override
  State<LineItemActionDialog> createState() => _LineItemActionDialogState();
}

class _LineItemActionDialogState extends State<LineItemActionDialog> {
  late bool _isDiscountExempt;
  late bool _isFreeItem;
  late double _itemDiscountPercent;
  late double _itemDiscountAmount;
  late TextEditingController _notesCtrl;
  late TextEditingController _discPercentCtrl;
  late TextEditingController _discFixedCtrl;
  final Map<int, List<OptionValue>> _selectedSelections = {};

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    final item = widget.cartItem;
    _isDiscountExempt = item.isDiscountExempt;
    _isFreeItem = item.isFreeItem;
    _itemDiscountPercent = item.itemDiscountPercent;
    _itemDiscountAmount = item.itemDiscountAmount;
    _notesCtrl = TextEditingController(text: item.notes ?? '');
    _discPercentCtrl = TextEditingController(
      text: _itemDiscountPercent > 0 ? _itemDiscountPercent.toStringAsFixed(0) : '',
    );
    _discFixedCtrl = TextEditingController(
      text: _itemDiscountAmount > 0 ? _itemDiscountAmount.toStringAsFixed(2) : '',
    );

    for (final option in item.selectedOptions) {
      _selectedSelections.putIfAbsent(option.optionGroupId, () => []).add(option);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _discPercentCtrl.dispose();
    _discFixedCtrl.dispose();
    super.dispose();
  }

  void _applyFixedDiscount(double amt) {
    setState(() {
      _isFreeItem = false;
      _itemDiscountAmount = amt;
      _itemDiscountPercent = 0.0;
      _discFixedCtrl.text = amt > 0 ? amt.toStringAsFixed(2) : '';
      _discPercentCtrl.clear();
    });
  }

  void _applyPercentDiscount(double pct) {
    setState(() {
      _isFreeItem = false;
      _itemDiscountPercent = pct;
      _itemDiscountAmount = 0.0;
      _discPercentCtrl.text = pct > 0 ? pct.toStringAsFixed(0) : '';
      _discFixedCtrl.clear();
    });
  }

  void _clearLineDiscount() {
    setState(() {
      _isFreeItem = false;
      _itemDiscountPercent = 0.0;
      _itemDiscountAmount = 0.0;
      _discPercentCtrl.clear();
      _discFixedCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.cartItem;
    final flatOptions = _selectedSelections.values.expand((list) => list).toList();

    // Compute preview price
    double baseUnitPrice = item.unitPrice;
    double previewLineTotal = baseUnitPrice * item.quantity;
    if (_isFreeItem) {
      previewLineTotal = 0.0;
    } else if (_itemDiscountPercent > 0) {
      previewLineTotal -= (previewLineTotal * (_itemDiscountPercent / 100));
    } else if (_itemDiscountAmount > 0) {
      previewLineTotal -= _itemDiscountAmount;
    }
    if (previewLineTotal < 0) previewLineTotal = 0.0;

    return CustomFormDialog(
      title: 'Item Options & Line Discounts',
      maxWidth: 540,
      saveLabel: 'Apply Changes',
      onSave: () {
        final updated = item.copyWith(
          selectedOptions: flatOptions,
          notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
          isDiscountExempt: _isDiscountExempt,
          isFreeItem: _isFreeItem,
          itemDiscountPercent: _isFreeItem ? 0.0 : (double.tryParse(_discPercentCtrl.text) ?? 0.0),
          itemDiscountAmount: _isFreeItem ? 0.0 : (double.tryParse(_discFixedCtrl.text) ?? 0.0),
        );
        widget.onSave(updated);
        Navigator.of(context).pop();
      },
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Overview Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.item.name,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Qty: ${item.quantity}x • Base Price: ₱${item.unitPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Line Total', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                      Text(
                        '₱${previewLineTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _isFreeItem ? const Color(0xFF15803D) : primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. FREE ITEM / COMPLIMENTARY TOGGLE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isFreeItem ? const Color(0xFFDCFCE7) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isFreeItem ? const Color(0xFF86EFAC) : surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        color: _isFreeItem ? const Color(0xFF15803D) : const Color(0xFF64748B),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Free Item / Manager Comp',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isFreeItem ? const Color(0xFF15803D) : textDark,
                            ),
                          ),
                          Text(
                            '100% complimentary item (${item.unitPrice.toStringAsFixed(2)})',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: _isFreeItem,
                    activeColor: const Color(0xFF15803D),
                    onChanged: (val) {
                      setState(() {
                        _isFreeItem = val;
                        if (val) {
                          _itemDiscountPercent = 0.0;
                          _itemDiscountAmount = 0.0;
                          _discPercentCtrl.clear();
                          _discFixedCtrl.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. DISCOUNT EXEMPTION TOGGLE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isDiscountExempt ? const Color(0xFFF1F5F9) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isDiscountExempt ? primaryBlue.withOpacity(0.4) : surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.money_off_rounded,
                        color: _isDiscountExempt ? primaryBlue : const Color(0xFF64748B),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discount Exempt',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isDiscountExempt ? primaryBlue : textDark,
                            ),
                          ),
                          Text(
                            'Exempt from Senior/PWD & order discounts',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: _isDiscountExempt,
                    activeColor: primaryBlue,
                    onChanged: (val) => setState(() => _isDiscountExempt = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. ITEM-LEVEL DIRECT DISCOUNT
            if (!_isFreeItem) ...[
              Text(
                'Line Item Discount',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 8),

              // Quick Percentage & Fixed Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDiscountChip('5% Off', () => _applyPercentDiscount(5)),
                    const SizedBox(width: 6),
                    _buildDiscountChip('10% Off', () => _applyPercentDiscount(10)),
                    const SizedBox(width: 6),
                    _buildDiscountChip('20% Off', () => _applyPercentDiscount(20)),
                    const SizedBox(width: 6),
                    _buildDiscountChip('50% Off', () => _applyPercentDiscount(50)),
                    const SizedBox(width: 6),
                    _buildDiscountChip('₱20 Off', () => _applyFixedDiscount(20)),
                    const SizedBox(width: 6),
                    _buildDiscountChip('₱50 Off', () => _applyFixedDiscount(50)),
                    const SizedBox(width: 6),
                    _buildDiscountChip('₱100 Off', () => _applyFixedDiscount(100)),
                    const SizedBox(width: 6),
                    _buildDiscountChip('Clear', _clearLineDiscount, isClear: true),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Custom Discount Inputs
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _discPercentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Discount Percentage',
                        suffixText: '%',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val) ?? 0.0;
                        setState(() {
                          _itemDiscountPercent = parsed;
                          if (parsed > 0) {
                            _itemDiscountAmount = 0.0;
                            _discFixedCtrl.clear();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _discFixedCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Fixed Discount Amount',
                        prefixText: '₱ ',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val) ?? 0.0;
                        setState(() {
                          _itemDiscountAmount = parsed;
                          if (parsed > 0) {
                            _itemDiscountPercent = 0.0;
                            _discPercentCtrl.clear();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            // 4. LINE SPECIAL NOTES
            Text(
              'Special Preparation Notes',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Less sugar, Extra ice, No dairy',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 18),

            // Remove Button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRemove();
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                label: Text(
                  'Remove from Cart',
                  style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountChip(String label, VoidCallback onTap, {bool isClear = false}) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isClear ? Colors.redAccent : primaryBlue,
        ),
      ),
      backgroundColor: isClear ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
      side: BorderSide(color: isClear ? Colors.red.withOpacity(0.3) : surfaceBorder),
      onPressed: onTap,
    );
  }
}
