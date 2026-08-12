import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EJLogViewerDialog extends StatelessWidget {
  final String ejContent;

  const EJLogViewerDialog({super.key, required this.ejContent});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.receipt_long, color: Color(0xFF355C8F)),
          SizedBox(width: 8),
          Text('Electronic Journal (EJ) Raw Log'),
        ],
      ),
      content: Container(
        width: 480,
        height: 400,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Terminal dark theme
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            ejContent,
            style: GoogleFonts.firaCode(
              color: const Color(0xFF4ADE80), // Terminal green text
              fontSize: 12,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
