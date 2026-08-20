import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../domain/entities/shift/cash_denomination_count.dart';
import '../../widgets/custom_form_dialog.dart';

class TenderDeclarationDialog extends StatefulWidget {
  final Function(List<CashDenominationCount> denominations, double totalCash) onConfirm;
  final List<CashDenominationCount>? initialDenominations;

  const TenderDeclarationDialog({
    super.key,
    required this.onConfirm,
    this.initialDenominations,
  });

  @override
  State<TenderDeclarationDialog> createState() => _TenderDeclarationDialogState();
}

class _TenderDeclarationDialogState extends State<TenderDeclarationDialog> {
  final Map<double, TextEditingController> _controllers = {};

  static const List<double> _denominations = [
    1000.0,
    500.0,
    200.0,
    100.0,
    50.0,
    20.0,
    10.0,
    5.0,
    1.0,
    0.25,
  ];

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    for (final d in _denominations) {
      final initial = widget.initialDenominations?.firstWhere(
        (e) => (e.denomination - d).abs() < 0.001,
        orElse: () => CashDenominationCount(denomination: d, count: 0),
      );
      _controllers[d] = TextEditingController(
        text: (initial?.count ?? 0) > 0 ? initial!.count.toString() : '0',
      );
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalAmount {
    double sum = 0.0;
    _controllers.forEach((denom, controller) {
      final count = int.tryParse(controller.text) ?? 0;
      sum += (denom * count);
    });
    return sum;
  }

  void _submit() {
    final List<CashDenominationCount> list = [];
    _controllers.forEach((denom, controller) {
      final count = int.tryParse(controller.text) ?? 0;
      list.add(CashDenominationCount(denomination: denom, count: count));
    });

    widget.onConfirm(list, _totalAmount);
    Navigator.of(context).pop();
  }

  void _increment(double denom) {
    final current = int.tryParse(_controllers[denom]!.text) ?? 0;
    _controllers[denom]!.text = (current + 1).toString();
    setState(() {});
  }

  void _decrement(double denom) {
    final current = int.tryParse(_controllers[denom]!.text) ?? 0;
    if (current > 0) {
      _controllers[denom]!.text = (current - 1).toString();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomFormDialog(
      title: 'Cash Drawer Count',
      maxWidth: 620,
      saveLabel: 'Save Declaration',
      onSave: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: primaryBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Count all physical bills and coins currently in the cash drawer.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Denominations List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _denominations.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final denom = _denominations[index];
              final ctrl = _controllers[denom]!;
              final count = int.tryParse(ctrl.text) ?? 0;
              final subtotal = count * denom;

              final isBill = denom >= 20;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    // Denomination badge
                    Container(
                      width: 90,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isBill
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₱${denom >= 1 ? denom.toInt() : denom.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isBill
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Quick Minus
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 22, color: Color(0xFF94A3B8)),
                      onPressed: () => _decrement(denom),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    // Count Input Field
                    SizedBox(
                      width: 70,
                      height: 40,
                      child: TextFormField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: surfaceBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: primaryBlue, width: 2),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick Plus
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22, color: primaryBlue),
                      onPressed: () => _increment(denom),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Spacer(),
                    // Subtotal
                    Text(
                      '₱${subtotal.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Total Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Declared Cash:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textDark,
                  ),
                ),
                Text(
                  '₱${_totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
