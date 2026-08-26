import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';

class SurchargeDialog extends StatefulWidget {
  final double currentAmount;
  final double currentPercent;
  final double grossSubtotal;
  final Function({required double amount, required double percent}) onApply;
  final VoidCallback onRemove;

  const SurchargeDialog({
    super.key,
    required this.currentAmount,
    required this.currentPercent,
    required this.grossSubtotal,
    required this.onApply,
    required this.onRemove,
  });

  @override
  State<SurchargeDialog> createState() => _SurchargeDialogState();
}

class _SurchargeDialogState extends State<SurchargeDialog> {
  final _amountController = TextEditingController();
  bool _isPercentage = true;
  final List<double> _quickPercents = [5, 8, 10, 12];
  final List<double> _quickFixedAmounts = [20, 50, 100, 150];

  @override
  void initState() {
    super.initState();
    if (widget.currentPercent > 0) {
      _isPercentage = true;
      _amountController.text = widget.currentPercent.toStringAsFixed(0);
    } else if (widget.currentAmount > 0) {
      _isPercentage = false;
      _amountController.text = widget.currentAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _applyQuickPercent(double p) {
    final calcAmt = widget.grossSubtotal * (p / 100);
    widget.onApply(amount: calcAmt, percent: p);
    AppToast.showSuccess(
      context,
      message: '${p.toStringAsFixed(0)}% Service Charge applied (+₱${calcAmt.toStringAsFixed(2)})',
      title: 'Surcharge Applied',
    );
    Navigator.of(context).pop();
  }

  void _applyQuickFixed(double fixed) {
    widget.onApply(amount: fixed, percent: 0.0);
    AppToast.showSuccess(
      context,
      message: '₱${fixed.toStringAsFixed(2)} Surcharge applied',
      title: 'Surcharge Applied',
    );
    Navigator.of(context).pop();
  }

  void _submit() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final val = double.tryParse(text);
    if (val == null || val <= 0) {
      AppToast.showWarning(context, message: 'Please enter a valid surcharge amount');
      return;
    }

    if (_isPercentage) {
      final calcAmt = widget.grossSubtotal * (val / 100);
      widget.onApply(amount: calcAmt, percent: val);
      AppToast.showSuccess(
        context,
        message: '${val.toStringAsFixed(0)}% Surcharge applied (+₱${calcAmt.toStringAsFixed(2)})',
      );
    } else {
      widget.onApply(amount: val, percent: 0.0);
      AppToast.showSuccess(
        context,
        message: '₱${val.toStringAsFixed(2)} Fixed Surcharge applied',
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasActive = widget.currentAmount > 0 || widget.currentPercent > 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.room_service_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Charge / Surcharge',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Dine-in service charge, delivery fee, or holiday surcharge',
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mode selector (Percentage vs Fixed)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Percentage (%)')),
                  ButtonSegment(value: false, label: Text('Fixed Fee (₱)')),
                ],
                selected: {_isPercentage},
                onSelectionChanged: (s) => setState(() => _isPercentage = s.first),
              ),
              const SizedBox(height: 14),

              // Quick Presets
              Text(
                _isPercentage ? 'QUICK SERVICE CHARGE PRESETS' : 'QUICK DELIVERY & PACKAGING FEES',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              if (_isPercentage)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickPercents.map((p) {
                    return ActionChip(
                      label: Text('${p.toStringAsFixed(0)}% Service Charge'),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      onPressed: () => _applyQuickPercent(p),
                    );
                  }).toList(),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickFixedAmounts.map((fixed) {
                    return ActionChip(
                      label: Text('+₱${fixed.toStringAsFixed(0)} Fee'),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      onPressed: () => _applyQuickFixed(fixed),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 14),

              // Custom Input Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _isPercentage ? 'Custom Surcharge Percentage (%)' : 'Custom Surcharge Amount (₱)',
                  prefixText: _isPercentage ? null : '₱ ',
                  suffixText: _isPercentage ? '%' : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),

              // Actions Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasActive)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      label: Text(
                        'Remove Surcharge',
                        style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                      onPressed: () {
                        widget.onRemove();
                        AppToast.showInfo(context, message: 'Surcharge removed');
                        Navigator.of(context).pop();
                      },
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
