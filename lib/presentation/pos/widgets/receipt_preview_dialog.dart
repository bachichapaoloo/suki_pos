import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/services/printer_service.dart';
import 'package:suki_pos/services/store_settings_service.dart';

class ReceiptPreviewDialog extends StatelessWidget {
  final TransactionDetail transaction;
  final bool isVoided;

  const ReceiptPreviewDialog({
    super.key,
    required this.transaction,
    this.isVoided = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final settings = StoreSettingsService.instance;
    final hasStatutory = transaction.beneficiaryName != null &&
        transaction.beneficiaryName!.isNotEmpty;

    return AlertDialog(
      backgroundColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.all(16),
      content: SingleChildScrollView(
        child: Container(
          width: 360, // 80mm thermal paper width
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
              if (isVoided)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.red,
                  child: const Text(
                    '*** VOIDED TRANSACTION ***',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (isVoided) const SizedBox(height: 12),

              // DYNAMIC STORE HEADER
              Text(
                settings.storeName.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                settings.receiptHeader,
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${settings.branchName} • ${settings.address}',
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'TIN: ${settings.taxId}',
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              // TRANSACTION METADATA
              _buildMetaRow('Txn No:', transaction.transactionNo, isBold: true),
              _buildMetaRow(
                'Date/Time:',
                dateFormat.format(transaction.transactionDate),
              ),
              _buildMetaRow('Cashier:', transaction.cashierName),
              _buildMetaRow('Order Type:', transaction.orderTypeName),
              _buildMetaRow(
                'Guests / SC:',
                '${transaction.guestCount} / ${transaction.eligibleGuestCount}',
              ),

              // STATUTORY BENEFICIARY INFO
              if (hasStatutory) ...[
                const SizedBox(height: 4),
                _buildMetaRow(
                  'Discount:',
                  transaction.discountName ?? 'Statutory (SC/PWD)',
                  isBold: true,
                ),
                _buildMetaRow('Cardholder:', transaction.beneficiaryName ?? 'N/A'),
                _buildMetaRow('ID / OSCA No:', transaction.beneficiaryIdNo ?? 'N/A'),
              ],

              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              // ITEMIZED LINE ITEMS
              ...transaction.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              line.itemName,
                              style: GoogleFonts.robotoMono(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            line.isFreeItem
                                ? 'FREE'
                                : '₱${line.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: line.isFreeItem
                                  ? Colors.green.shade700
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '  ${line.quantity} x ₱${line.unitPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (line.lineDiscount > 0)
                            Text(
                              '-₱${line.lineDiscount.toStringAsFixed(2)}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                color: Colors.red.shade700,
                              ),
                            ),
                        ],
                      ),
                      if (line.selectedOptions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Text(
                            '+ ${line.selectedOptions.join(', ')}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              // FINANCIAL TOTALS
              _buildAmountRow('GROSS SUBTOTAL:', transaction.grossAmount),
              if (transaction.itemDiscountAmount > 0)
                _buildAmountRow(
                  'LESS ITEM DISCOUNTS:',
                  -transaction.itemDiscountAmount,
                  isDiscount: true,
                ),
              if (transaction.orderDiscountAmount > 0)
                _buildAmountRow(
                  'LESS ORDER DISCOUNT:',
                  -transaction.orderDiscountAmount,
                  isDiscount: true,
                ),
              if (transaction.surchargeAmount > 0)
                _buildAmountRow(
                  'SERVICE CHARGE / SURCHARGE:',
                  transaction.surchargeAmount,
                ),

              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NET TOTAL DUE:',
                    style: GoogleFonts.robotoMono(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₱${transaction.netAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // PAYMENT BREAKDOWN
              _buildMetaRow(
                '${transaction.paymentMethodName} Tendered:',
                '₱${transaction.cashTendered.toStringAsFixed(2)}',
              ),
              if (transaction.bankName != null &&
                  transaction.bankName!.isNotEmpty)
                _buildMetaRow('Bank:', transaction.bankName!),
              if (transaction.referenceNumber != null &&
                  transaction.referenceNumber!.isNotEmpty)
                _buildMetaRow('Ref / Auth No:', transaction.referenceNumber!, isBold: true),
              _buildMetaRow(
                'Change Given:',
                '₱${transaction.changeGiven.toStringAsFixed(2)}',
                isBold: true,
              ),

              const SizedBox(height: 8),
              const Text('------------------------------------------'),
              const SizedBox(height: 8),

              // BIR TAX & EXEMPTION BREAKDOWN
              Text(
                'TAX BREAKDOWN (12% VAT)',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              _buildTaxRow('VATable Sales (12%):', transaction.vatableSales),
              _buildTaxRow('VAT Amount (12%):', transaction.vatAmount),
              _buildTaxRow('VAT-Exempt Sales:', transaction.vatExemptSales),
              _buildTaxRow('Zero-Rated Sales:', transaction.zeroRatedSales),

              const SizedBox(height: 16),
              Text(
                isVoided
                    ? '*** TRANSACTION CANCELLED / VOIDED ***'
                    : settings.receiptFooter,
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
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
          label: const Text('Print Thermal Receipt'),
          onPressed: () async {
            try {
              await PrinterService.printThermalReceipt(
                transaction,
                isVoided: isVoided,
              );
              if (context.mounted) {
                AppToast.showSuccess(
                  context,
                  message: 'Thermal receipt dispatched to printer.',
                  title: 'Receipt Ready',
                );
                Navigator.of(context).pop();
              }
            } catch (e) {
              if (context.mounted) {
                AppToast.showError(
                  context,
                  message: 'Unable to open printer dialog: $e',
                  title: 'Print Error',
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(fontSize: 11, color: Colors.grey[800]),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${amount < 0 ? "-" : ""}₱${amount.abs().toStringAsFixed(2)}',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDiscount ? Colors.red.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.grey[700]),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.grey[900]),
          ),
        ],
      ),
    );
  }
}
