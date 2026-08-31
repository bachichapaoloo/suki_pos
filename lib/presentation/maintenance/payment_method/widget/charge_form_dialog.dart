import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/maintenance/charge.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

class ChargeFormDialog extends StatefulWidget {
  final Charge? charge;
  final Function(Charge) onSave;

  const ChargeFormDialog({
    super.key,
    this.charge,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Charge? charge,
    required Function(Charge) onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChargeFormDialog(charge: charge, onSave: onSave),
    );
  }

  @override
  State<ChargeFormDialog> createState() => _ChargeFormDialogState();
}

class _ChargeFormDialogState extends State<ChargeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late int _chargeType; // 1 = Corporate, 2 = Employee, 3 = VIP
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.charge?.name ?? '');
    _codeController = TextEditingController(text: widget.charge?.code ?? '');
    _chargeType = widget.charge?.chargeType ?? 1;
    _isActive = widget.charge?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final charge = Charge(
        id: widget.charge?.id,
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        chargeType: _chargeType,
        isActive: _isActive,
      );
      widget.onSave(charge);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.charge != null;

    return CustomFormDialog(
      title: isEditing ? 'Edit Charge Account' : 'Add Charge Account',
      saveLabel: isEditing ? 'Save Changes' : 'Create Account',
      onSave: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Account Code',
              controller: _codeController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Account code is required' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Account / Client Name',
              controller: _nameController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Account name is required' : null,
            ),
            const SizedBox(height: 16),

            Text(
              'Account Classification',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip('Corporate / Client', 1, Icons.business_rounded, const Color(0xFF6366F1)),
                _buildTypeChip('Employee / Staff', 2, Icons.badge_outlined, const Color(0xFFF59E0B)),
                _buildTypeChip('VIP Account', 3, Icons.star_outline_rounded, const Color(0xFFEC4899)),
              ],
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Active Account', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500)),
              subtitle: Text(
                'Allow charges on this account at checkout',
                style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey),
              ),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, int typeVal, IconData icon, Color color) {
    final isSelected = _chargeType == typeVal;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
      label: Text(label),
      selected: isSelected,
      selectedColor: color,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      onSelected: (val) {
        if (val) setState(() => _chargeType = typeVal);
      },
    );
  }
}
