import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/services/printer_service.dart';
import 'package:suki_pos/services/store_settings_service.dart';
import '../bloc/shift_state.dart';

class ZReadingReportDialog extends StatelessWidget {
  final ShiftActive? shiftState;
  final Map<String, dynamic>? zReadingData;

  const ZReadingReportDialog({
    super.key,
    this.shiftState,
    this.zReadingData,
  });

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final settings = StoreSettingsService.instance;
    final z = zReadingData ?? shiftState?.zReadingData ?? const {};

    final nextZNo = (z['nextZNumber'] as num? ?? 1).toInt();
    final prevGrand = (z['previousGrandTotal'] as num? ?? 0.0).toDouble();
    final presGrand = (z['presentGrandTotal'] as num? ?? 0.0).toDouble();
    final beginningCash =
        (z['beginningCash'] as num? ?? shiftState?.shift.beginningCash ?? 0.0)
            .toDouble();
    final cashSales =
        (z['cashSales'] as num? ?? shiftState?.theoreticalCashSales ?? 0.0)
            .toDouble();
    final cashCount = (z['cashCount'] as num? ?? 0).toInt();
    final cardAmt = (z['cardAmount'] as num? ?? 0.0).toDouble();
    final cardCnt = (z['cardCount'] as num? ?? 0).toInt();
    final atmAmt = (z['atmAmount'] as num? ?? 0.0).toDouble();
    final atmCnt = (z['atmCount'] as num? ?? 0).toInt();
    final chkAmt = (z['checkAmount'] as num? ?? 0.0).toDouble();
    final chkCnt = (z['checkCount'] as num? ?? 0).toInt();
    final gcAmt = (z['giftCheckAmount'] as num? ?? 0.0).toDouble();
    final gcCnt = (z['giftCheckCount'] as num? ?? 0).toInt();
    final chgAmt = (z['chargeAmount'] as num? ?? 0.0).toDouble();
    final chgCnt = (z['chargeCount'] as num? ?? 0).toInt();

    final cashIn = (z['cashIn'] as num? ?? shiftState?.cashIn ?? 0.0).toDouble();
    final cashOut =
        (z['cashOut'] as num? ?? shiftState?.cashOut ?? 0.0).toDouble();
    final expectedCash =
        (z['expectedCash'] as num? ??
                shiftState?.expectedTotalCash ??
                (beginningCash + cashSales + cashIn - cashOut))
            .toDouble();
    final declaredCash =
        (z['declaredCash'] as num? ?? shiftState?.declaredCash ?? 0.0)
            .toDouble();
    final shortOver =
        (z['shortOver'] as num? ?? (declaredCash - expectedCash)).toDouble();

    final grossSales = (z['grossSales'] as num? ?? cashSales).toDouble();
    final postVoidAmt = (z['postVoidAmount'] as num? ?? 0.0).toDouble();
    final postVoidCnt = (z['postVoidCount'] as num? ?? 0).toInt();
    final totalDiscounts = (z['totalDiscounts'] as num? ?? 0.0).toDouble();
    final surchargeAmt = (z['surchargeAmount'] as num? ?? 0.0).toDouble();
    final netSales = (z['netSales'] as num? ?? cashSales).toDouble();
    final vatableSales =
        (z['vatableSales'] as num? ?? (netSales / 1.12)).toDouble();
    final vatAmount =
        (z['vatAmount'] as num? ?? (netSales - vatableSales)).toDouble();
    final vatExempt = (z['vatExemptSales'] as num? ?? 0.0).toDouble();
    final zeroRated = (z['zeroRatedSales'] as num? ?? 0.0).toDouble();
    final begSiNo = (z['begSiNo'] as num? ?? 0).toInt();
    final endSiNo = (z['endSiNo'] as num? ?? 0).toInt();
    final begTseqNo = (z['begTseqNo'] as num? ?? 0).toInt();
    final endTseqNo = (z['endTseqNo'] as num? ?? 0).toInt();
    final salesCount = (z['salesCount'] as num? ?? 0).toInt();
    final guestCount = (z['guestCount'] as num? ?? 0).toInt();

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
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: Color(0xFFDC2626),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Z-Reading (End of Day Closeout)',
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
                        'Z-READING REPORT (END-OF-DAY)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      Text(
                        'TIN: ${settings.taxId} • PERMIT: ${settings.permitNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _receiptDivider(),
                      const SizedBox(height: 8),

                      _row('Z-Counter No:', '#$nextZNo', isBold: true),
                      _row('Terminal No:', '#01'),
                      _row('EOD Close Date:', dateFormat.format(DateTime.now())),
                      _row(
                        'SI# Range:',
                        '${begSiNo.toString().padLeft(6, '0')} - ${endSiNo.toString().padLeft(6, '0')}',
                      ),
                      _row('TSEQ# Range:', '$begTseqNo - $endTseqNo'),
                      _row('Txns / Guests:', '$salesCount / $guestCount'),

                      const SizedBox(height: 8),
                      _receiptDivider(),
                      const SizedBox(height: 8),

                      _sectionTitle('CONSOLIDATED PAYMENT MEDIA'),
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

                      _sectionTitle('CONSOLIDATED CASH ACCOUNTABILITY'),
                      _row(
                        'Opening Change Funds:',
                        '₱${beginningCash.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Add Cash Sales:',
                        '₱${cashSales.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Add Cash In:',
                        '₱${cashIn.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Less Cash Out:',
                        '-₱${cashOut.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Expected Cash:',
                        '₱${expectedCash.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                      _row(
                        'Declared Physical Cash:',
                        '₱${declaredCash.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                      _row(
                        'Short / Over:',
                        '₱${shortOver.toStringAsFixed(2)}',
                        isBold: true,
                        color: shortOver < 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                      ),

                      const SizedBox(height: 8),
                      _receiptDivider(),
                      const SizedBox(height: 8),

                      _sectionTitle('ACCUMULATED GRAND TOTALS & VAT'),
                      _row(
                        'GROSS SALES:',
                        '₱${grossSales.toStringAsFixed(2)}',
                        isBold: true,
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
                        'NET SALES TODAY:',
                        '₱${netSales.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                      const Divider(color: Color(0xFFCBD5E1), height: 14),
                      _row(
                        'Previous Grand Total:',
                        '₱${prevGrand.toStringAsFixed(2)}',
                      ),
                      _row(
                        'Present Grand Total:',
                        '₱${presGrand.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                      const Divider(color: Color(0xFFCBD5E1), height: 14),
                      _row(
                        'VATable Sales (12%):',
                        '₱${vatableSales.toStringAsFixed(2)}',
                      ),
                      _row(
                        'VAT Amount (12%):',
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
                        '*** END OF Z-READING REPORT ***\nSTORE CLOSED & AUDIT LOGGED',
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
                        if (shiftState != null) {
                          await PrinterService.printShiftReadingReport(
                            shiftState: shiftState!,
                            isZReading: true,
                          );
                        } else {
                          await PrinterService.printZReadingMapReport(z);
                        }
                      } catch (_) {}
                      if (context.mounted) {
                        AppToast.showInfo(
                          context,
                          message:
                              'Z-Reading #$nextZNo printed & End-of-Day closed.',
                          title: 'End of the Day (Z-Reading)',
                        );
                        Navigator.of(context).pop(true);
                      }
                    },
                    icon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Confirm Z-Read & Close Day',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
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
            color: const Color(0xFFDC2626),
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
