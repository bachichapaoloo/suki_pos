import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/data/dao/bank_dao.dart';
import 'package:suki_pos/data/dao/charge_payment_dao.dart';
import 'package:suki_pos/data/dao/payment_method_dao.dart';
import 'package:suki_pos/domain/entities/maintenance/bank.dart';
import 'package:suki_pos/domain/entities/maintenance/charge.dart';
import 'package:suki_pos/domain/entities/maintenance/payment_method.dart';
import 'package:suki_pos/injection_container.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';

enum PaymentSegment { cash, card, ewallet, charge, voucher }

class PaymentDialog extends StatefulWidget {
  final double totalDue;
  final Function(
    int methodId,
    String methodName,
    double tendered,
    double change, {
    int? bankId,
    String? referenceNumber,
    int? chargeAccountId,
  })
  onComplete;

  const PaymentDialog({
    super.key,
    required this.totalDue,
    required this.onComplete,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  List<PaymentMethod> _methods = [];
  List<Bank> _banks = [];
  List<Charge> _charges = [];

  PaymentSegment _currentSegment = PaymentSegment.cash;
  int? _selectedBankId;
  int? _selectedChargeId;
  final _refNoController = TextEditingController();

  int? _selectedMethodId;
  String _selectedMethodName = 'Cash';
  final _tenderController = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = true;

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _tenderController.text = widget.totalDue.toStringAsFixed(2);
    _loadData();
  }

  @override
  void dispose() {
    _tenderController.dispose();
    _refNoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final methods = await sl<PaymentMethodDao>().getActivePaymentMethods();
    final banks = await sl<BankDao>().getActiveBanks();
    final charges = await sl<ChargePaymentDao>().getActiveChargePayments();

    if (!mounted) return;
    setState(() {
      _methods = methods;
      _banks = banks;
      _charges = charges;

      // Select initial cash method
      _selectSegment(PaymentSegment.cash);
      _loading = false;
    });
  }

  void _selectSegment(PaymentSegment segment) {
    _currentSegment = segment;

    PaymentMethod? matchedMethod;
    switch (segment) {
      case PaymentSegment.cash:
        matchedMethod = _methods.where((m) => m.code.toLowerCase() == 'cash').firstOrNull ?? _methods.firstOrNull;
        _tenderController.text = widget.totalDue.toStringAsFixed(2);
        break;
      case PaymentSegment.card:
        matchedMethod =
            _methods.where((m) => m.code.toLowerCase() == 'card').firstOrNull ??
            _methods.where((m) => m.code.toLowerCase() == 'atm').firstOrNull;
        _tenderController.text = widget.totalDue.toStringAsFixed(2);
        // Default card terminal
        final cardBanks = _banks.where((b) => b.cardType == 1 || b.cardType == 2).toList();
        if (cardBanks.isNotEmpty) {
          _selectedBankId = cardBanks.first.id;
        }
        break;
      case PaymentSegment.ewallet:
        matchedMethod =
            _methods.where((m) => m.code.toLowerCase() == 'atm' || m.code.toLowerCase() == 'online').firstOrNull ??
            _methods.where((m) => m.code.toLowerCase() == 'card').firstOrNull;
        _tenderController.text = widget.totalDue.toStringAsFixed(2);
        // Default e-wallet
        final walletBanks = _banks.where((b) => b.cardType == 3).toList();
        if (walletBanks.isNotEmpty) {
          _selectedBankId = walletBanks.first.id;
        } else if (_banks.isNotEmpty) {
          _selectedBankId = _banks.first.id;
        }
        break;
      case PaymentSegment.charge:
        matchedMethod = _methods.where((m) => m.code.toLowerCase() == 'charge').firstOrNull;
        _tenderController.text = widget.totalDue.toStringAsFixed(2);
        if (_charges.isNotEmpty) {
          _selectedChargeId = _charges.first.id;
        }
        break;
      case PaymentSegment.voucher:
        matchedMethod = _methods
            .where((m) => m.code.toLowerCase() == 'gift_check' || m.code.toLowerCase() == 'coupon')
            .firstOrNull;
        _tenderController.text = widget.totalDue.toStringAsFixed(2);
        break;
    }

    if (matchedMethod != null) {
      _selectedMethodId = matchedMethod.id;
      _selectedMethodName = matchedMethod.name;
    }
  }

  void _setTenderAmount(double amt) {
    FeedbackService.tap();
    setState(() {
      _tenderController.text = amt.toStringAsFixed(2);
    });
  }

  void _addToTender(double additional) {
    FeedbackService.tap();
    final current = double.tryParse(_tenderController.text) ?? 0.0;
    setState(() {
      _tenderController.text = (current + additional).toStringAsFixed(2);
    });
  }

  void _onNumpadPress(String val) {
    FeedbackService.tap();
    final text = _tenderController.text;
    if (val == 'C') {
      _tenderController.clear();
    } else if (val == '⌫') {
      if (text.isNotEmpty) {
        _tenderController.text = text.substring(0, text.length - 1);
      }
    } else if (val == '.') {
      if (!text.contains('.')) {
        _tenderController.text = text.isEmpty ? '0.' : '$text.';
      }
    } else {
      if (text == '0' || text == widget.totalDue.toStringAsFixed(2)) {
        _tenderController.text = val;
      } else {
        _tenderController.text = text + val;
      }
    }
    setState(() {});
  }

  void _submitPayment() {
    final isCash = _currentSegment == PaymentSegment.cash;
    final tendered = isCash ? (double.tryParse(_tenderController.text) ?? 0.0) : widget.totalDue;

    if (isCash && tendered < widget.totalDue) return;
    if (_selectedMethodId == null) return;

    final change = isCash ? (tendered - widget.totalDue) : 0.0;
    FeedbackService.tap();

    widget.onComplete(
      _selectedMethodId!,
      _selectedMethodName,
      tendered,
      change,
      bankId: (_currentSegment == PaymentSegment.card || _currentSegment == PaymentSegment.ewallet)
          ? _selectedBankId
          : null,
      referenceNumber:
          (_currentSegment == PaymentSegment.card || _currentSegment == PaymentSegment.ewallet) &&
              _refNoController.text.trim().isNotEmpty
          ? _refNoController.text.trim()
          : null,
      chargeAccountId: _currentSegment == PaymentSegment.charge ? _selectedChargeId : null,
    );
    Navigator.of(context).pop();
  }

  double get _nextHundredAmount {
    final due = widget.totalDue;
    final remainder = due % 100;
    if (remainder == 0) return due + 100;
    return (due + (100 - remainder));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(content: Center(child: CircularProgressIndicator()));
    }

    final isCash = _currentSegment == PaymentSegment.cash;
    final tendered = isCash ? (double.tryParse(_tenderController.text) ?? 0.0) : widget.totalDue;
    final change = tendered >= widget.totalDue ? tendered - widget.totalDue : 0.0;
    final isValid = isCash ? (tendered >= widget.totalDue && _selectedMethodId != null) : (_selectedMethodId != null);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (isValid) _submitPayment();
        },
      },
      child: CustomFormDialog(
        title: 'Tender Payment & Settle Bill',
        maxWidth: isCash ? 680 : 590,
        saveLabel: 'Complete Sale (₱${widget.totalDue.toStringAsFixed(2)})',
        onSave: isValid ? _submitPayment : () {},
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Total Due Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL DUE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF93C5FD),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Net payable balance', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                  Text(
                    '₱${widget.totalDue.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Segmented Payment Method Selector
            Text(
              'Payment Mode',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: surfaceBorder),
              ),
              child: Row(
                children: [
                  _buildSegmentButton('Cash', Icons.payments_rounded, PaymentSegment.cash),
                  _buildSegmentButton('Card', Icons.credit_card_rounded, PaymentSegment.card),
                  _buildSegmentButton('E-Wallet', Icons.qr_code_rounded, PaymentSegment.ewallet),
                  _buildSegmentButton('Charge', Icons.receipt_long_rounded, PaymentSegment.charge),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Dynamic Form per Segment
            if (isCash)
              _buildCashPaymentForm(tendered, change)
            else if (_currentSegment == PaymentSegment.card)
              _buildCardPaymentForm()
            else if (_currentSegment == PaymentSegment.ewallet)
              _buildEWalletPaymentForm()
            else if (_currentSegment == PaymentSegment.charge)
              _buildChargePaymentForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, IconData icon, PaymentSegment segment) {
    final isSelected = _currentSegment == segment;
    return Expanded(
      child: InkWell(
        onTap: () {
          FeedbackService.tap();
          setState(() => _selectSegment(segment));
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? primaryBlue : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? primaryBlue : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CASH FORM (NUMPAD + CHIPS + CHANGE DUE)
  // ===========================================================================

  Widget _buildCashPaymentForm(double tendered, double change) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount Tendered',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textDark),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _tenderController,
                    focusNode: _focusNode,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: textDark),
                    decoration: InputDecoration(
                      prefixText: '₱ ',
                      prefixStyle: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: primaryBlue),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: surfaceBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: primaryBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickTenderChip('Exact', () => _setTenderAmount(widget.totalDue), isPrimary: true),
                      if (_nextHundredAmount > widget.totalDue)
                        _buildQuickTenderChip(
                          '₱${_nextHundredAmount.toStringAsFixed(0)}',
                          () => _setTenderAmount(_nextHundredAmount),
                        ),
                      _buildQuickTenderChip('₱100', () => _setTenderAmount(100)),
                      _buildQuickTenderChip('₱200', () => _setTenderAmount(200)),
                      _buildQuickTenderChip('₱500', () => _setTenderAmount(500)),
                      _buildQuickTenderChip('₱1,000', () => _setTenderAmount(1000)),
                      _buildQuickTenderChip('+₱50', () => _addToTender(50)),
                      _buildQuickTenderChip('+₱100', () => _addToTender(100)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: surfaceBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNumpadRow(['1', '2', '3']),
                    const SizedBox(height: 3),
                    _buildNumpadRow(['4', '5', '6']),
                    const SizedBox(height: 3),
                    _buildNumpadRow(['7', '8', '9']),
                    const SizedBox(height: 3),
                    _buildNumpadRow(['.', '0', '⌫']),
                    const SizedBox(height: 3),
                    InkWell(
                      onTap: () => _onNumpadPress('C'),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          'Clear',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Live Change Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tendered >= widget.totalDue ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: tendered >= widget.totalDue ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    tendered >= widget.totalDue ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    size: 16,
                    color: tendered >= widget.totalDue ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tendered >= widget.totalDue ? 'Change Due:' : 'Insufficient Tender:',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: tendered >= widget.totalDue ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
              Text(
                '₱${change.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: tendered >= widget.totalDue ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CREDIT / DEBIT CARD FORM
  // ===========================================================================

  Widget _buildCardPaymentForm() {
    final cardBanks = _banks.where((b) => b.cardType == 1 || b.cardType == 2).toList();
    final banksList = cardBanks.isNotEmpty ? cardBanks : _banks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Terminal / Bank Provider',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textDark),
        ),
        const SizedBox(height: 6),
        if (banksList.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'No bank terminals registered. Add terminals in Maintenance > Payment Methods.',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
          )
        else
          DropdownButtonFormField<int>(
            value: _selectedBankId,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
            items: banksList.map((b) {
              final isCredit = b.cardType == 2;
              return DropdownMenuItem(
                value: b.id,
                child: Row(
                  children: [
                    Icon(
                      isCredit ? Icons.credit_score_rounded : Icons.credit_card_rounded,
                      size: 18,
                      color: isCredit ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    Text('${b.name} (${isCredit ? 'Credit Card' : 'Debit Card'})'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedBankId = val),
          ),
        const SizedBox(height: 12),

        Text(
          'Card Approval / Trace ID (Optional)',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textDark),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _refNoController,
          decoration: InputDecoration(
            hintText: 'e.g. POS Trace No. / Approval Code',
            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 14),

        // Charge summary banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Charge ₱${widget.totalDue.toStringAsFixed(2)} directly to customer card terminal.',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E40AF)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // E-WALLET / QR FORM (GCASH, MAYA)
  // ===========================================================================

  Widget _buildEWalletPaymentForm() {
    final walletBanks = _banks.where((b) => b.cardType == 3).toList();
    final walletsList = walletBanks.isNotEmpty ? walletBanks : _banks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'E-Wallet Merchant Channel',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textDark),
        ),
        const SizedBox(height: 6),
        if (walletsList.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'No E-Wallets registered. Add GCash or Maya in Maintenance > Payment Methods.',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
          )
        else
          DropdownButtonFormField<int>(
            value: _selectedBankId,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
            items: walletsList.map((b) {
              return DropdownMenuItem(
                value: b.id,
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_rounded, size: 18, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text('${b.name} (E-Wallet)'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedBankId = val),
          ),
        const SizedBox(height: 12),

        Text(
          'Customer Reference / GCash Reference No.',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textDark),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _refNoController,
          decoration: InputDecoration(
            hintText: 'e.g. 1029 3847 2910',
            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 14),

        // E-wallet confirmation box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Received ₱${widget.totalDue.toStringAsFixed(2)} via digital QR payment.',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF065F46)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CHARGE ACCOUNT FORM
  // ===========================================================================

  Widget _buildChargePaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Charge Account Client / Company',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: textDark),
        ),
        const SizedBox(height: 6),
        if (_charges.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'No charge accounts registered. Add accounts in Maintenance > Payment Methods.',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
          )
        else
          DropdownButtonFormField<int>(
            value: _selectedChargeId,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
            items: _charges.map((c) {
              return DropdownMenuItem(
                value: c.id,
                child: Text('${c.code} - ${c.name}'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedChargeId = val),
          ),
        const SizedBox(height: 14),

        // Charge confirmation box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bill ₱${widget.totalDue.toStringAsFixed(2)} to account receivables.',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF5B21B6)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTenderChip(String label, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isPrimary ? primaryBlue.withOpacity(0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPrimary ? primaryBlue : surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isPrimary ? primaryBlue : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      children: keys.map((k) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: InkWell(
              onTap: () => _onNumpadPress(k),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: surfaceBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1)),
                  ],
                ),
                child: Text(
                  k,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
