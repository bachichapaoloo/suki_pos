import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/domain/entities/maintenance/order_type.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';

class OrderTypeFormDialog extends StatefulWidget {
  final OrderType? orderType;
  final Function(OrderType) onSave;

  const OrderTypeFormDialog({
    super.key,
    this.orderType,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    OrderType? orderType,
    required Function(OrderType) onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderTypeFormDialog(
        orderType: orderType,
        onSave: onSave,
      ),
    );
  }

  @override
  State<OrderTypeFormDialog> createState() => _OrderTypeFormDialogState();
}

class _OrderTypeFormDialogState extends State<OrderTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _additionalPercentageController;

  late bool _hasServiceCharge;
  late bool _askGuestCount;
  late bool _askRefNo;
  late bool _isDelivery;
  late bool _printAdditionalCopy;

  @override
  void initState() {
    super.initState();
    final ot = widget.orderType;
    _nameController = TextEditingController(text: ot?.name ?? '');
    _additionalPercentageController = TextEditingController(
      text: ot != null && ot.additionalPercentage > 0 ? ot.additionalPercentage.toStringAsFixed(1) : '0',
    );

    _hasServiceCharge = ot?.hasServiceCharge ?? true;
    _askGuestCount = ot?.askGuestCount ?? false;
    _askRefNo = ot?.askRefNo ?? false;
    _isDelivery = ot?.isDelivery ?? false;
    _printAdditionalCopy = ot?.printAdditionalCopy ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _additionalPercentageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final additionalPct = double.tryParse(_additionalPercentageController.text.trim()) ?? 0.0;

    final updated = OrderType(
      id: widget.orderType?.id ?? 0,
      name: name,
      hasServiceCharge: _hasServiceCharge,
      additionalPercentage: additionalPct,
      askGuestCount: _askGuestCount,
      askRefNo: _askRefNo,
      isDelivery: _isDelivery,
      printAdditionalCopy: _printAdditionalCopy,
    );

    widget.onSave(updated);
    AppToast.showSuccess(
      context,
      message: widget.orderType == null ? 'Order type "$name" created' : 'Order type "$name" updated',
      title: 'Order Type Saved',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEdit = widget.orderType != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.table_restaurant_rounded, color: colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Edit Order Type' : 'Create New Order Type',
                              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                            ),
                            Text(
                              'Configure dining operational rules and fee behavior',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
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
                  const SizedBox(height: 18),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Order Type Name *',
                      hintText: 'e.g., Dine-In, Take-Out, Delivery, Drive-Thru, Bar',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Order type name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Additional Percentage / Custom Surcharge
                  TextFormField(
                    controller: _additionalPercentageController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Order-Specific Surcharge / Packaging Fee (%)',
                      hintText: '0 for none, or e.g., 5 for 5% delivery fee',
                      suffixText: '%',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'OPERATIONAL BEHAVIOR & PROMPTS',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),

                  // Toggles Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: 'Incur Service Charge',
                          subtitle: 'Automatically applies global service charge when selected',
                          icon: Icons.room_service_outlined,
                          value: _hasServiceCharge,
                          onChanged: (v) => setState(() => _hasServiceCharge = v),
                          colorScheme: colorScheme,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          title: 'Prompt for Guest Count (Pax)',
                          subtitle: 'Ask cashier for number of dining guests upon selection',
                          icon: Icons.people_outline_rounded,
                          value: _askGuestCount,
                          onChanged: (v) => setState(() => _askGuestCount = v),
                          colorScheme: colorScheme,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          title: 'Prompt for Reference / Pager No.',
                          subtitle: 'Prompt cashier for buzzer, pager, or customer tag',
                          icon: Icons.tag_rounded,
                          value: _askRefNo,
                          onChanged: (v) => setState(() => _askRefNo = v),
                          colorScheme: colorScheme,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          title: 'Delivery Order Flag',
                          subtitle: 'Flags order for dispatch, courier, and rider tracking',
                          icon: Icons.delivery_dining_rounded,
                          value: _isDelivery,
                          onChanged: (v) => setState(() => _isDelivery = v),
                          colorScheme: colorScheme,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          title: 'Print Additional Receipt Copy',
                          subtitle: 'Automatically prints duplicate slip for kitchen / rider',
                          icon: Icons.receipt_long_rounded,
                          value: _printAdditionalCopy,
                          onChanged: (v) => setState(() => _printAdditionalCopy = v),
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Actions Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: Text(isEdit ? 'Save Changes' : 'Create Order Type', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        ),
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
