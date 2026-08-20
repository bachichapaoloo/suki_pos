import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/inventory/stock.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

class StockRecordDialog extends StatefulWidget {
  final List<Item> availableItems;
  final Function(Stock stock) onSave;

  const StockRecordDialog({
    super.key,
    required this.availableItems,
    required this.onSave,
  });

  @override
  State<StockRecordDialog> createState() => _StockRecordDialogState();
}

class _StockRecordDialogState extends State<StockRecordDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedItemId;
  late TextEditingController _initialQtyCtrl;
  late TextEditingController _minLevelCtrl;
  late TextEditingController _maxLevelCtrl;
  late TextEditingController _reorderLevelCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _remarksCtrl;

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _initialQtyCtrl = TextEditingController(text: '0');
    _minLevelCtrl = TextEditingController(text: '10');
    _maxLevelCtrl = TextEditingController(text: '100');
    _reorderLevelCtrl = TextEditingController(text: '20');
    _costCtrl = TextEditingController(text: '0.00');
    _locationCtrl = TextEditingController(text: 'Main Storage');
    _remarksCtrl = TextEditingController(text: 'Initial Stock Entry');

    if (widget.availableItems.isNotEmpty) {
      _selectedItemId = widget.availableItems.first.id;
      _costCtrl.text = widget.availableItems.first.costPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _initialQtyCtrl.dispose();
    _minLevelCtrl.dispose();
    _maxLevelCtrl.dispose();
    _reorderLevelCtrl.dispose();
    _costCtrl.dispose();
    _locationCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _onItemSelected(int? itemId) {
    setState(() {
      _selectedItemId = itemId;
      if (itemId != null) {
        final item = widget.availableItems.firstWhere((i) => i.id == itemId);
        _costCtrl.text = item.costPrice.toStringAsFixed(2);
      }
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedItemId != null) {
      final initialQty = double.tryParse(_initialQtyCtrl.text) ?? 0.0;
      final minLevel = double.tryParse(_minLevelCtrl.text) ?? 0.0;
      final maxLevel = double.tryParse(_maxLevelCtrl.text) ?? 0.0;
      final reorderLevel = double.tryParse(_reorderLevelCtrl.text) ?? 0.0;
      final cost = double.tryParse(_costCtrl.text);

      final stock = Stock(
        itemId: _selectedItemId!,
        quantity: initialQty,
        beginningInv: initialQty,
        minLevel: minLevel,
        maxLevel: maxLevel,
        reorderLevel: reorderLevel,
        cost: cost,
        location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
        remarks: _remarksCtrl.text.trim().isNotEmpty ? _remarksCtrl.text.trim() : null,
        updatedAt: DateTime.now(),
      );

      widget.onSave(stock);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormDialog(
      title: 'New Stock Inventory Record',
      maxWidth: 580,
      saveLabel: 'Save Stock Record',
      onSave: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Selection Dropdown
            Text(
              'Select Product / Item *',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedItemId,
              style: GoogleFonts.inter(fontSize: 14, color: textDark),
              decoration: InputDecoration(
                hintText: 'Choose an item from catalog',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
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
              items: widget.availableItems.map((item) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text('${item.name} (${item.itemCode})'),
                );
              }).toList(),
              onChanged: _onItemSelected,
              validator: (v) => v == null ? 'Please select an item' : null,
            ),
            const SizedBox(height: 16),

            // Initial Quantity & Unit Cost Row
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Beginning / Initial Qty',
                    controller: _initialQtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: '0.00',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Unit Cost Price (₱)',
                    controller: _costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: '0.00',
                  ),
                ),
              ],
            ),

            // Thresholds Row
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Min Stock Level (Alert)',
                    controller: _minLevelCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: '10',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Reorder Level',
                    controller: _reorderLevelCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: '20',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Max Stock Level',
                    controller: _maxLevelCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hintText: '100',
                  ),
                ),
              ],
            ),

            // Storage Location & Remarks
            CustomTextField(
              label: 'Warehouse / Storage Location',
              controller: _locationCtrl,
              hintText: 'e.g. Main Storage, Aisle 3, Shelf B',
            ),
            CustomTextField(
              label: 'Remarks / Reference Notes',
              controller: _remarksCtrl,
              hintText: 'e.g. Opening balance stock inventory',
            ),
          ],
        ),
      ),
    );
  }
}
