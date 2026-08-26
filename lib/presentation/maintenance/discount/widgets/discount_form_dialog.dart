import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/maintenance/discount_type.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

class DiscountFormDialog extends StatefulWidget {
  const DiscountFormDialog({
    super.key,
    this.discount,
    required this.discountTypes,
  });

  final Discount? discount;
  final List<DiscountType> discountTypes;

  @override
  State<DiscountFormDialog> createState() => _DiscountFormDialogState();
}

class _DiscountFormDialogState extends State<DiscountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late int? _selectedTypeId;
  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late TextEditingController _capAmountController;
  late bool _isPercentage;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final d = widget.discount;
    _selectedTypeId = d?.discountTypeId ?? (widget.discountTypes.isNotEmpty ? widget.discountTypes.first.id : null);
    _nameController = TextEditingController(text: d?.name);
    _isPercentage = d == null ? true : (d.percentage != null && d.percentage! > 0);
    _rateController = TextEditingController(
      text: d == null ? '' : (_isPercentage ? d.percentage?.toStringAsFixed(0) : d.fixedAmount?.toStringAsFixed(2)),
    );
    _capAmountController = TextEditingController(text: d?.capAmount?.toStringAsFixed(2) ?? '');
    _isActive = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _capAmountController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate() && _selectedTypeId != null) {
      final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;
      final cap = double.tryParse(_capAmountController.text.trim());

      final discount = Discount(
        id: widget.discount?.id,
        discountTypeId: _selectedTypeId!,
        name: _nameController.text.trim(),
        percentage: _isPercentage ? rate : null,
        fixedAmount: !_isPercentage ? rate : null,
        capAmount: cap,
        isActive: _isActive,
      );

      Navigator.pop(context, discount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.discount != null;

    return CustomFormDialog(
      title: isEditing ? 'Edit Discount' : 'New Discount',
      onSave: _onSave,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Discount Type Dropdown
            _buildTypeDropdown(),
            const SizedBox(height: 12),

            // 2. Discount Name Input
            CustomTextField(
              label: 'Discount Name',
              controller: _nameController,
              hintText: 'e.g. Senior Citizen 20%',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 12),

            // 3. Discount Mode Selector (% vs ₱)
            _buildModeSelector(),
            const SizedBox(height: 12),

            // 4. Rate Input (Percentage or Fixed)
            CustomTextField(
              label: _isPercentage ? 'Percentage Rate (%)' : 'Fixed Amount (₱)',
              controller: _rateController,
              hintText: _isPercentage ? 'e.g. 20' : 'e.g. 50.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a value';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid number > 0';
                if (_isPercentage && n > 100) return 'Cannot exceed 100%';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // 5. Optional Cap Amount
            CustomTextField(
              label: 'Max Cap Amount (₱) - Optional',
              controller: _capAmountController,
              hintText: 'e.g. 500.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            // 6. Active Switch
            _buildActiveSwitch(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discount Type',
          style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        if (widget.discountTypes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'No discount types available. Please add a discount type first.',
              style: GoogleFonts.roboto(color: Colors.red, fontSize: 11),
            ),
          ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _selectedTypeId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Select Type',
            border: OutlineInputBorder(),
            enabled: widget.discountTypes.isNotEmpty,
          ),
          validator: (v) => v == null ? 'Select a discount type' : null,
          items: widget.discountTypes.map((type) {
            return DropdownMenuItem(
              value: type.id,
              child: Text(type.name),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              _selectedTypeId = v;
            });
          },
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discount Mode',
          style: GoogleFonts.roboto(fontSize: 15),
        ),
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          selected: {_isPercentage},
          onSelectionChanged: (Set<bool> s) {
            setState(() {
              _isPercentage = s.first;
              _rateController.clear();
              _capAmountController.clear();
            });
          },
          segments: const <ButtonSegment<bool>>[
            ButtonSegment<bool>(value: true, label: Text('Percentage (%)')),
            ButtonSegment<bool>(value: false, label: Text('Fixed (₱)')),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Active',
          style: GoogleFonts.roboto(fontSize: 15),
        ),
        Switch(
          value: _isActive,
          onChanged: (v) {
            setState(() {
              _isActive = v;
            });
          },
        ),
      ],
    );
  }
}
