import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/data/dao/bank_dao.dart';
import 'package:suki_pos/data/dao/charge_payment_dao.dart';
import 'package:suki_pos/data/dao/payment_method_dao.dart';
import 'package:suki_pos/domain/entities/maintenance/bank.dart';
import 'package:suki_pos/domain/entities/maintenance/charge.dart';
import 'package:suki_pos/domain/entities/maintenance/payment_method.dart';
import 'package:suki_pos/domain/entities/pos/tender_payment_leg.dart';
import 'package:suki_pos/injection_container.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';

enum PaymentSegment { cash, card, ewallet, bankCheck, voucher, charge }

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
    List<TenderPaymentLeg>? payments,
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
  List<Map<String, dynamic>> _giftChecks = [];

  final List<TenderPaymentLeg> _splitLegs = [];

  PaymentSegment _currentSegment = PaymentSegment.cash;
  int? _selectedBankId;
  int? _selectedChargeId;
  int? _selectedGiftCheckId;
  int _selectedCardType = 2; // 1 = Debit, 2 = Credit

  int? _selectedMethodId;
  String _selectedMethodCode = 'cash';
  String _selectedMethodName = 'Cash';

  // Form controllers
  final _tenderController = TextEditingController();
  final _applyAmountController = TextEditingController();
  final _refNoController = TextEditingController();
  final _cardNoController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _approvalNoController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _gcQtyController = TextEditingController(text: '1');
  final _gcSerialsController = TextEditingController();

  final _focusNode = FocusNode();
  bool _loading = true;

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  double get _paidSoFar =>
      _splitLegs.fold<double>(0.0, (sum, leg) => sum + leg.amount);

  double get _remainingBalance =>
      (widget.totalDue - _paidSoFar).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _tenderController.text = widget.totalDue.toStringAsFixed(2);
    _applyAmountController.text = widget.totalDue.toStringAsFixed(2);
    _loadData();
  }

  @override
  void dispose() {
    _tenderController.dispose();
    _applyAmountController.dispose();
    _refNoController.dispose();
    _cardNoController.dispose();
    _cardExpiryController.dispose();
    _approvalNoController.dispose();
    _customerNameController.dispose();
    _gcQtyController.dispose();
    _gcSerialsController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final methods = await sl<PaymentMethodDao>().getActivePaymentMethods();
    final banks = await sl<BankDao>().getActiveBanks();
    final charges = await sl<ChargePaymentDao>().getActiveChargePayments();
    final db = await sl<DatabaseHelper>().database;
    final giftChecks = await db.query(
      SchemaConstants.giftCheck,
      where: 'is_active = 1',
      orderBy: 'id ASC',
    );

    if (!mounted) return;
    setState(() {
      _methods = methods;
      _banks = banks;
      _charges = charges;
      _giftChecks = giftChecks;

      _selectSegment(PaymentSegment.cash);
      _loading = false;
    });
  }

  void _selectSegment(PaymentSegment segment) {
    _currentSegment = segment;
    final rem = _remainingBalance;
    _applyAmountController.text = rem.toStringAsFixed(2);
    _tenderController.text = rem.toStringAsFixed(2);

    PaymentMethod? matchedMethod;
    switch (segment) {
      case PaymentSegment.cash:
        matchedMethod = _methods
                .where((m) => m.code.toLowerCase() == 'cash')
                .firstOrNull ??
            _methods.firstOrNull;
        break;
      case PaymentSegment.card:
        matchedMethod = _methods
                .where((m) => m.code.toLowerCase() == 'card')
                .firstOrNull ??
            _methods.where((m) => m.code.toLowerCase() == 'atm').firstOrNull;
        final cardBanks =
            _banks.where((b) => b.cardType == 1 || b.cardType == 2).toList();
        if (cardBanks.isNotEmpty) {
          _selectedBankId = cardBanks.first.id;
          _selectedCardType = cardBanks.first.cardType ?? 2;
        } else if (_banks.isNotEmpty) {
          _selectedBankId = _banks.first.id;
        }
        break;
      case PaymentSegment.ewallet:
        matchedMethod = _methods
                .where(
                  (m) =>
                      m.code.toLowerCase() == 'atm' ||
                      m.code.toLowerCase() == 'online',
                )
                .firstOrNull ??
            _methods.where((m) => m.code.toLowerCase() == 'card').firstOrNull;
        final walletBanks = _banks.where((b) => b.cardType == 3).toList();
        if (walletBanks.isNotEmpty) {
          _selectedBankId = walletBanks.first.id;
        } else if (_banks.isNotEmpty) {
          _selectedBankId = _banks.first.id;
        }
        break;
      case PaymentSegment.bankCheck:
        matchedMethod = _methods
            .where((m) => m.code.toLowerCase() == 'bank_check')
            .firstOrNull;
        if (_banks.isNotEmpty && _selectedBankId == null) {
          _selectedBankId = _banks.first.id;
        }
        break;
      case PaymentSegment.voucher:
        matchedMethod = _methods
            .where(
              (m) =>
                  m.code.toLowerCase() == 'gift_check' ||
                  m.code.toLowerCase() == 'coupon',
            )
            .firstOrNull;
        if (_giftChecks.isNotEmpty) {
          _selectedGiftCheckId ??= _giftChecks.first['id'] as int;
          _recalcGiftCheckAmount();
        }
        break;
      case PaymentSegment.charge:
        matchedMethod =
            _methods.where((m) => m.code.toLowerCase() == 'charge').firstOrNull;
        if (_charges.isNotEmpty) {
          _selectedChargeId = _charges.first.id;
        }
        break;
    }

    if (matchedMethod != null) {
      _selectedMethodId = matchedMethod.id;
      _selectedMethodCode = matchedMethod.code.toLowerCase();
      _selectedMethodName = matchedMethod.name;
    } else {
      // Fallback standard IDs seeded in SchemaConstants
      switch (segment) {
        case PaymentSegment.cash:
          _selectedMethodId = 1;
          _selectedMethodCode = 'cash';
          _selectedMethodName = 'Cash';
          break;
        case PaymentSegment.card:
          _selectedMethodId = 2;
          _selectedMethodCode = 'card';
          _selectedMethodName = 'Credit/Debit Card';
          break;
        case PaymentSegment.ewallet:
          _selectedMethodId = 3;
          _selectedMethodCode = 'atm';
          _selectedMethodName = 'ATM / Online Banking';
          break;
        case PaymentSegment.bankCheck:
          _selectedMethodId = 4;
          _selectedMethodCode = 'bank_check';
          _selectedMethodName = 'Bank Check';
          break;
        case PaymentSegment.voucher:
          _selectedMethodId = 5;
          _selectedMethodCode = 'gift_check';
          _selectedMethodName = 'Gift Check';
          break;
        case PaymentSegment.charge:
          _selectedMethodId = 6;
          _selectedMethodCode = 'charge';
          _selectedMethodName = 'Charge Account';
          break;
      }
    }
  }

  void _recalcGiftCheckAmount() {
    if (_selectedGiftCheckId == null || _giftChecks.isEmpty) return;
    final gc = _giftChecks
        .where((g) => g['id'] == _selectedGiftCheckId)
        .firstOrNull;
    if (gc == null) return;
    final unitAmt = (gc['amount'] as num? ?? 0.0).toDouble();
    final qty = int.tryParse(_gcQtyController.text) ?? 1;
    final totalFace = unitAmt * (qty > 0 ? qty : 1);
    _tenderController.text = totalFace.toStringAsFixed(2);
    final rem = _remainingBalance;
    _applyAmountController.text =
        (totalFace < rem ? totalFace : rem).toStringAsFixed(2);
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
      if (text == '0' || text == _remainingBalance.toStringAsFixed(2)) {
        _tenderController.text = val;
      } else {
        _tenderController.text = text + val;
      }
    }
    setState(() {});
  }

  TenderPaymentLeg? _buildCurrentLeg({required bool forFullRemainder}) {
    if (_selectedMethodId == null) return null;
    final rem = _remainingBalance;
    if (rem <= 0.001) return null;

    final rawApply = double.tryParse(_applyAmountController.text) ?? rem;
    final appliedAmount = forFullRemainder
        ? rem
        : rawApply.clamp(0.01, rem);

    final isCash = _currentSegment == PaymentSegment.cash;
    final isCheck = _currentSegment == PaymentSegment.bankCheck;
    final isVoucher = _currentSegment == PaymentSegment.voucher;

    final rawTender =
        double.tryParse(_tenderController.text) ?? appliedAmount;
    final tendered = (isCash || isCheck || isVoucher)
        ? rawTender
        : appliedAmount;

    if (isCash && tendered < appliedAmount - 0.001) return null;
    if ((isCheck || isVoucher) && tendered < appliedAmount - 0.001) return null;

    final change = isCash
        ? (tendered - appliedAmount).clamp(0.0, double.infinity)
        : 0.0;
    final excess = (isCheck || isVoucher)
        ? (tendered - appliedAmount).clamp(0.0, double.infinity)
        : 0.0;

    final bankName = _banks
        .where((b) => b.id == _selectedBankId)
        .map((b) => b.name)
        .firstOrNull;

    return TenderPaymentLeg(
      paymentMethodId: _selectedMethodId!,
      paymentMethodCode: _selectedMethodCode,
      paymentMethodName: _selectedMethodName,
      amount: appliedAmount,
      cashTendered: tendered,
      changeGiven: change,
      excessAmount: excess,
      cashlessAmount: isCash ? null : tendered,
      bankId: (_currentSegment == PaymentSegment.card ||
              _currentSegment == PaymentSegment.ewallet ||
              _currentSegment == PaymentSegment.bankCheck)
          ? _selectedBankId
          : null,
      bankName: bankName,
      cardType: _currentSegment == PaymentSegment.card
          ? _selectedCardType
          : (_currentSegment == PaymentSegment.ewallet ? 3 : null),
      cardNumber: _currentSegment == PaymentSegment.card &&
              _cardNoController.text.trim().isNotEmpty
          ? _cardNoController.text.trim()
          : null,
      cardExpiry: _currentSegment == PaymentSegment.card &&
              _cardExpiryController.text.trim().isNotEmpty
          ? _cardExpiryController.text.trim()
          : null,
      approvalNumber: _currentSegment == PaymentSegment.card &&
              _approvalNoController.text.trim().isNotEmpty
          ? _approvalNoController.text.trim()
          : null,
      referenceNumber: _refNoController.text.trim().isNotEmpty
          ? _refNoController.text.trim()
          : (_approvalNoController.text.trim().isNotEmpty
                ? _approvalNoController.text.trim()
                : null),
      paymentChannel: _currentSegment == PaymentSegment.ewallet
          ? bankName ?? 'E-Wallet'
          : null,
      merchantTerminal: _currentSegment == PaymentSegment.card
          ? bankName
          : null,
      giftCheckId:
          _currentSegment == PaymentSegment.voucher ? _selectedGiftCheckId : null,
      giftCheckQty: _currentSegment == PaymentSegment.voucher
          ? (int.tryParse(_gcQtyController.text) ?? 1)
          : null,
      serialNumbers: _currentSegment == PaymentSegment.voucher &&
              _gcSerialsController.text.trim().isNotEmpty
          ? _gcSerialsController.text.trim()
          : null,
      chargeAccountId:
          _currentSegment == PaymentSegment.charge ? _selectedChargeId : null,
      customerName: _customerNameController.text.trim().isNotEmpty
          ? _customerNameController.text.trim()
          : null,
    );
  }

  void _addSplitLeg() {
    final leg = _buildCurrentLeg(forFullRemainder: false);
    if (leg == null) return;
    FeedbackService.tap();
    setState(() {
      _splitLegs.add(leg);
      _refNoController.clear();
      _cardNoController.clear();
      _cardExpiryController.clear();
      _approvalNoController.clear();
      _gcSerialsController.clear();
      final rem = _remainingBalance;
      _applyAmountController.text = rem.toStringAsFixed(2);
      _tenderController.text = rem.toStringAsFixed(2);
    });
  }

  void _removeSplitLeg(int index) {
    FeedbackService.tap();
    setState(() {
      _splitLegs.removeAt(index);
      final rem = _remainingBalance;
      _applyAmountController.text = rem.toStringAsFixed(2);
      _tenderController.text = rem.toStringAsFixed(2);
    });
  }

  void _submitPayment() {
    final List<TenderPaymentLeg> allLegs = List.from(_splitLegs);
    if (_remainingBalance > 0.009) {
      final finalLeg = _buildCurrentLeg(forFullRemainder: true);
      if (finalLeg == null) return;
      allLegs.add(finalLeg);
    }

    if (allLegs.isEmpty) return;
    FeedbackService.tap();

    final primaryLeg = allLegs.first;
    final totalTendered =
        allLegs.fold<double>(0.0, (sum, l) => sum + l.cashTendered);
    final totalChange =
        allLegs.fold<double>(0.0, (sum, l) => sum + l.changeGiven);
    final combinedMethodName =
        allLegs.map((l) => l.paymentMethodName).toSet().join(' + ');

    widget.onComplete(
      primaryLeg.paymentMethodId,
      combinedMethodName,
      totalTendered,
      totalChange,
      bankId: primaryLeg.bankId,
      referenceNumber: primaryLeg.referenceNumber ?? primaryLeg.approvalNumber,
      chargeAccountId: primaryLeg.chargeAccountId,
      payments: allLegs,
    );
    Navigator.of(context).pop();
  }

  double get _nextHundredAmount {
    final due = _remainingBalance;
    final remainder = due % 100;
    if (remainder == 0) return due + 100;
    return (due + (100 - remainder));
  }

  bool get _canSubmitCurrent {
    if (_remainingBalance <= 0.009 && _splitLegs.isNotEmpty) return true;
    return _buildCurrentLeg(forFullRemainder: true) != null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      );
    }

    final isCash = _currentSegment == PaymentSegment.cash;
    final rem = _remainingBalance;
    final tendered = isCash
        ? (double.tryParse(_tenderController.text) ?? 0.0)
        : (double.tryParse(_tenderController.text) ?? rem);
    final change = isCash && tendered >= rem ? tendered - rem : 0.0;
    final isValid = _canSubmitCurrent;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (isValid) _submitPayment();
        },
      },
      child: CustomFormDialog(
        title: 'Tender Payment & Settle Bill',
        maxWidth: 720,
        saveLabel:
            'Complete Sale (₱${widget.totalDue.toStringAsFixed(2)})',
        onSave: isValid ? _submitPayment : () {},
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Total Due & Remaining Balance Banner
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
                        _splitLegs.isEmpty
                            ? 'TOTAL DUE'
                            : 'REMAINING BALANCE (SPLIT PAYMENT)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF93C5FD),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _splitLegs.isEmpty
                            ? 'Net payable balance'
                            : 'Total Bill: ₱${widget.totalDue.toStringAsFixed(2)} • Paid: ₱${_paidSoFar.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₱${rem.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // 1B. Added Split Payment Legs
            if (_splitLegs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applied Payment Legs (${_splitLegs.length})',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...List.generate(_splitLegs.length, (i) {
                      final leg = _splitLegs[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 15,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${leg.paymentMethodName}: ₱${leg.amount.toStringAsFixed(2)}${leg.excessAmount > 0 ? " (Excess: ₱${leg.excessAmount.toStringAsFixed(2)})" : ""}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _removeSplitLeg(i),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // 2. 6-Segment Payment Method Selector (KwikPOS Lite Parity)
            Text(
              'Payment Mode (6 Tenders)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
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
                  _buildSegmentButton(
                    'Cash',
                    Icons.payments_rounded,
                    PaymentSegment.cash,
                  ),
                  _buildSegmentButton(
                    'Card',
                    Icons.credit_card_rounded,
                    PaymentSegment.card,
                  ),
                  _buildSegmentButton(
                    'ATM/QR',
                    Icons.qr_code_rounded,
                    PaymentSegment.ewallet,
                  ),
                  _buildSegmentButton(
                    'Check',
                    Icons.account_balance_rounded,
                    PaymentSegment.bankCheck,
                  ),
                  _buildSegmentButton(
                    'Gift Check',
                    Icons.card_giftcard_rounded,
                    PaymentSegment.voucher,
                  ),
                  _buildSegmentButton(
                    'Charge',
                    Icons.receipt_long_rounded,
                    PaymentSegment.charge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Split Payment Partial Amount Bar
            if (rem > 0.01) ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _applyAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount to Apply for this Tender',
                          prefixText: '₱ ',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _addSplitLeg,
                    icon: const Icon(Icons.call_split_rounded, size: 16),
                    label: Text(
                      'Add Split Leg',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: const BorderSide(color: primaryBlue),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 4. Dynamic Form per Segment
            if (isCash)
              _buildCashPaymentForm(tendered, change, rem)
            else if (_currentSegment == PaymentSegment.card)
              _buildCardPaymentForm(rem)
            else if (_currentSegment == PaymentSegment.ewallet)
              _buildEWalletPaymentForm(rem)
            else if (_currentSegment == PaymentSegment.bankCheck)
              _buildBankCheckPaymentForm(rem)
            else if (_currentSegment == PaymentSegment.voucher)
              _buildGiftCheckPaymentForm(rem)
            else if (_currentSegment == PaymentSegment.charge)
              _buildChargePaymentForm(rem),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(
    String label,
    IconData icon,
    PaymentSegment segment,
  ) {
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
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? primaryBlue : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? primaryBlue : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. CASH FORM (NUMPAD + CHIPS + CHANGE DUE)
  // ===========================================================================

  Widget _buildCashPaymentForm(
    double tendered,
    double change,
    double remainingDue,
  ) {
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
                    'Cash Tendered',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _tenderController,
                    focusNode: _focusNode,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₱ ',
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: surfaceBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 2,
                        ),
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
                      _buildQuickTenderChip(
                        'Exact',
                        () => _setTenderAmount(remainingDue),
                        isPrimary: true,
                      ),
                      if (_nextHundredAmount > remainingDue)
                        _buildQuickTenderChip(
                          '₱${_nextHundredAmount.toStringAsFixed(0)}',
                          () => _setTenderAmount(_nextHundredAmount),
                        ),
                      _buildQuickTenderChip(
                        '₱100',
                        () => _setTenderAmount(100),
                      ),
                      _buildQuickTenderChip(
                        '₱200',
                        () => _setTenderAmount(200),
                      ),
                      _buildQuickTenderChip(
                        '₱500',
                        () => _setTenderAmount(500),
                      ),
                      _buildQuickTenderChip(
                        '₱1,000',
                        () => _setTenderAmount(1000),
                      ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tendered >= remainingDue
                ? const Color(0xFFECFDF5)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: tendered >= remainingDue
                  ? const Color(0xFFA7F3D0)
                  : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    tendered >= remainingDue
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: tendered >= remainingDue
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tendered >= remainingDue
                        ? 'Change Due:'
                        : 'Insufficient Tender:',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: tendered >= remainingDue
                          ? const Color(0xFF065F46)
                          : const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
              Text(
                '₱${change.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: tendered >= remainingDue
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. CREDIT / DEBIT CARD FORM (card_trans parity)
  // ===========================================================================

  Widget _buildCardPaymentForm(double remainingDue) {
    final cardBanks =
        _banks.where((b) => b.cardType == 1 || b.cardType == 2).toList();
    final banksList = cardBanks.isNotEmpty ? cardBanks : _banks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank / Card Terminal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (banksList.isEmpty)
                    const Text('No banks configured')
                  else
                    DropdownButtonFormField<int>(
                      value: _selectedBankId,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      items: banksList
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedBankId = val),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Type',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _selectedCardType,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('Credit Card')),
                      DropdownMenuItem(value: 1, child: Text('Debit Card')),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedCardType = val ?? 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardNoController,
                decoration: InputDecoration(
                  labelText: 'Card Number (Last 4 / Masked)',
                  hintText: 'e.g. **** 1234',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _cardExpiryController,
                decoration: InputDecoration(
                  labelText: 'Expiry (MM/YY)',
                  hintText: '12/28',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _approvalNoController,
                decoration: InputDecoration(
                  labelText: 'Approval / Trace No.',
                  hintText: 'e.g. APP-9012',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _customerNameController,
          decoration: InputDecoration(
            labelText: 'Cardholder / Customer Name (Optional)',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. ATM / E-WALLET / ONLINE FORM (atm_trans parity)
  // ===========================================================================

  Widget _buildEWalletPaymentForm(double remainingDue) {
    final walletBanks = _banks.where((b) => b.cardType == 3).toList();
    final walletsList = walletBanks.isNotEmpty ? walletBanks : _banks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATM / E-Wallet / Online Channel',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        if (walletsList.isNotEmpty)
          DropdownButtonFormField<int>(
            value: _selectedBankId,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
            items: walletsList
                .map(
                  (b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(b.name),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedBankId = val),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _refNoController,
                decoration: InputDecoration(
                  labelText: 'Reference / ATM Account No.',
                  hintText: 'e.g. 1029 3847 2910',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Sender / Customer Name',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. BANK CHECK FORM (bank_check_trans parity with Excess calculation)
  // ===========================================================================

  Widget _buildBankCheckPaymentForm(double remainingDue) {
    final checkAmount =
        double.tryParse(_tenderController.text) ?? remainingDue;
    final applied =
        (double.tryParse(_applyAmountController.text) ?? remainingDue)
            .clamp(0.0, remainingDue);
    final excess = (checkAmount - applied).clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _banks.isEmpty
                  ? const Text('No banks configured')
                  : DropdownButtonFormField<int>(
                      value: _selectedBankId,
                      decoration: InputDecoration(
                        labelText: 'Issuing Bank',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _banks
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedBankId = val),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _refNoController,
                decoration: InputDecoration(
                  labelText: 'Check Number *',
                  hintText: 'e.g. CHK-004921',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tenderController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Check Face Amount',
                  prefixText: '₱ ',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Payor / Customer Name',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check Excess (Non-Refundable):',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF92400E),
                ),
              ),
              Text(
                '₱${excess.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. GIFT CHECK / VOUCHER FORM (gift_check_trans parity + serials + excess)
  // ===========================================================================

  Widget _buildGiftCheckPaymentForm(double remainingDue) {
    final gcFaceAmount =
        double.tryParse(_tenderController.text) ?? remainingDue;
    final applied =
        (double.tryParse(_applyAmountController.text) ?? remainingDue)
            .clamp(0.0, remainingDue);
    final excess = (gcFaceAmount - applied).clamp(0.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _giftChecks.isEmpty
                  ? TextField(
                      controller: _tenderController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Gift Check Face Amount',
                        prefixText: '₱ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    )
                  : DropdownButtonFormField<int>(
                      value: _selectedGiftCheckId,
                      decoration: InputDecoration(
                        labelText: 'Gift Check / Voucher Type',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: _giftChecks
                          .map(
                            (gc) => DropdownMenuItem<int>(
                              value: gc['id'] as int,
                              child: Text(
                                '${gc['name']} (₱${(gc['amount'] as num).toStringAsFixed(2)})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedGiftCheckId = val;
                          _recalcGiftCheckAmount();
                        });
                      },
                    ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _gcQtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Qty',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() => _recalcGiftCheckAmount()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _tenderController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Total GC Value',
                  prefixText: '₱ ',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _gcSerialsController,
          decoration: InputDecoration(
            labelText: 'Gift Check Serial Number(s) (comma-separated)',
            hintText: 'e.g. GC-1001, GC-1002',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gift Check Excess (Forfeited):',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF92400E),
                ),
              ),
              Text(
                '₱${excess.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. CHARGE ACCOUNT FORM (charge_trans parity)
  // ===========================================================================

  Widget _buildChargePaymentForm(double remainingDue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Charge Account Client / Company',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        if (_charges.isEmpty)
          const Text('No charge accounts registered.')
        else
          DropdownButtonFormField<int>(
            value: _selectedChargeId,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
            items: _charges
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.code} - ${c.name}'),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedChargeId = val),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _refNoController,
                decoration: InputDecoration(
                  labelText: 'Charge Reference / PO No.',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Authorized Signatory / Customer',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickTenderChip(
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary
              ? primaryBlue.withOpacity(0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? primaryBlue.withOpacity(0.3) : surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isPrimary ? primaryBlue : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: InkWell(
              onTap: () => _onNumpadPress(key),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: surfaceBorder),
                ),
                child: Text(
                  key,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
