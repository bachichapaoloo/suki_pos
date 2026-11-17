import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/services/printer_service.dart';
import 'package:suki_pos/services/store_settings_service.dart';
import '../bloc/shift_state.dart';

class XReadingReportDialog extends StatelessWidget {
  final ShiftActive shiftState;
  final bool closeShiftOnConfirm;

  const XReadingReportDialog({
    super.key,
    required this.shiftState,
    this.closeShiftOnConfirm = true,
  });

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final shift = shiftState.shift;
    final settings = StoreSettingsService.instance;
    final x = shiftState.xReadingData;

    final cashSales =
        (x['cashSales'] as num? ?? shiftState.theoreticalCashSales).toDouble();
    final cashCount = (x['cashCount'] as num? ?? 0).toInt();
    final cardAmt = (x['cardAmount'] as num? ?? 0.0).toDouble();
    final cardCnt = (x['cardCount'] as num? ?? 0).toInt();
    final atmAmt = (x['atmAmount'] as num? ?? 0.0).toDouble();
    final atmCnt = (x['atmCount'] as num? ?? 0).toInt();
    final chkAmt = (x['checkAmount'] as num? ?? 0.0).toDouble();
    final chkCnt = (x['checkCount'] as num? ?? 0).toInt();
    final gcAmt = (x['giftCheckAmount'] as num? ?? 0.0).toDouble();
    final gcCnt = (x['giftCheckCount'] as num? ?? 0).toInt();
    final chgAmt = (x['chargeAmount'] as num? ?? 0.0).toDouble();
    final chgCnt = (x['chargeCount'] as num? ?? 0).toInt();

    final cashIn = (x['cashIn'] as num? ?? shiftState.cashIn).toDouble();
    final cashOut = (x['cashOut'] as num? ?? shiftState.cashOut).toDouble();
    final grossSales = (x['grossSales'] as num? ?? cashSales).toDouble();
    final postVoidAmt = (x['postVoidAmount'] as num? ?? 0.0).toDouble();
    final postVoidCnt = (x['postVoidCount'] as num? ?? 0).toInt();
    final totalDiscounts = (x['totalDiscounts'] as num? ?? 0.0).toDouble();
    final surchargeAmt = (x['surchargeAmount'] as num? ?? 0.0).toDouble();
    final netSales = (x['netSales'] as num? ?? cashSales).toDouble();
    final vatableSales =
        (x['vatableSales'] as num? ?? (netSales / 1.12)).toDouble();
    final vatAmount =
        (x['vatAmount'] as num? ?? (netSales - vatableSales)).toDouble();
    final vatExempt = (x['vatExemptSales'] as num? ?? 0.0).toDouble();
    final zeroRated = (x['zeroRatedSales'] as num? ?? 0.0).toDouble();
    final begSiNo = (x['begSiNo'] as num? ?? 0).toInt();
    final endSiNo = (x['endSiNo'] as num? ?? 0).toInt();
    final begTseqNo = (x['begTseqNo'] as num? ?? 0).toInt();
    final endTseqNo = (x['endTseqNo'] as num? ?? 0).toInt();
    final salesCount = (x['salesCount'] as num? ?? 0).toInt();
    final guestCount = (x['guestCount'] as num? ?? 0).toInt();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'X-Reading (End of Cashier Shift)',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Thermal Receipt Preview Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        settings.storeName.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'X-READING REPORT (CASHIER SHIFT)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: primaryBlue,
                        ),
                      ),
                      Text(
                        'TIN: ${settings.taxId}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _receiptDivider(),
                      const SizedBox(height: 8),

                      _row('Shift ID:', '#${shift.id}'),
                      _row('Cashier ID:', '#${shift.cashierId}'),
                      _row('Start Time:', dateFormat.format(shift.startTime)),
                      _row('Report Time:', dateFormat.format(DateTime.now())),
                      _row(
                        'SI# Range:',
                        '${begSiNo.toString().padLeft(6, '0')} - ${endSiNo.toString().padLeft(6, '0')}',
                      ),
                      _row('TSEQ# Range:', '$begTseqNo - $endTseqNo'),
                      _row(
                        'Txns / Guests:',
                        '$salesCount / $guestCount',
                      ),

                      const SizedBox(height: 8),
                      _receiptDivider(),
                      const SizedBox(height: 8),

                      // Payment Media Section
                      _sectionTitle('PAYMENT MEDIA BREAKDOWN'),
                      _row(
                        'Cash Sales ($cashCount):',
                        '₱${cashSales.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Credit/Debit Card ($cardCnt):',
                        '₱${cardAmt.toStringAsFixed(2)}',
                      ),
                      _row(
                        'ATM / E-Wallet ($atmCnt):',
                        '₱${atmAmt.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Bank Check ($chkCnt):',
                        '₱${chkAmt.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Gift Check ($gcCnt):',
                        '₱${gcAmt.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Charge Account ($chgCnt):',
                        '₱${chgAmt.toStringAsFixed(2)}',
                      ),

                      const SizedBox(height: 8),
                      _receiptDivider(),
                      const SizedBox(height: 8),

                      // Cash Accountability Section
                      _sectionTitle('CASH DRAWER ACCOUNTABILITY'),
                      _row(
                        'Opening Change Fund:',
                        '₱${shift.beginningCash.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Add Cash Sales:',
                        '₱${cashSales.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Add Cash In (Deposit):',
                        '₱${cashIn.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Less Cash Out (Withdraw):',
                        '-₱${cashOut.toStringAsFixed(2)}',
                      ),
                      const Divider(color: Color(0xFFCBD5E1), height: 14),
                      _row(
                        'Expected Drawer Cash:',
                        '₱${shiftState.expectedTotalCash.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                      _row(
                        'Declared Physical Cash:',
                        '₱${(shiftState.declaredCash ?? 0.0).toStringAsFixed(2)}',
                        isBold: true,
                      ),
                      _row(
                        'Short / Over:',
                        '₱${shiftState.variance.toStringAsFixed(2)}',
                        isBold: true,
                        color: shiftState.variance < 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                      ),

                      const SizedBox(height: 8),
                      _receiptDivider(),
                      const SizedBox(height: 8),

                      // Sales & Tax Summary Section
                      _sectionTitle('SALES & VAT SUMMARY'),
                      _row(
                        'Gross Sales:',
                        '₱${grossSales.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Less Post-Void ($postVoidCnt):',
                        '-₱${postVoidAmt.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Less Discounts:',
                        '-₱${totalDiscounts.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Add Service Charge:',
                        '₱${surchargeAmt.toStringAsFixed(2)}',
                      ),
                      _row(
                        'NET SALES:',
                        '₱${netSales.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                      const SizedBox(height: 4),
                      _row(
                        'VATable Sales (12%):',
                        '₱${vatableSales.toStringAsFixed(2)}',
                      ),
                      _row(
                        '12% VAT Amount:',
                        '₱${vatAmount.toStringAsFixed(2)}',
                      ),
                      _row(
                        'VAT-Exempt Sales:',
                        '₱${vatExempt.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Zero-Rated Sales:',
                        '₱${zeroRated.toStringAsFixed(2)}',
                      ),

                      const SizedBox(height: 12),
                      Text(
                        '*** END OF X-READING REPORT ***',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF94A3B8),
                        ),
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
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await PrinterService.printShiftReadingReport(
                          shiftState: shiftState,
                          isZReading: false,
                        );
                      } catch (_) {}
                      if (context.mounted) {
                        AppToast.showSuccess(
                          context,
                          message:
                              'X-Reading printed & cashier shift finalized.',
                          title: 'End of Shift (X-Reading)',
                        );
                        Navigator.of(context).pop(true);
                      }
                    },
                    icon: const Icon(
                      Icons.print_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      closeShiftOnConfirm
                          ? 'Confirm X-Reading & End Shift'
                          : 'Print X-Read',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: primaryBlue,
          ),
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
            color: index % 2 == 0
                ? Colors.transparent
                : const Color(0xFFCBD5E1),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? textDark,
            ),
          ),
        ],
      ),
    );
  }
}
