import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/domain/entities/maintenance/order_type.dart';
import 'package:suki_pos/domain/entities/maintenance/service_charge_config.dart';
import 'package:suki_pos/presentation/maintenance/order_type/bloc/order_type_cubit.dart';
import 'package:suki_pos/presentation/maintenance/order_type/bloc/order_type_state.dart';
import 'package:suki_pos/presentation/maintenance/order_type/widgets/order_type_form_dialog.dart';
import 'package:suki_pos/presentation/maintenance/service_charge/bloc/service_charge_cubit.dart';
import 'package:suki_pos/presentation/maintenance/service_charge/bloc/service_charge_state.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/app_unified_header.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';
import 'package:suki_pos/presentation/widgets/skeleton_loader.dart';

class ServiceChargePage extends StatefulWidget {
  const ServiceChargePage({super.key});

  @override
  State<ServiceChargePage> createState() => _ServiceChargePageState();
}

class _ServiceChargePageState extends State<ServiceChargePage> with SingleTickerProviderStateMixin {
  final _rateController = TextEditingController();
  bool _isActive = true;
  bool _computeBeforeDiscount = true;
  bool _hasInitialized = false;
  TabController? _mobileTabController;

  final List<double> _quickPresets = [5, 8, 10, 12, 15];

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 2, vsync: this);
    context.read<ServiceChargeCubit>().loadServiceChargeConfig();
    context.read<OrderTypeCubit>().loadOrderTypes();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _mobileTabController?.dispose();
    super.dispose();
  }

  void _syncFromState(ServiceChargeConfig config) {
    if (!_hasInitialized) {
      _isActive = config.isActive;
      _computeBeforeDiscount = config.computeBeforeDiscount;
      _rateController.text = config.ratePercent.toStringAsFixed(0);
      _hasInitialized = true;
    }
  }

  Future<void> _saveMasterSettings() async {
    final rate = double.tryParse(_rateController.text.trim());
    if (rate == null || rate < 0 || rate > 100) {
      AppToast.showWarning(context, message: 'Please enter a valid rate between 0% and 100%');
      return;
    }

    final newConfig = ServiceChargeConfig(
      ratePercent: rate,
      isActive: _isActive,
      computeBeforeDiscount: _computeBeforeDiscount,
    );

    final success = await context.read<ServiceChargeCubit>().saveConfig(newConfig);
    if (!mounted) return;

    if (success) {
      FeedbackService.tap();
      AppToast.showSuccess(
        context,
        message: 'Global service charge settings saved successfully',
        title: 'Settings Updated',
      );
    }
  }

  void _openOrderTypeDialog({OrderType? orderType}) {
    OrderTypeFormDialog.show(
      context,
      orderType: orderType,
      onSave: (ot) {
        context.read<OrderTypeCubit>().save(ot);
        context.read<ServiceChargeCubit>().loadServiceChargeConfig();
      },
    );
  }

  void _confirmDeleteOrderType(OrderType ot) {
    showDialog(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: 'Delete Order Type',
        message: 'Are you sure you want to delete "${ot.name}"? This action cannot be undone.',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        onConfirm: () {
          context.read<OrderTypeCubit>().delete(ot.id);
          AppToast.showSuccess(context, message: 'Order type "${ot.name}" deleted');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MainLayout(
      currentTab: MainTab.inventory,
      mobileAppBar: const AppUnifiedHeader(
        title: 'Service & Order Types',
        subtitle: 'Rates, Computation & Modes',
        parentHubTitle: 'Maintenance',
        parentHubRoute: '/maintenance',
      ),
      desktopHeader: AppUnifiedHeader(
        title: 'Service Charge & Order Types Management',
        subtitle:
            'Side-by-side management of automatic service charges and dining mode operational rules (KwikPOS Suite)',
        parentHubTitle: 'Maintenance Hub',
        parentHubRoute: '/maintenance',
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('New Order Type', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _openOrderTypeDialog(),
          ),
        ],
      ),
      mobileBody: _buildMobileLayout(context, theme),
      desktopBody: _buildDesktopLayout(context, theme),
    );
  }

  // ---------------------------------------------------------------------
  // DESKTOP DUAL-PANE SIDE-BY-SIDE WORKSPACE
  // ---------------------------------------------------------------------

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    return BlocConsumer<ServiceChargeCubit, ServiceChargeState>(
      listener: (context, state) {
        if (state is ServiceChargeLoaded) {
          _syncFromState(state.config);
        }
      },
      builder: (context, state) {
        if (state is ServiceChargeLoading && !_hasInitialized) {
          return const Padding(padding: EdgeInsets.all(32), child: SkeletonTable(rows: 6));
        }

        if (state is ServiceChargeLoaded) {
          _syncFromState(state.config);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;

            if (!isWide) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildServiceChargePane(theme.colorScheme, isMobile: false),
                    const SizedBox(height: 24),
                    _buildOrderTypesPane(context, theme.colorScheme, isMobile: false),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: SERVICE CHARGE CALCULATION ENGINE (46% width)
                  Expanded(
                    flex: 46,
                    child: SingleChildScrollView(
                      child: _buildServiceChargePane(theme.colorScheme, isMobile: false),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // RIGHT COLUMN: ORDER TYPES & DINING MODES MANAGER (54% width)
                  Expanded(
                    flex: 54,
                    child: SingleChildScrollView(
                      child: _buildOrderTypesPane(context, theme.colorScheme, isMobile: false),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // MOBILE TABBED LAYOUT
  // ---------------------------------------------------------------------

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return BlocConsumer<ServiceChargeCubit, ServiceChargeState>(
      listener: (context, state) {
        if (state is ServiceChargeLoaded) {
          _syncFromState(state.config);
        }
      },
      builder: (context, state) {
        if (state is ServiceChargeLoading && !_hasInitialized) {
          return const Padding(padding: EdgeInsets.all(16), child: SkeletonTable(rows: 6));
        }

        if (state is ServiceChargeLoaded) {
          _syncFromState(state.config);
        }

        return Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _mobileTabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: colorScheme.primary,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.room_service_rounded, size: 18), text: 'Service Charge'),
                  Tab(icon: Icon(Icons.table_restaurant_rounded, size: 18), text: 'Order Types'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _mobileTabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildServiceChargePane(colorScheme, isMobile: true),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildOrderTypesPane(context, colorScheme, isMobile: true),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // LEFT PANE: SERVICE CHARGE MASTER ENGINE & RULES
  // ---------------------------------------------------------------------

  Widget _buildServiceChargePane(ColorScheme colorScheme, {required bool isMobile}) {
    final currentRate = double.tryParse(_rateController.text.trim()) ?? 10.0;
    const sampleGross = 1000.0;
    const sampleDiscount = 200.0; // 20% discount

    final sampleBeforeCharge = sampleGross * (currentRate / 100);
    final sampleAfterCharge = (sampleGross - sampleDiscount) * (currentRate / 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. MASTER SETTINGS CARD
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.room_service_rounded, color: colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Global Service Charge',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Master rate applied to eligible order types',
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: _isActive,
                    activeColor: colorScheme.primary,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              Text(
                'DEFAULT RATE PERCENTAGE (%)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        suffixText: '%',
                        suffixStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _quickPresets.map((p) {
                        final isSelected = _rateController.text == p.toStringAsFixed(0);
                        return ActionChip(
                          label: Text('${p.toStringAsFixed(0)}%'),
                          backgroundColor: isSelected ? colorScheme.primary : const Color(0xFFF1F5F9),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          ),
                          side: BorderSide(color: isSelected ? colorScheme.primary : const Color(0xFFCBD5E1)),
                          onPressed: () => setState(() => _rateController.text = p.toStringAsFixed(0)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. COMPUTATION BASIS CARD (BEFORE VS AFTER DISCOUNT)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.calculate_outlined, color: Colors.purple.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discount Interaction Rule',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Compute before or after statutory/promo discounts',
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Option A: Before Discount
              InkWell(
                onTap: () => setState(() => _computeBeforeDiscount = true),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _computeBeforeDiscount ? colorScheme.primary.withOpacity(0.06) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _computeBeforeDiscount ? colorScheme.primary : const Color(0xFFCBD5E1),
                      width: _computeBeforeDiscount ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _computeBeforeDiscount ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _computeBeforeDiscount ? colorScheme.primary : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compute BEFORE Discount (Gross Subtotal)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Calculated on Gross Subtotal. Senior/PWD and store discounts do not reduce service charge.',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option B: After Discount
              InkWell(
                onTap: () => setState(() => _computeBeforeDiscount = false),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: !_computeBeforeDiscount ? colorScheme.primary.withOpacity(0.06) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !_computeBeforeDiscount ? colorScheme.primary : const Color(0xFFCBD5E1),
                      width: !_computeBeforeDiscount ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        !_computeBeforeDiscount ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: !_computeBeforeDiscount ? colorScheme.primary : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compute AFTER Discount (Net Subtotal)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Calculated on Net Subtotal after subtracting all statutory and promo discounts.',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Dynamic Live Simulation Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF0369A1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _computeBeforeDiscount
                            ? 'Live Rule Preview: On ₱1,000 gross with ₱200 discount, Service Charge (${currentRate.toStringAsFixed(0)}%) = +₱${sampleBeforeCharge.toStringAsFixed(2)} (Net Due: ₱${(sampleGross - sampleDiscount + sampleBeforeCharge).toStringAsFixed(2)})'
                            : 'Live Rule Preview: On ₱1,000 gross with ₱200 discount (₱800 net), Service Charge (${currentRate.toStringAsFixed(0)}%) = +₱${sampleAfterCharge.toStringAsFixed(2)} (Net Due: ₱${(sampleGross - sampleDiscount + sampleAfterCharge).toStringAsFixed(2)})',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save Button for Left Pane
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: Text('Save Engine Rules', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _saveMasterSettings,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // RIGHT PANE: ORDER TYPES & DINING MODES MANAGER (KWIKPOS SUITE)
  // ---------------------------------------------------------------------

  Widget _buildOrderTypesPane(BuildContext context, ColorScheme colorScheme, {required bool isMobile}) {
    return BlocBuilder<OrderTypeCubit, OrderTypeState>(
      builder: (context, state) {
        final orderTypes = state is OrderTypeLoaded ? state.orderTypes : <OrderType>[];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.table_restaurant_outlined, color: Colors.blue.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Types & Dining Modes',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${orderTypes.length} operational modes configured',
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isMobile)
                    IconButton.filled(
                      icon: const Icon(Icons.add, size: 18),
                      style: IconButton.styleFrom(backgroundColor: colorScheme.primary),
                      onPressed: () => _openOrderTypeDialog(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              if (orderTypes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.layers_clear_outlined, size: 36, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 8),
                        Text(
                          'No order types found. Tap + to add.',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orderTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final ot = orderTypes[idx];
                    return _buildOrderTypeCard(context, ot, colorScheme);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderTypeCard(BuildContext context, OrderType ot, ColorScheme colorScheme) {
    IconData iconData = Icons.restaurant_rounded;
    final nameLower = ot.name.toLowerCase();
    if (nameLower.contains('take')) {
      iconData = Icons.shopping_bag_outlined;
    } else if (nameLower.contains('delivery')) {
      iconData = Icons.delivery_dining_rounded;
    } else if (nameLower.contains('drive')) {
      iconData = Icons.directions_car_filled_rounded;
    } else if (nameLower.contains('bar')) {
      iconData = Icons.local_bar_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Icon(iconData, size: 18, color: const Color(0xFF334155)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ot.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      ot.hasServiceCharge ? 'Auto-incurs global service charge' : 'Service charge waived',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: ot.hasServiceCharge ? FontWeight.w600 : FontWeight.normal,
                        color: ot.hasServiceCharge ? const Color(0xFF059669) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Live Service Charge Switch
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: ot.hasServiceCharge,
                  activeColor: colorScheme.primary,
                  onChanged: (val) {
                    FeedbackService.tap();
                    final updated = ot.copyWith(hasServiceCharge: val);
                    context.read<OrderTypeCubit>().save(updated);
                  },
                ),
              ),
              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
                visualDensity: VisualDensity.compact,
                onPressed: () => _openOrderTypeDialog(orderType: ot),
              ),
              // Delete Button (if not default ID 1)
              if (ot.id > 3)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDeleteOrderType(ot),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Feature Badges
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildFeatureBadge(
                label: 'Service Charge',
                isActive: ot.hasServiceCharge,
                activeColor: const Color(0xFF059669),
                activeBg: const Color(0xFFECFDF5),
              ),
              if (ot.additionalPercentage > 0)
                _buildFeatureBadge(
                  label: '+${ot.additionalPercentage.toStringAsFixed(1)}% Surcharge',
                  isActive: true,
                  activeColor: const Color(0xFFD97706),
                  activeBg: const Color(0xFFFEF3C7),
                ),
              if (ot.askGuestCount)
                _buildFeatureBadge(
                  label: 'Pax Prompt',
                  isActive: true,
                  activeColor: const Color(0xFF2563EB),
                  activeBg: const Color(0xFFEFF6FF),
                ),
              if (ot.askRefNo)
                _buildFeatureBadge(
                  label: 'Pager/Ref',
                  isActive: true,
                  activeColor: const Color(0xFF7C3AED),
                  activeBg: const Color(0xFFF5F3FF),
                ),
              if (ot.isDelivery)
                _buildFeatureBadge(
                  label: 'Delivery Mode',
                  isActive: true,
                  activeColor: const Color(0xFF0D9488),
                  activeBg: const Color(0xFFF0FDFA),
                ),
              if (ot.printAdditionalCopy)
                _buildFeatureBadge(
                  label: '2x Receipts',
                  isActive: true,
                  activeColor: const Color(0xFF475569),
                  activeBg: const Color(0xFFF1F5F9),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge({
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color activeBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? activeBg : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? activeColor.withOpacity(0.3) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isActive ? activeColor : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
