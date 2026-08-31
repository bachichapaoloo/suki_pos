import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/maintenance/bank.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

class BankFormDialog extends StatefulWidget {
  final Bank? bank;
  final Function(Bank) onSave;

  const BankFormDialog({
    super.key,
    this.bank,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    Bank? bank,
    required Function(Bank) onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BankFormDialog(bank: bank, onSave: onSave),
    );
  }

  @override
  State<BankFormDialog> createState() => _BankFormDialogState();
}

class _BankFormDialogState extends State<BankFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int _selectedCardType; // 1 = Debit, 2 = Credit, 3 = E-Wallet
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bank?.name ?? '');
    _selectedCardType = widget.bank?.cardType ?? 1;
    _isActive = widget.bank?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final bank = Bank(
        id: widget.bank?.id,
        name: _nameController.text.trim(),
        cardType: _selectedCardType,
        isActive: _isActive,
      );
      widget.onSave(bank);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bank != null;

    return CustomFormDialog(
      title: isEditing ? 'Edit Bank / E-Wallet' : 'Add Bank / E-Wallet',
      saveLabel: isEditing ? 'Save Changes' : 'Add Account',
      onSave: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Bank / E-Wallet Name',
              controller: _nameController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            Text(
              'Account / Card Type',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Card Type Selector Chips
            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip('Debit Card', 1, Icons.credit_card, const Color(0xFF3B82F6)),
                _buildTypeChip('Credit Card', 2, Icons.credit_score, const Color(0xFF8B5CF6)),
                _buildTypeChip('E-Wallet / QR', 3, Icons.qr_code_rounded, const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 16),

            // Active Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Active Status', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500)),
              subtitle: Text(
                'Enable or disable in cashier terminal',
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

  Widget _buildTypeChip(String label, int typeValue, IconData icon, Color color) {
    final isSelected = _selectedCardType == typeValue;
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
        if (val) setState(() => _selectedCardType = typeValue);
      },
    );
  }
}
