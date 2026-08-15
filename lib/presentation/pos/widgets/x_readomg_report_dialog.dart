import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../bloc/shift_state.dart';

class XReadingReportDialog extends StatelessWidget {
  final ShiftActive shiftState;

  const XReadingReportDialog({super.key, required this.shiftState});

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
                'X-READING REPORT (MID-DAY)',
                style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              _row('Shift ID:', '#${shift.id}'),
              _row('Cashier ID:', '#${shift.cashierId}'),
              _row('Start Time:', dateFormat.format(shift.startTime)),
              _row('Print Time:', dateFormat.format(DateTime.now())),

              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              _row('Beginning Change Fund:', '₱${shift.beginningCash.toStringAsFixed(2)}'),
              _row('Cash Sales Collected:', '₱${shiftState.theoreticalCashSales.toStringAsFixed(2)}'),
              const Divider(),
              _row('Theoretical Drawer Cash:', '₱${shiftState.expectedTotalCash.toStringAsFixed(2)}', isBold: true),
              _row('Declared Cash Count:', '₱${(shiftState.declaredCash ?? 0.0).toStringAsFixed(2)}', isBold: true),
              const Divider(),
              _row(
                'Short / Over:',
                '₱${shiftState.variance.toStringAsFixed(2)}',
                isBold: true,
                color: shiftState.variance < 0 ? Colors.red : Colors.green,
              ),

              const SizedBox(height: 16),
              Text(
                '*** END OF X-READING REPORT ***',
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
          label: const Text('Print X-Read'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Printing X-Reading report...')),
            );
            Navigator.of(context).pop();
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
