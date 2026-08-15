import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../bloc/shift_state.dart';

class ZReadingReportDialog extends StatelessWidget {
  final ShiftActive shiftState;

  const ZReadingReportDialog({super.key, required this.shiftState});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final shift = shiftState.shift;

    return AlertDialog(
      backgroundColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.all(16),
      content: SingleChildScrollView(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SUKIPOS STORE', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                'Z-READING REPORT (END-OF-DAY)',
                style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text('BIR PERMIT NO: 123456789', style: GoogleFonts.roboto(fontSize: 10, color: Colors.grey[700])),
              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              _row('Terminal No:', '#01'),
              _row('Z-Read Counter:', '#0042'),
              _row('Shift Date:', dateFormat.format(shift.startTime)),
              _row('EOD Close Date:', dateFormat.format(DateTime.now())),

              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              _row('Beginning Cash:', '₱${shift.beginningCash.toStringAsFixed(2)}'),
              _row('Net Cash Collected:', '₱${shiftState.theoreticalCashSales.toStringAsFixed(2)}'),
              _row('Ending Cash Count:', '₱${(shiftState.declaredCash ?? 0.0).toStringAsFixed(2)}', isBold: true),
              _row(
                'Short / Over:',
                '₱${shiftState.variance.toStringAsFixed(2)}',
                isBold: true,
                color: shiftState.variance < 0 ? Colors.red : Colors.green,
              ),

              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              _row('GROSS SALES:', '₱${shiftState.theoreticalCashSales.toStringAsFixed(2)}', isBold: true),
              _row('VATable Sales:', '₱${(shiftState.theoreticalCashSales / 1.12).toStringAsFixed(2)}'),
              _row(
                'VAT Amount (12%):',
                '₱${(shiftState.theoreticalCashSales - (shiftState.theoreticalCashSales / 1.12)).toStringAsFixed(2)}',
              ),

              const SizedBox(height: 16),
              Text(
                '*** END OF Z-READING REPORT ***\nSTORE CLOSED & AUDIT LOGGED',
                style: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.print),
          label: const Text('Print Z-Read & Close'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Printing Z-Reading EOD report...')),
            );
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
