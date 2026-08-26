import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';

class OrderNotesDialog extends StatefulWidget {
  final String? currentRemarks;
  final Function(String remarks) onSave;

  const OrderNotesDialog({
    super.key,
    this.currentRemarks,
    required this.onSave,
  });

  @override
  State<OrderNotesDialog> createState() => _OrderNotesDialogState();
}

class _OrderNotesDialogState extends State<OrderNotesDialog> {
  late TextEditingController _notesController;

  final List<String> _quickNotes = [
    'Serve all together',
    'Dine-in ASAP',
    'Rush order',
    'Less ice for drinks',
    'Allergies: No peanuts',
    'Senior Citizen group',
    'Pack separately',
    'Separate sauces',
  ];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.currentRemarks ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _appendNote(String text) {
    if (_notesController.text.isEmpty) {
      _notesController.text = text;
    } else {
      _notesController.text = '${_notesController.text}, $text';
    }
  }

  void _save() {
    widget.onSave(_notesController.text.trim());
    AppToast.showSuccess(context, message: 'Order notes updated');
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
                    child: Icon(Icons.edit_note_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Remarks & Kitchen Notes',
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          'Special instructions for kitchen and cashier team',
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

              // Quick Notes Chips
              Text(
                'QUICK NOTES',
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickNotes.map((n) {
                  return ActionChip(
                    label: Text(n),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    onPressed: () => _appendNote(n),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Order Notes / Kitchen Instructions',
                  hintText: 'e.g. Serve drinks first, extra napkins',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Save Notes', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
