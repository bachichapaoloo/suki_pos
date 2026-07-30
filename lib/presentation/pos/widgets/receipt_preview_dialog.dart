import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';

class ReceiptPreviewDialog extends StatelessWidget {
  final TransactionDetail transaction;

  const ReceiptPreviewDialog({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');

    return AlertDialog(
      backgroundColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.all(16),
      content: SingleChildScrollView(
        child: Container(
          width: 340, // 80mm thermal paper width simulator
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
              // HEADER
              Text(
                'SUKIPOS STORE',
                style: GoogleFonts.robotoMono(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Main Branch, Quezon City',
                style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                'TIN: 000-123-456-00000',
                style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              // TRANSACTION METADATA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Txn No:', style: GoogleFonts.robotoMono(fontSize: 12)),
                  Text(
                    transaction.transactionNo,
                    style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date:', style: GoogleFonts.robotoMono(fontSize: 12)),
                  Text(dateFormat.format(transaction.transactionDate), style: GoogleFonts.robotoMono(fontSize: 11)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cashier:', style: GoogleFonts.robotoMono(fontSize: 12)),
                  Text(transaction.cashierName, style: GoogleFonts.robotoMono(fontSize: 12)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Type:', style: GoogleFonts.robotoMono(fontSize: 12)),
                  Text(transaction.orderTypeName, style: GoogleFonts.robotoMono(fontSize: 12)),
                ],
              ),

              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              // ITEMIZED LINE ITEMS
              ...transaction.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              line.itemName,
                              style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '₱${line.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '  ${line.quantity} x ₱${line.unitPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.robotoMono(fontSize: 11, color: Colors.grey[700]),
                      ),
                      if (line.selectedOptions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Text(
                            '+ ${line.selectedOptions.join(', ')}',
                            style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              // TOTALS & PAYMENT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL DUE:', style: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    '₱${transaction.grossAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.robotoMono(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${transaction.paymentMethodName} Tendered:', style: GoogleFonts.robotoMono(fontSize: 11)),
                  Text('₱${transaction.cashTendered.toStringAsFixed(2)}', style: GoogleFonts.robotoMono(fontSize: 11)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Change:', style: GoogleFonts.robotoMono(fontSize: 11)),
                  Text('₱${transaction.changeGiven.toStringAsFixed(2)}', style: GoogleFonts.robotoMono(fontSize: 11)),
                ],
              ),

              const SizedBox(height: 16),
              Text(
                '*** THANK YOU & PLEASE COME AGAIN ***',
                style: GoogleFonts.robotoMono(fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'THIS SERVES AS YOUR OFFICIAL RECEIPT',
                style: GoogleFonts.robotoMono(fontSize: 9, color: Colors.grey[600]),
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
          label: const Text('Print Receipt'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sending print job to ESC/POS printer...')),
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
