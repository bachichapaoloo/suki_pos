import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:suki_pos/domain/entities/orders/transaction_detail.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_state.dart';
import 'package:suki_pos/services/store_settings_service.dart';

/// Generates 80mm thermal roll PDF documents for receipts and X/Z shift readings
/// and dispatches them to the OS / thermal receipt printer via `printing`.
class PrinterService {
  PrinterService._();
  static final PrinterService instance = PrinterService._();

  static Future<void> printThermalReceipt(
    TransactionDetail transaction, {
    bool isVoided = false,
  }) async {
    final settings = StoreSettingsService.instance;
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final hasStatutory = transaction.beneficiaryName != null &&
        transaction.beneficiaryName!.isNotEmpty;

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (isVoided) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  color: PdfColors.grey800,
                  child: pw.Text(
                    '*** VOIDED TRANSACTION ***',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
              ],
              pw.Text(
                settings.storeName.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                settings.receiptHeader,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                '${settings.branchName} • ${settings.address}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'TIN: ${settings.taxId}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 6),
              _divider(),
              pw.SizedBox(height: 4),
              _metaRow('Txn No:', transaction.transactionNo, isBold: true),
              _metaRow(
                'Date/Time:',
                dateFormat.format(transaction.transactionDate),
              ),
              _metaRow('Cashier:', transaction.cashierName),
              _metaRow('Order Type:', transaction.orderTypeName),
              _metaRow(
                'Guests / SC:',
                '${transaction.guestCount} / ${transaction.eligibleGuestCount}',
              ),
              if (hasStatutory) ...[
                pw.SizedBox(height: 3),
                _metaRow(
                  'Discount:',
                  transaction.discountName ?? 'Statutory (SC/PWD)',
                  isBold: true,
                ),
                _metaRow('Cardholder:', transaction.beneficiaryName ?? 'N/A'),
                _metaRow('ID / OSCA No:', transaction.beneficiaryIdNo ?? 'N/A'),
              ],
              pw.SizedBox(height: 4),
              _divider(),
              pw.SizedBox(height: 4),
              ...transaction.lines.map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              line.itemName,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            line.isFreeItem
                                ? 'FREE'
                                : 'PHP ${line.amount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '  ${line.quantity} x PHP ${line.unitPrice.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          if (line.lineDiscount > 0)
                            pw.Text(
                              '-PHP ${line.lineDiscount.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                        ],
                      ),
                      if (line.selectedOptions.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 8),
                          child: pw.Text(
                            '+ ${line.selectedOptions.join(', ')}',
                            style: const pw.TextStyle(fontSize: 7.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              _divider(),
              pw.SizedBox(height: 4),
              _metaRow(
                'GROSS SUBTOTAL:',
                'PHP ${transaction.grossAmount.toStringAsFixed(2)}',
                isBold: true,
              ),
              if (transaction.itemDiscountAmount > 0)
                _metaRow(
                  'LESS ITEM DISCOUNTS:',
                  '-PHP ${transaction.itemDiscountAmount.toStringAsFixed(2)}',
                ),
              if (transaction.orderDiscountAmount > 0)
                _metaRow(
                  'LESS ORDER DISCOUNT:',
                  '-PHP ${transaction.orderDiscountAmount.toStringAsFixed(2)}',
                ),
              if (transaction.surchargeAmount > 0)
                _metaRow(
                  'SERVICE CHARGE / SURCHARGE:',
                  'PHP ${transaction.surchargeAmount.toStringAsFixed(2)}',
                ),
              pw.SizedBox(height: 3),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'NET TOTAL DUE:',
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'PHP ${transaction.netAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              _metaRow(
                '${transaction.paymentMethodName} Tendered:',
                'PHP ${transaction.cashTendered.toStringAsFixed(2)}',
              ),
              if (transaction.bankName != null &&
                  transaction.bankName!.isNotEmpty)
                _metaRow('Bank:', transaction.bankName!),
              if (transaction.referenceNumber != null &&
                  transaction.referenceNumber!.isNotEmpty)
                _metaRow('Ref / Auth No:', transaction.referenceNumber!),
              _metaRow(
                'Change Given:',
                'PHP ${transaction.changeGiven.toStringAsFixed(2)}',
                isBold: true,
              ),
              pw.SizedBox(height: 4),
              _divider(),
              pw.SizedBox(height: 4),
              pw.Text(
                'TAX BREAKDOWN (12% VAT)',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              _metaRow(
                'VATable Sales (12%):',
                'PHP ${transaction.vatableSales.toStringAsFixed(2)}',
              ),
              _metaRow(
                'VAT Amount (12%):',
                'PHP ${transaction.vatAmount.toStringAsFixed(2)}',
              ),
              _metaRow(
                'VAT-Exempt Sales:',
                'PHP ${transaction.vatExemptSales.toStringAsFixed(2)}',
              ),
              _metaRow(
                'Zero-Rated Sales:',
                'PHP ${transaction.zeroRatedSales.toStringAsFixed(2)}',
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                isVoided
                    ? '*** TRANSACTION CANCELLED / VOIDED ***'
                    : settings.receiptFooter,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'Receipt_${transaction.transactionNo}',
      format: PdfPageFormat.roll80,
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  static Future<void> printShiftReadingReport({
    required ShiftActive shiftState,
    required bool isZReading,
  }) async {
    final settings = StoreSettingsService.instance;
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final shift = shiftState.shift;
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                settings.storeName.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                isZReading
                    ? 'Z-READING REPORT (END-OF-DAY)'
                    : 'X-READING REPORT (MID-DAY)',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'TIN: ${settings.taxId} | Permit: ${settings.permitNumber}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.SizedBox(height: 6),
              _divider(),
              pw.SizedBox(height: 4),
              _metaRow('Terminal No:', '#01'),
              _metaRow('Shift ID:', '#${shift.id}'),
              _metaRow('Cashier ID:', '#${shift.cashierId}'),
              _metaRow('Shift Start:', dateFormat.format(shift.startTime)),
              _metaRow('Report Time:', dateFormat.format(DateTime.now())),
              pw.SizedBox(height: 4),
              _divider(),
              pw.SizedBox(height: 4),
              _metaRow(
                'Beginning Cash:',
                'PHP ${shift.beginningCash.toStringAsFixed(2)}',
              ),
              _metaRow(
                'Cash Sales Collected:',
                'PHP ${shiftState.theoreticalCashSales.toStringAsFixed(2)}',
              ),
              _metaRow(
                'Expected Drawer Cash:',
                'PHP ${shiftState.expectedTotalCash.toStringAsFixed(2)}',
                isBold: true,
              ),
              _metaRow(
                'Declared Cash Count:',
                'PHP ${(shiftState.declaredCash ?? 0.0).toStringAsFixed(2)}',
                isBold: true,
              ),
              _metaRow(
                'Short / Over:',
                'PHP ${shiftState.variance.toStringAsFixed(2)}',
                isBold: true,
              ),
              if (isZReading) ...[
                pw.SizedBox(height: 4),
                _divider(),
                pw.SizedBox(height: 4),
                _metaRow(
                  'GROSS SALES:',
                  'PHP ${shiftState.theoreticalCashSales.toStringAsFixed(2)}',
                  isBold: true,
                ),
                _metaRow(
                  'VATable Sales:',
                  'PHP ${(shiftState.theoreticalCashSales / 1.12).toStringAsFixed(2)}',
                ),
                _metaRow(
                  'VAT Amount (12%):',
                  'PHP ${(shiftState.theoreticalCashSales - (shiftState.theoreticalCashSales / 1.12)).toStringAsFixed(2)}',
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Text(
                isZReading
                    ? '*** END OF Z-READING REPORT ***'
                    : '*** END OF X-READING REPORT ***',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: isZReading
          ? 'ZReading_Shift_${shift.id}'
          : 'XReading_Shift_${shift.id}',
      format: PdfPageFormat.roll80,
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  static Future<void> printZReadingMapReport(
    Map<String, dynamic> zData,
  ) async {
    final settings = StoreSettingsService.instance;
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final doc = pw.Document();
    final nextZNo = (zData['nextZNumber'] as num? ?? 1).toInt();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                settings.storeName.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Z-READING REPORT (END-OF-DAY)',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'TIN: ${settings.taxId} | Permit: ${settings.permitNumber}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.SizedBox(height: 6),
              _divider(),
              pw.SizedBox(height: 4),
              _metaRow('Z-Counter No:', '#$nextZNo', isBold: true),
              _metaRow('Report Time:', dateFormat.format(DateTime.now())),
              _metaRow(
                'Previous Grand Total:',
                'PHP ${(zData['previousGrandTotal'] as num? ?? 0.0).toStringAsFixed(2)}',
              ),
              _metaRow(
                'Net Sales Today:',
                'PHP ${(zData['netSales'] as num? ?? 0.0).toStringAsFixed(2)}',
                isBold: true,
              ),
              _metaRow(
                'Present Grand Total:',
                'PHP ${(zData['presentGrandTotal'] as num? ?? 0.0).toStringAsFixed(2)}',
                isBold: true,
              ),
              pw.SizedBox(height: 4),
              _divider(),
              pw.SizedBox(height: 4),
              _metaRow(
                'Declared Cash:',
                'PHP ${(zData['declaredCash'] as num? ?? 0.0).toStringAsFixed(2)}',
              ),
              _metaRow(
                'Expected Cash:',
                'PHP ${(zData['expectedCash'] as num? ?? 0.0).toStringAsFixed(2)}',
              ),
              _metaRow(
                'Short / Over:',
                'PHP ${(zData['shortOver'] as num? ?? 0.0).toStringAsFixed(2)}',
                isBold: true,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '*** END OF Z-READING REPORT ***',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'ZReading_$nextZNo',
      format: PdfPageFormat.roll80,
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  static pw.Widget _divider() {
    return pw.Text(
      '----------------------------------------',
      textAlign: pw.TextAlign.center,
      style: const pw.TextStyle(fontSize: 8),
    );
  }

  static pw.Widget _metaRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: 8.5,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5)),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
