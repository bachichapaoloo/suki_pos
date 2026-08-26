import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart' as domain;
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_bloc.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_state.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_state.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/services/cart_calculator.dart';

class DiscountSelectionDialog extends StatefulWidget {
  final domain.Discount? currentDiscount;
  final double currentPercentage;
  final double currentFixed;
  final String? currentBeneficiaryName;
  final String? currentBeneficiaryId;
  final int guestCount;
  final int eligibleGuestCount;
  final Function(
    domain.Discount discount, {
    String? idNumber,
    String? cardholderName,
    int? guestCount,
    int? eligibleCount,
  }) onApplyDiscount;
  final Function(double percent) onApplyPercentage;
  final Function(double amount) onApplyFixed;
  final VoidCallback onRemoveDiscount;

  const DiscountSelectionDialog({
    super.key,
    required this.onApplyDiscount,
    required this.currentDiscount,
    required this.currentPercentage,
    required this.currentFixed,
    this.currentBeneficiaryName,
    this.currentBeneficiaryId,
    this.guestCount = 1,
    this.eligibleGuestCount = 0,
    required this.onApplyPercentage,
    required this.onApplyFixed,
    required this.onRemoveDiscount,
  });

  @override
  State<DiscountSelectionDialog> createState() => _DiscountSelectionDialogState();
}

class _DiscountSelectionDialogState extends State<DiscountSelectionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _customAmountController = TextEditingController();
  final _beneficiaryNameController = TextEditingController();
  final _beneficiaryIdController = TextEditingController();

  DiscountType _customType = DiscountType.percentage;
  late int _guestCount;
  late int _eligibleCount;
  domain.Discount? _selectedStatutoryDiscount;

  final List<double> _quickPercentages = [5, 10, 15, 20, 25, 50];

  @override
  void initState() {
    super.initState();
    _guestCount = widget.guestCount > 0 ? widget.guestCount : 1;
    _eligibleCount = widget.eligibleGuestCount > 0 ? widget.eligibleGuestCount : 1;

    _beneficiaryNameController.text = widget.currentBeneficiaryName ?? '';
    _beneficiaryIdController.text = widget.currentBeneficiaryId ?? '';

    if (widget.currentFixed > 0) {
      _customType = DiscountType.fixed;
      _customAmountController.text = widget.currentFixed.toStringAsFixed(2);
    } else if (widget.currentPercentage > 0) {
      _customType = DiscountType.percentage;
      _customAmountController.text = widget.currentPercentage.toStringAsFixed(0);
    }

    final isStatutory = widget.currentDiscount?.isSpecialVatExempt ?? false;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: isStatutory ? 0 : (widget.currentDiscount != null ? 1 : 2),
    );

    if (isStatutory) {
      _selectedStatutoryDiscount = widget.currentDiscount;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customAmountController.dispose();
    _beneficiaryNameController.dispose();
    _beneficiaryIdController.dispose();
    super.dispose();
  }

  void _applyStatutory(domain.Discount discount) {
    final idNo = _beneficiaryIdController.text.trim();
    final name = _beneficiaryNameController.text.trim();

    if (idNo.isEmpty) {
      AppToast.showWarning(
        context,
        message: 'Please enter the ${discount.name} ID Number (OSCA / PWD ID / TIN)',
        title: 'ID Number Required',
      );
      return;
    }

    if (name.isEmpty) {
      AppToast.showWarning(
        context,
        message: 'Please enter the Cardholder / Beneficiary Name',
        title: 'Cardholder Name Required',
      );
      return;
    }

    if (_eligibleCount > _guestCount) {
      AppToast.showWarning(
        context,
        message: 'Eligible Senior/PWD count cannot exceed total guest count',
        title: 'Invalid Head Count',
      );
      return;
    }

    widget.onApplyDiscount(
      discount,
      idNumber: idNo,
      cardholderName: name,
      guestCount: _guestCount,
      eligibleCount: _eligibleCount,
    );

    AppToast.showSuccess(
      context,
      message: '${discount.name} applied for $name ($idNo)',
      title: 'Statutory Discount Applied',
    );
    Navigator.of(context).pop();
  }

  void _applyStoreDiscount(domain.Discount discount) {
    widget.onApplyDiscount(discount);
    AppToast.showSuccess(
      context,
      message: '${discount.name} applied to order',
      title: 'Store Discount Applied',
    );
    Navigator.of(context).pop();
  }

  void _submitCustom() {
    final text = _customAmountController.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final val = double.tryParse(text);
    if (val == null || val <= 0) {
      AppToast.showWarning(context, message: 'Please enter a valid positive discount amount');
      return;
    }

    if (_customType == DiscountType.percentage) {
      if (val > 100) {
        AppToast.showWarning(context, message: 'Percentage discount cannot exceed 100%');
        return;
      }
      widget.onApplyPercentage(val);
      AppToast.showSuccess(context, message: '${val.toStringAsFixed(0)}% custom discount applied');
    } else {
      widget.onApplyFixed(val);
      AppToast.showSuccess(context, message: '₱${val.toStringAsFixed(2)} custom discount applied');
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cartState = context.read<CartCubit>().state;
    final hasActiveDiscount = widget.currentDiscount != null || widget.currentPercentage > 0 || widget.currentFixed > 0;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: screenHeight * 0.9,
        ),
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
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.loyalty_rounded, color: colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apply Order Discount',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Philippine Statutory Discounts (RA 9994/10754) & Store Promos',
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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(icon: Icon(Icons.verified_user_outlined, size: 16), text: 'Statutory (SC/PWD)'),
                    Tab(icon: Icon(Icons.storefront_outlined, size: 16), text: 'Store Promos'),
                    Tab(icon: Icon(Icons.tune_rounded, size: 16), text: 'Custom / %'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Flexible Scrollable Tab Views Container (Never overflows height)
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatutoryTab(context, cartState),
                    _buildStorePromosTab(context),
                    _buildCustomOverrideTab(context),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Footer Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasActiveDiscount)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Colors.redAccent),
                      label: Text(
                        'Clear Discount',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.redAccent),
                      ),
                      onPressed: () {
                        widget.onRemoveDiscount();
                        AppToast.showInfo(context, message: 'Discount cleared');
                        Navigator.of(context).pop();
                      },
                    )
                  else
                    const SizedBox.shrink(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: STATUTORY PH DISCOUNTS (RA 9994 / RA 10754)
  // -------------------------------------------------------------

  Widget _buildStatutoryTab(BuildContext context, CartState cartState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<DiscountBloc, DiscountState>(
      builder: (context, state) {
        List<domain.Discount> statutoryList = [];

        if (state is DiscountLoaded) {
          statutoryList = state.discounts.where((d) => d.isActive && d.isSpecialVatExempt).toList();
        }

        // Fallback default statutory discounts if none configured in DB
        if (statutoryList.isEmpty) {
          statutoryList = const [
            domain.Discount(
              id: 1,
              discountTypeId: 2,
              discountTypeCode: 'senior',
              name: 'Senior Citizen (20% VAT-Exempt)',
              percentage: 20.0,
            ),
            domain.Discount(
              id: 2,
              discountTypeId: 3,
              discountTypeCode: 'pwd',
              name: 'PWD (20% VAT-Exempt)',
              percentage: 20.0,
            ),
            domain.Discount(
              id: 3,
              discountTypeId: 7,
              discountTypeCode: 'athlete',
              name: 'National Athlete (20% VAT-Exempt)',
              percentage: 20.0,
            ),
            domain.Discount(
              id: 4,
              discountTypeId: 6,
              discountTypeCode: 'solo_parent',
              name: 'Solo Parent (VAT-Exempt)',
              percentage: 20.0,
            ),
          ];
        }

        final currentSelected = _selectedStatutoryDiscount ?? statutoryList.first;

        // Compute live breakdown estimate
        final simulatedBreakdown = CartCalculator.calculate(
          items: cartState.items,
          appliedDiscount: currentSelected,
          guestCount: _guestCount,
          eligibleGuestCount: _eligibleCount,
        );

        final lessVat = (simulatedBreakdown.grossSubtotal - simulatedBreakdown.vatableSales - simulatedBreakdown.vatAmount).clamp(0.0, double.infinity);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Law Chips / Rule Selector
              Text(
                'SELECT STATUTORY DISCOUNT TYPE',
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: statutoryList.map((d) {
                  final isSelected = currentSelected.id == d.id || currentSelected.name == d.name;
                  return ChoiceChip(
                    label: Text(d.name),
                    selected: isSelected,
                    selectedColor: colorScheme.primary.withOpacity(0.12),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? colorScheme.primary : const Color(0xFF1E293B),
                    ),
                    side: BorderSide(
                      color: isSelected ? colorScheme.primary : const Color(0xFFCBD5E1),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedStatutoryDiscount = d);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Beneficiary Details Inputs
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _beneficiaryIdController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'ID / OSCA / PWD No. *',
                        hintText: 'e.g. 1234-5678',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _beneficiaryNameController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Cardholder Name *',
                        hintText: 'e.g. Maria Clara',
                        prefixIcon: const Icon(Icons.person_outline, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Multi-Guest / Head Count Steppers & Quick Proportions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dine-In Proportional Sharing',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              ),
                              Text(
                                '$_eligibleCount of $_guestCount guests receive 20% + VAT exempt',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStepper(
                              label: 'SC/PWD',
                              value: _eligibleCount,
                              onChanged: (val) {
                                if (val >= 1 && val <= _guestCount) {
                                  setState(() => _eligibleCount = val);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildStepper(
                              label: 'Total',
                              value: _guestCount,
                              onChanged: (val) {
                                if (val >= 1) {
                                  setState(() {
                                    _guestCount = val;
                                    if (_eligibleCount > _guestCount) {
                                      _eligibleCount = _guestCount;
                                    }
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Quick Preset Chips for Head Count
                    Wrap(
                      spacing: 6,
                      children: [
                        _buildQuickHeadCountChip(1, 1, '100% Solo (1/1)'),
                        _buildQuickHeadCountChip(1, 2, '50% Share (1/2)'),
                        _buildQuickHeadCountChip(1, 4, '25% Share (1/4)'),
                        _buildQuickHeadCountChip(2, 4, '50% Share (2/4)'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Live BIR Calculation Breakdown Card & Apply Button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Less 12% VAT: -₱${lessVat.toStringAsFixed(2)}  •  Less 20% SC: -₱${simulatedBreakdown.manualDiscountAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF065F46),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Net Total Due: ₱${simulatedBreakdown.netTotal.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _applyStatutory(currentSelected),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickHeadCountChip(int eligible, int total, String label) {
    final isSelected = _eligibleCount == eligible && _guestCount == total;
    return InkWell(
      onTap: () {
        setState(() {
          _eligibleCount = eligible;
          _guestCount = total;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper({required String label, required int value, required ValueChanged<int> onChanged}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
        ),
        InkWell(
          onTap: () => onChanged(value - 1),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: const Icon(Icons.remove, size: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('$value', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold)),
        ),
        InkWell(
          onTap: () => onChanged(value + 1),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: const Icon(Icons.add, size: 13),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: STORE / PROMOTIONAL DISCOUNTS
  // -------------------------------------------------------------

  Widget _buildStorePromosTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<DiscountBloc, DiscountState>(
      builder: (context, state) {
        if (state is DiscountLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<domain.Discount> storePromos = [];
        if (state is DiscountLoaded) {
          storePromos = state.discounts.where((d) => d.isActive && !d.isSpecialVatExempt).toList();
        }

        if (storePromos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.discount_outlined, size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No regular promotional discounts configured.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                ),
                Text(
                  'Add promos in Maintenance › Discounts or use the Custom tab.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          itemCount: storePromos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final promo = storePromos[index];
            final isSelected = widget.currentDiscount?.id == promo.id;
            final rateText = promo.isPercentage
                ? '${promo.percentage?.toStringAsFixed(0)}% OFF'
                : '₱${promo.fixedAmount?.toStringAsFixed(2)} OFF';

            return ListTile(
              dense: true,
              tileColor: isSelected ? colorScheme.primary.withOpacity(0.08) : const Color(0xFFF8FAFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isSelected ? colorScheme.primary : const Color(0xFFE2E8F0)),
              ),
              leading: Icon(
                promo.isPercentage ? Icons.percent_rounded : Icons.money_off_rounded,
                color: isSelected ? colorScheme.primary : const Color(0xFF64748B),
                size: 20,
              ),
              title: Text(
                promo.name,
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
              ),
              subtitle: Text(
                rateText,
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              trailing: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isSelected ? colorScheme.primary : const Color(0xFF334155),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () => _applyStoreDiscount(promo),
                child: Text(
                  isSelected ? 'Active' : 'Apply',
                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 3: CUSTOM / MANUAL OVERRIDE
  // -------------------------------------------------------------

  Widget _buildCustomOverrideTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK PERCENTAGE PRESETS',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickPercentages.map((percent) {
              return ActionChip(
                label: Text('${percent.toStringAsFixed(0)}% OFF'),
                backgroundColor: const Color(0xFFF1F5F9),
                labelStyle: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                onPressed: () {
                  widget.onApplyPercentage(percent);
                  AppToast.showSuccess(context, message: '${percent.toStringAsFixed(0)}% discount applied');
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Text(
            'CUSTOM VALUE',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<DiscountType>(
            segments: const [
              ButtonSegment(value: DiscountType.percentage, label: Text('Percentage (%)')),
              ButtonSegment(value: DiscountType.fixed, label: Text('Fixed Amount (₱)')),
            ],
            selected: {_customType},
            onSelectionChanged: (set) => setState(() => _customType = set.first),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: _customType == DiscountType.percentage
                        ? 'Discount Percentage (%)'
                        : 'Discount Amount (₱)',
                    prefixText: _customType == DiscountType.fixed ? '₱ ' : null,
                    suffixText: _customType == DiscountType.percentage ? '%' : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _submitCustom,
                child: Text('Apply', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
