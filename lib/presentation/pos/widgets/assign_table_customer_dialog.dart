import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';

class AssignTableCustomerDialog extends StatefulWidget {
  final String? currentTableName;
  final String? currentCustomerName;
  final int currentGuestCount;
  final Function({String? tableName, String? customerName, int? guestCount}) onSave;

  const AssignTableCustomerDialog({
    super.key,
    this.currentTableName,
    this.currentCustomerName,
    this.currentGuestCount = 1,
    required this.onSave,
  });

  @override
  State<AssignTableCustomerDialog> createState() => _AssignTableCustomerDialogState();
}

class _AssignTableCustomerDialogState extends State<AssignTableCustomerDialog> {
  late TextEditingController _tableController;
  late TextEditingController _customerController;
  late int _guestCount;

  final List<String> _quickTables = ['T-1', 'T-2', 'T-3', 'T-4', 'T-5', 'T-6', 'T-7', 'T-8', 'VIP-1', 'BAR-1'];

  @override
  void initState() {
    super.initState();
    _tableController = TextEditingController(text: widget.currentTableName ?? '');
    _customerController = TextEditingController(text: widget.currentCustomerName ?? '');
    _guestCount = widget.currentGuestCount > 0 ? widget.currentGuestCount : 1;
  }

  @override
  void dispose() {
    _tableController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  void _save() {
    final table = _tableController.text.trim();
    final customer = _customerController.text.trim();

    widget.onSave(
      tableName: table.isNotEmpty ? table : null,
      customerName: customer.isNotEmpty ? customer : null,
      guestCount: _guestCount,
    );

    AppToast.showSuccess(
      context,
      message: 'Order tagged: ${table.isNotEmpty ? "Table $table" : ""}${table.isNotEmpty && customer.isNotEmpty ? " • " : ""}${customer.isNotEmpty ? customer : ""}',
      title: 'Order Info Updated',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                          'Assign Table & Customer',
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          'Tag order with dining table or customer / pager',
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
              const SizedBox(height: 16),

              // Quick Table Chips
              Text(
                'QUICK TABLES',
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickTables.map((t) {
                  final isSelected = _tableController.text == t;
                  return ActionChip(
                    label: Text(t),
                    backgroundColor: isSelected ? colorScheme.primary : const Color(0xFFF1F5F9),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                    side: BorderSide(color: isSelected ? colorScheme.primary : const Color(0xFFCBD5E1)),
                    onPressed: () => setState(() => _tableController.text = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Table / Pager Field
              TextFormField(
                controller: _tableController,
                decoration: InputDecoration(
                  labelText: 'Table / Buzzer Number',
                  hintText: 'e.g. Table 4 or Pager #12',
                  prefixIcon: const Icon(Icons.table_restaurant_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Customer Name Field
              TextFormField(
                controller: _customerController,
                decoration: InputDecoration(
                  labelText: 'Customer / Guest Name',
                  hintText: 'e.g. John Doe',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // Guest Count Stepper
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Guest Count (Heads):', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () {
                            if (_guestCount > 1) setState(() => _guestCount--);
                          },
                        ),
                        Text('$_guestCount', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () => setState(() => _guestCount++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text('Save Tag', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
