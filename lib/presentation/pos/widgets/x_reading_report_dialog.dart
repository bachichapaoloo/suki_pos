import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import '../bloc/shift_state.dart';

class XReadingReportDialog extends StatelessWidget {
  final ShiftActive shiftState;

  const XReadingReportDialog({super.key, required this.shiftState});

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final shift = shiftState.shift;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'X-Reading Report',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Thermal Receipt Mock Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SUKI POS',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'X-READING REPORT (MID-DAY)',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: primaryBlue),
                      ),
                      const SizedBox(height: 12),
                      _receiptDivider(),
                      const SizedBox(height: 12),

                      _row('Shift ID:', '#${shift.id}'),
                      _row('Cashier ID:', '#${shift.cashierId}'),
                      _row('Start Time:', dateFormat.format(shift.startTime)),
                      _row('Print Time:', dateFormat.format(DateTime.now())),

                      const SizedBox(height: 12),
                      _receiptDivider(),
                      const SizedBox(height: 12),

                      _row('Beginning Cash:', '₱${shift.beginningCash.toStringAsFixed(2)}'),
                      _row('Cash Sales Collected:', '₱${shiftState.theoreticalCashSales.toStringAsFixed(2)}'),
                      const Divider(color: Color(0xFFCBD5E1), height: 16),
                      _row('Expected Drawer Cash:', '₱${shiftState.expectedTotalCash.toStringAsFixed(2)}', isBold: true),
                      _row('Declared Cash Count:', '₱${(shiftState.declaredCash ?? 0.0).toStringAsFixed(2)}', isBold: true),
                      const Divider(color: Color(0xFFCBD5E1), height: 16),
                      _row(
                        'Short / Over:',
                        '₱${shiftState.variance.toStringAsFixed(2)}',
                        isBold: true,
                        color: shiftState.variance < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        '*** END OF X-READING REPORT ***',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      AppToast.showInfo(
                        context,
                        message: 'Printing X-Reading report...',
                        title: 'Printing Report',
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.print_rounded, size: 18, color: Colors.white),
                    label: Text('Print X-Read', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptDivider() {
    return Row(
      children: List.generate(
        32,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : const Color(0xFFCBD5E1),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? textDark,
            ),
          ),
        ],
      ),
    );
  }
}
