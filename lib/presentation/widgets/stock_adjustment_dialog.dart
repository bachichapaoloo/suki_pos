import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/domain/entities/inventory/stock_with_item.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';

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

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

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
          ? (_type == AdjustmentType.stockIn ? 'Stock Receiving / Delivery' : 'Damaged / Spoilage / Write-off')
          : _remarksController.text.trim();

      widget.onConfirm(delta, remarks);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = widget.stockItem.unitName ?? 'units';
    final isLow = widget.stockItem.isLowStock;
    final onHand = widget.stockItem.stock.quantity;

    return CustomFormDialog(
      title: 'Stock Adjustment',
      maxWidth: 520,
      saveLabel: 'Apply Adjustment',
      onSave: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: surfaceBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stockItem.itemName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Code: ${widget.stockItem.itemCode} • Barcode: ${widget.stockItem.barcode ?? 'N/A'}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$onHand $unitLabel',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isLow ? const Color(0xFFDC2626) : primaryBlue,
                        ),
                      ),
                      Text(
                        'On Hand',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Adjustment Type Segmented Control
            Text(
              'Adjustment Type',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _type = AdjustmentType.stockIn),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == AdjustmentType.stockIn ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _type == AdjustmentType.stockIn ? const Color(0xFF16A34A) : surfaceBorder,
                          width: _type == AdjustmentType.stockIn ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 18,
                            color: _type == AdjustmentType.stockIn ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stock-In (+)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _type == AdjustmentType.stockIn ? const Color(0xFF15803D) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _type = AdjustmentType.stockOut),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == AdjustmentType.stockOut ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _type == AdjustmentType.stockOut ? const Color(0xFFDC2626) : surfaceBorder,
                          width: _type == AdjustmentType.stockOut ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 18,
                            color: _type == AdjustmentType.stockOut ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stock-Out (-)',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _type == AdjustmentType.stockOut ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quantity Input
            Text(
              _type == AdjustmentType.stockIn ? 'Quantity Received' : 'Quantity Deducted',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                suffixText: unitLabel,
                suffixStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryBlue, width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter quantity';
                final parsed = double.tryParse(val);
                if (parsed == null || parsed <= 0) return 'Enter a valid positive number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Remarks Input
            Text(
              'Remarks / Reference',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _remarksController,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: _type == AdjustmentType.stockIn
                    ? 'e.g. PO-2026-001, Supplier Delivery'
                    : 'e.g. Spoilage, Broken bottle, Damaged goods',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: primaryBlue, width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
