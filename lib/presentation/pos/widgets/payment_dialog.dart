import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/injection_container.dart';
import 'package:suki_pos/presentation/widgets/custom_form_dialog.dart';

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
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    final db = await sl<DatabaseHelper>().database;
    final results = await db.query(
      SchemaConstants.paymentMethod,
      where: 'is_active = 1',
      orderBy: 'id ASC',
    );
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
    setState(() {
      _tenderController.text = amt.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(content: Center(child: CircularProgressIndicator()));
    }

    final tendered = double.tryParse(_tenderController.text) ?? 0.0;
    final change = tendered >= widget.totalDue ? tendered - widget.totalDue : 0.0;
    final isValid = tendered >= widget.totalDue && _selectedMethodId != null;

    return CustomFormDialog(
      title: 'Tender Payment & Settle Bill',
      maxWidth: 480,
      saveLabel: 'Complete Sale (₱${widget.totalDue.toStringAsFixed(2)})',
      onSave: isValid
          ? () {
              widget.onComplete(_selectedMethodId!, _selectedMethodName, tendered, change);
              Navigator.of(context).pop();
            }
          : () {},
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Due Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL AMOUNT DUE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue)),
                    const SizedBox(height: 2),
                    Text('Net payable balance', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
                Text(
                  '₱${widget.totalDue.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Payment Method Selector
          Text(
            'Payment Method',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _methods.map((m) {
                final isSelected = m['id'] == _selectedMethodId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
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
          const SizedBox(height: 18),

          // Amount Tendered Field
          Text(
            'Amount Tendered',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tenderController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: '₱ ',
              prefixStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(height: 10),

          // Quick Cash Suggestions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickTenderChip('Exact (₱${widget.totalDue.toStringAsFixed(2)})', () => _setTenderAmount(widget.totalDue)),
                const SizedBox(width: 6),
                _buildQuickTenderChip('₱100', () => _setTenderAmount(100)),
                const SizedBox(width: 6),
                _buildQuickTenderChip('₱500', () => _setTenderAmount(500)),
                const SizedBox(width: 6),
                _buildQuickTenderChip('₱1,000', () => _setTenderAmount(1000)),
                const SizedBox(width: 6),
                _buildQuickTenderChip('₱2,000', () => _setTenderAmount(2000)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Change Due Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: tendered >= widget.totalDue ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: tendered >= widget.totalDue ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tendered >= widget.totalDue ? 'Change Due:' : 'Insufficient Tender:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tendered >= widget.totalDue ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                  ),
                ),
                Text(
                  '₱${change.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tendered >= widget.totalDue ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTenderChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: primaryBlue),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: surfaceBorder),
      onPressed: onTap,
    );
  }
}
