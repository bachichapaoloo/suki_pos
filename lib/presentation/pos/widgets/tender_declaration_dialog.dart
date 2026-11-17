import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../domain/entities/shift/cash_denomination_count.dart';
import '../../widgets/custom_form_dialog.dart';

class TenderDeclarationDialog extends StatefulWidget {
  final Function(List<CashDenominationCount> denominations, double totalCash)
  onConfirm;
  final List<CashDenominationCount>? initialDenominations;
  final Map<String, dynamic>? nonCashSummary;

  const TenderDeclarationDialog({
    super.key,
    required this.onConfirm,
    this.initialDenominations,
    this.nonCashSummary,
  });

  @override
  State<TenderDeclarationDialog> createState() =>
      _TenderDeclarationDialogState();
}

class _TenderDeclarationDialogState extends State<TenderDeclarationDialog> {
  final Map<double, TextEditingController> _controllers = {};

  /// All 12 KwikPOS Lite denominations
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
    0.10,
    0.05,
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

  double get _totalCashAmount {
    double sum = 0.0;
    _controllers.forEach((denom, controller) {
      final count = int.tryParse(controller.text) ?? 0;
      sum += (denom * count);
    });
    return sum;
  }

  double get _totalNonCashAmount =>
      (widget.nonCashSummary?['totalNonCash'] as num? ?? 0.0).toDouble();

  void _submit() {
    final List<CashDenominationCount> list = [];
    _controllers.forEach((denom, controller) {
      final count = int.tryParse(controller.text) ?? 0;
      list.add(CashDenominationCount(denomination: denom, count: count));
    });

    widget.onConfirm(list, _totalCashAmount);
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
    final nc = widget.nonCashSummary ?? const {};
    final cardAmt = (nc['cardAmount'] as num? ?? 0.0).toDouble();
    final cardCnt = (nc['cardCount'] as num? ?? 0).toInt();
    final atmAmt = (nc['atmAmount'] as num? ?? 0.0).toDouble();
    final atmCnt = (nc['atmCount'] as num? ?? 0).toInt();
    final chkAmt = (nc['checkAmount'] as num? ?? 0.0).toDouble();
    final chkCnt = (nc['checkCount'] as num? ?? 0).toInt();
    final gcAmt = (nc['giftCheckAmount'] as num? ?? 0.0).toDouble();
    final gcCnt = (nc['giftCheckCount'] as num? ?? 0).toInt();
    final chgAmt = (nc['chargeAmount'] as num? ?? 0.0).toDouble();
    final chgCnt = (nc['chargeCount'] as num? ?? 0).toInt();

    return CustomFormDialog(
      title: 'Tender Declaration & Physical Cash Count',
      maxWidth: 660,
      saveLabel: 'Save Tender Declaration',
      onSave: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Auto-Populated Shift Non-Cash Tender Summary (KwikPOS Lite Parity)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shift Non-Cash Media (Auto-Calculated)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _nonCashBadge('Card ($cardCnt)', cardAmt),
                    _nonCashBadge('ATM/Online ($atmCnt)', atmAmt),
                    _nonCashBadge('Bank Check ($chkCnt)', chkAmt),
                    _nonCashBadge('Gift Check ($gcCnt)', gcAmt),
                    _nonCashBadge('Charge ($chgCnt)', chgAmt),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 2. Physical Denominations List (12 Denominations)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _denominations.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final denom = _denominations[index];
              final ctrl = _controllers[denom]!;
              final count = int.tryParse(ctrl.text) ?? 0;
              final subtotal = count * denom;
              final isBill = denom >= 20;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 90,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
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
                          fontSize: 13.5,
                          color: isBill
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                      onPressed: () => _decrement(denom),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      height: 36,
                      child: TextFormField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: surfaceBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: primaryBlue,
                      ),
                      onPressed: () => _increment(denom),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Spacer(),
                    Text(
                      '₱${subtotal.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          // 3. Total Declared Cash & Total All Tenders Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Declared Physical Cash:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textDark,
                      ),
                    ),
                    Text(
                      '₱${_totalCashAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
                if (_totalNonCashAmount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Declared (Cash + Non-Cash):',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      Text(
                        '₱${(_totalCashAmount + _totalNonCashAmount).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nonCashBadge(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: surfaceBorder),
      ),
      child: Text(
        '$label: ₱${amount.toStringAsFixed(2)}',
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
    );
  }
}
