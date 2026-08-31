import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/injection_container.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';
import 'package:suki_pos/presentation/widgets/hotkey_badge.dart';

class PaymentDialog extends StatefulWidget {
  final double totalDue;
  final Function(int methodId, String methodName, double tendered, double change) onComplete;

  const PaymentDialog({
    super.key,
    required this.totalDue,
    required this.onComplete,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  List<Map<String, dynamic>> _methods = [];
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
    _loadPaymentMethods();
    _tenderController.text = widget.totalDue.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _tenderController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    final db = await sl<DatabaseHelper>().database;
    final results = await db.query(
      SchemaConstants.paymentMethod,
      where: 'is_active = 1',
      orderBy: 'id ASC',
    );
    if (!mounted) return;
    setState(() {
      _methods = results;
      if (results.isNotEmpty) {
        _selectedMethodId = results.first['id'] as int;
        _selectedMethodName = results.first['name'] as String;
      }
      _loading = false;
    });
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
      // Digit 0-9
      if (text == '0' || text == widget.totalDue.toStringAsFixed(2)) {
        _tenderController.text = val;
      } else {
        _tenderController.text = text + val;
      }
    }
    setState(() {});
  }

  void _submitPayment() {
    final tendered = double.tryParse(_tenderController.text) ?? 0.0;
    if (tendered < widget.totalDue || _selectedMethodId == null) return;
    final change = tendered - widget.totalDue;
    FeedbackService.tap();
    widget.onComplete(_selectedMethodId!, _selectedMethodName, tendered, change);
    Navigator.of(context).pop();
  }

  double get _nextHundredAmount {
    final due = widget.totalDue;
    final remainder = due % 100;
    if (remainder == 0) return due + 100;
    return (due + (100 - remainder));
  }

  IconData _getMethodIcon(String code) {
    switch (code.toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'atm':
      case 'online':
        return Icons.account_balance_rounded;
      case 'charge':
        return Icons.receipt_long_rounded;
      case 'coupon':
      case 'gift_check':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(content: Center(child: CircularProgressIndicator()));
    }

    final tendered = double.tryParse(_tenderController.text) ?? 0.0;
    final change = tendered >= widget.totalDue ? tendered - widget.totalDue : 0.0;
    final isValid = tendered >= widget.totalDue && _selectedMethodId != null;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (isValid) _submitPayment();
        },
      },
      child: CustomFormDialog(
        title: 'Tender Payment & Settle Bill',
        maxWidth: 580,
        saveLabel: 'Complete Sale (₱${widget.totalDue.toStringAsFixed(2)})',
        onSave: isValid ? _submitPayment : () {},
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total Due Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL AMOUNT DUE',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF93C5FD), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text('Net payable balance', style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70)),
                    ],
                  ),
                  Text(
                    '₱${widget.totalDue.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Payment Method Selector Pills
            Text(
              'Payment Method',
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: textDark),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _methods.map((m) {
                  final isSelected = m['id'] == _selectedMethodId;
                  final code = (m['code'] ?? '') as String;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(
                        _getMethodIcon(code),
                        size: 16,
                        color: isSelected ? Colors.white : primaryBlue,
                      ),
                      label: Text(m['name'] as String),
                      selected: isSelected,
                      selectedColor: primaryBlue,
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : textDark,
                      ),
                      side: BorderSide(color: isSelected ? primaryBlue : surfaceBorder),
                      onSelected: (val) {
                        if (val) {
                          FeedbackService.tap();
                          setState(() {
                            _selectedMethodId = m['id'] as int;
                            _selectedMethodName = m['name'] as String;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Dual Pane: Left (Amount Tendered + Quick Chips) & Right (Touch Numpad)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Inputs & Quick Chips
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount Tendered',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: textDark),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _tenderController,
                        focusNode: _focusNode,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: textDark),
                        decoration: InputDecoration(
                          prefixText: '₱ ',
                          prefixStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: primaryBlue),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

                      // Quick Cash Denomination Buttons
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          _buildQuickTenderChip('Exact', () => _setTenderAmount(widget.totalDue), isPrimary: true),
                          if (_nextHundredAmount > widget.totalDue)
                            _buildQuickTenderChip('₱${_nextHundredAmount.toStringAsFixed(0)}', () => _setTenderAmount(_nextHundredAmount)),
                          _buildQuickTenderChip('₱100', () => _setTenderAmount(100)),
                          _buildQuickTenderChip('₱200', () => _setTenderAmount(200)),
                          _buildQuickTenderChip('₱500', () => _setTenderAmount(500)),
                          _buildQuickTenderChip('₱1,000', () => _setTenderAmount(1000)),
                          _buildQuickTenderChip('₱2,000', () => _setTenderAmount(2000)),
                          _buildQuickTenderChip('+₱50', () => _addToTender(50)),
                          _buildQuickTenderChip('+₱100', () => _addToTender(100)),
                          _buildQuickTenderChip('+₱500', () => _addToTender(500)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right Column: On-Screen Touch Numpad
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: surfaceBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNumpadRow(['1', '2', '3']),
                        const SizedBox(height: 4),
                        _buildNumpadRow(['4', '5', '6']),
                        const SizedBox(height: 4),
                        _buildNumpadRow(['7', '8', '9']),
                        const SizedBox(height: 4),
                        _buildNumpadRow(['.', '0', '⌫']),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _onNumpadPress('C'),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              'Clear',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Change Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        size: 18,
                        color: tendered >= widget.totalDue ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tendered >= widget.totalDue ? 'Change Due:' : 'Insufficient Tender:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: tendered >= widget.totalDue ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₱${change.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: tendered >= widget.totalDue ? const Color(0xFF059669) : const Color(0xFFDC2626),
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

  Widget _buildQuickTenderChip(String label, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
            fontSize: 11.5,
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
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: InkWell(
              onTap: () => _onNumpadPress(k),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 32,
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
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
