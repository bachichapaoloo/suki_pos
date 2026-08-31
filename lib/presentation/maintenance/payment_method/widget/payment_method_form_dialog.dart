import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/maintenance/payment_method.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/custom_text_field.dart';

class PaymentMethodFormDialog extends StatefulWidget {
  final PaymentMethod? paymentMethod;
  final Function(PaymentMethod) onSave;

  const PaymentMethodFormDialog({
    super.key,
    this.paymentMethod,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    PaymentMethod? paymentMethod,
    required Function(PaymentMethod) onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentMethodFormDialog(
        paymentMethod: paymentMethod,
        onSave: onSave,
      ),
    );
  }

  @override
  State<PaymentMethodFormDialog> createState() => _PaymentMethodFormDialogState();
}

class _PaymentMethodFormDialogState extends State<PaymentMethodFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.paymentMethod?.name ?? '');
    _codeController = TextEditingController(text: widget.paymentMethod?.code ?? '');
    _isActive = widget.paymentMethod?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final method = PaymentMethod(
        id: widget.paymentMethod?.id,
        code: _codeController.text.trim().toLowerCase().replaceAll(' ', '_'),
        name: _nameController.text.trim(),
        isActive: _isActive,
      );
      widget.onSave(method);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.paymentMethod != null;

    return CustomFormDialog(
      title: isEditing ? 'Edit Payment Method' : 'Add Payment Method',
      saveLabel: isEditing ? 'Save Changes' : 'Create Method',
      onSave: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Display Name',
              controller: _nameController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Display name is required' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Tender Code (Unique Identifier)',
              controller: _codeController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Code is required' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Active in POS Checkout',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Show this payment method as an option in cashier terminal',
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
}
