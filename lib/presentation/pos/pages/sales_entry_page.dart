import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/core/utils/image_storage_service.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/inventory/stock_cubit.dart';
import 'package:suki_pos/presentation/inventory/stock_state.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_bloc.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_event.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_event.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_state.dart';
import 'package:suki_pos/presentation/maintenance/option_group/bloc/option_group_cubit.dart';
import 'package:suki_pos/presentation/maintenance/order_type/bloc/order_type_cubit.dart';
import 'package:suki_pos/presentation/maintenance/order_type/bloc/order_type_state.dart';
import 'package:suki_pos/presentation/maintenance/service_charge/bloc/service_charge_cubit.dart';
import 'package:suki_pos/presentation/maintenance/service_charge/bloc/service_charge_state.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_state.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_state.dart';
import 'package:suki_pos/presentation/pos/widgets/add_to_cart_modal.dart';
import 'package:suki_pos/presentation/pos/widgets/assign_table_customer_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/cart_line_item_tile.dart';
import 'package:suki_pos/presentation/pos/widgets/change_fund_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/discount_selection_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/held_orders_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/line_item_action_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/order_notes_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/payment_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/receipt_preview_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/surcharge_dialog.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/app_unified_header.dart';
import 'package:suki_pos/presentation/widgets/hotkey_badge.dart';
import 'package:suki_pos/presentation/widgets/skeleton_loader.dart';

/// Responsive breakpoints for the Sales Entry layout.
class _Breakpoints {
  static const double mobile = 760;
  static const double tablet = 1140;
}

class SalesEntryPage extends StatefulWidget {
  const SalesEntryPage({super.key});

  @override
  State<SalesEntryPage> createState() => _SalesEntryPageState();
}

class _SalesEntryPageState extends State<SalesEntryPage> {
  int? _selectedDepartmentId;
  int? _selectedCategoryId;
  int? _selectedOrderTypeId;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ItemBloc>().add(LoadItems());
    context.read<CategoryBloc>().add(GetCategoriesEvent());
    context.read<DepartmentBloc>().add(GetDepartmentsEvent());
    context.read<OptionGroupCubit>().loadOptionGroups();
    context.read<OrderTypeCubit>().loadOrderTypes();
    context.read<DiscountBloc>().add(GetDiscountsEvent());
    context.read<StockCubit>().loadStockList();
    context.read<ServiceChargeCubit>().loadServiceChargeConfig();

    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() => _searchQuery = query);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyShiftStatus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  int _getActiveCashierId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return 1;
  }

  void _verifyShiftStatus() {
    final cashierId = _getActiveCashierId(context);
    context.read<ShiftCubit>().checkActiveShift(cashierId);
  }

  // ---------------------------------------------------------------------
  // BARCODE AUTO-SCAN & ADD TO CART
  // ---------------------------------------------------------------------

  void _handleBarcodeOrSearchSubmit(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final itemState = context.read<ItemBloc>().state;
    if (itemState is ItemLoaded) {
      // Find matching item by exact Barcode or Item Code
      final matchedItem = itemState.items.where((i) {
        final barcodeMatch = i.barcode != null && i.barcode!.toLowerCase() == clean.toLowerCase();
        final codeMatch = i.itemCode.toLowerCase() == clean.toLowerCase();
        return barcodeMatch || codeMatch;
      }).firstOrNull;

      if (matchedItem != null) {
        FeedbackService.tap();
        context.read<CartCubit>().addItem(item: matchedItem, quantity: 1);
        AppToast.showSuccess(
          context,
          message: 'Scanned 1x ${matchedItem.name}',
          title: 'Item Added to Cart',
        );
        _searchController.clear();
      }
    }
  }

  // ---------------------------------------------------------------------
  // DIALOG HANDLERS
  // ---------------------------------------------------------------------

  Future<void> _handleBackNavigation(BuildContext context) async {
    final cart = context.read<CartCubit>().state;

    if (cart.items.isNotEmpty) {
      await ConfirmationDialog.show(
        context,
        title: 'Active Order in Cart',
        message: 'You have active items in your cart. You can Hold Order [F2] or complete checkout before leaving.',
        variant: DialogVariant.warning,
        confirmLabel: 'OK',
        showCancel: false,
        contentAlignment: TextAlign.center,
      );
      return;
    }

    final shouldExit = await ConfirmationDialog.show(
      context,
      title: 'Exit Sales Terminal',
      message: 'Are you sure you want to return to the POS dashboard?',
      confirmLabel: 'Exit',
      confirmColor: Colors.red.shade600,
      variant: DialogVariant.danger,
      contentAlignment: TextAlign.center,
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/pos');
    }
  }

  void _openHoldOrderDialog(BuildContext context) {
    final cart = context.read<CartCubit>().state;
    if (cart.items.isEmpty) {
      AppToast.showWarning(context, message: 'Cart is empty. Add items first to hold order.');
      return;
    }

    final heldId = context.read<CartCubit>().holdCurrentOrder();
    if (heldId != null) {
      AppToast.showSuccess(
        context,
        message: 'Current order parked in queue [F3 to Recall]',
        title: 'Order Held Successfully',
      );
    }
  }

  void _openRecallHeldOrdersDialog(BuildContext context) {
    final cartState = context.read<CartCubit>().state;

    showDialog(
      context: context,
      builder: (_) => HeldOrdersDialog(
        heldOrders: cartState.heldOrders,
        onRecall: (heldId) => context.read<CartCubit>().recallHeldOrder(heldId),
        onDelete: (heldId) => context.read<CartCubit>().deleteHeldOrder(heldId),
      ),
    );
  }

  void _openAssignTableDialog(BuildContext context) {
    final cartState = context.read<CartCubit>().state;

    showDialog(
      context: context,
      builder: (_) => AssignTableCustomerDialog(
        currentTableName: cartState.tableName,
        currentCustomerName: cartState.customerName,
        currentGuestCount: cartState.guestCount,
        onSave: ({customerName, guestCount, tableName}) {
          if (tableName != null) context.read<CartCubit>().setTableName(tableName);
          if (customerName != null) context.read<CartCubit>().setCustomerName(customerName);
          if (guestCount != null) context.read<CartCubit>().setGuestCount(guestCount);
        },
      ),
    );
  }

  void _openOrderNotesDialog(BuildContext context) {
    final cartState = context.read<CartCubit>().state;

    showDialog(
      context: context,
      builder: (_) => OrderNotesDialog(
        currentRemarks: cartState.remarks,
        onSave: (notes) => context.read<CartCubit>().setRemarks(notes),
      ),
    );
  }

  void _openSurchargeDialog(BuildContext context, TaxDiscountBreakdown breakdown) {
    final cartState = context.read<CartCubit>().state;

    showDialog(
      context: context,
      builder: (_) => SurchargeDialog(
        currentAmount: cartState.surchargeAmount,
        currentPercent: cartState.surchargePercent,
        grossSubtotal: breakdown.grossSubtotal,
        onApply: ({required amount, required percent}) {
          context.read<CartCubit>().setSurcharge(amount: amount, percent: percent);
        },
        onRemove: () => context.read<CartCubit>().setSurcharge(amount: 0.0, percent: 0.0),
      ),
    );
  }

  void _openDiscountDialog(BuildContext context) {
    final cartState = context.read<CartCubit>().state;

    showDialog(
      context: context,
      builder: (_) => DiscountSelectionDialog(
        currentDiscount: cartState.appliedDiscount,
        currentPercentage: cartState.manualDiscountPercentage,
        currentFixed: cartState.manualDiscountFixed,
        currentBeneficiaryName: cartState.beneficiaryName,
        currentBeneficiaryId: cartState.beneficiaryIdNo,
        guestCount: cartState.guestCount,
        eligibleGuestCount: cartState.eligibleGuestCount,
        onApplyDiscount: (d, {cardholderName, idNumber, guestCount, eligibleCount}) {
          context.read<CartCubit>().applyDiscount(
            d,
            cardholderName: cardholderName,
            idNumber: idNumber,
            guestCount: guestCount,
            eligibleCount: eligibleCount,
          );
        },
        onApplyPercentage: (p) => context.read<CartCubit>().applyDiscountPercentage(p),
        onApplyFixed: (a) => context.read<CartCubit>().applyDiscountFixed(a),
        onRemoveDiscount: () => context.read<CartCubit>().removeDiscount(),
      ),
    );
  }

  void _openPaymentDialog(BuildContext context, TaxDiscountBreakdown breakdown) {
    final cartCubit = context.read<CartCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PaymentDialog(
        totalDue: breakdown.netTotal,
        onComplete: (paymentMethodId, methodName, cashTendered, change) async {
          final cashierId = _getActiveCashierId(context);

          final completedTxn = await cartCubit.submitOrder(
            cashierId: cashierId,
            paymentMethodId: paymentMethodId,
            cashTendered: cashTendered,
          );

          if (!mounted) return;

          if (completedTxn != null) {
            // Realtime Stock sync
            context.read<StockCubit>().loadStockList();

            AppToast.showSuccess(
              context,
              message: 'Sale Completed! Transaction #${completedTxn.transactionNo}',
              title: 'Order Completed',
            );

            showDialog(
              context: context,
              builder: (_) => ReceiptPreviewDialog(transaction: completedTxn),
            );
          } else {
            final errorMsg = cartCubit.state.errorMessage ?? 'Checkout failed. Please try again.';
            AppToast.showError(context, message: errorMsg, title: 'Checkout Failed');
          }
        },
      ),
    );
  }

  void _openMobileCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildCartPanel(context, Theme.of(context), scrollController: scrollController),
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
  // BUILD PAGE
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < _Breakpoints.mobile;
    final isTablet = screenWidth >= _Breakpoints.mobile && screenWidth < _Breakpoints.tablet;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f1): () {
          FeedbackService.tap();
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.f2): () {
          FeedbackService.tap();
          _openHoldOrderDialog(context);
        },
        const SingleActivator(LogicalKeyboardKey.f3): () {
          FeedbackService.tap();
          _openRecallHeldOrdersDialog(context);
        },
        const SingleActivator(LogicalKeyboardKey.f4): () {
          FeedbackService.tap();
          _openAssignTableDialog(context);
        },
        const SingleActivator(LogicalKeyboardKey.f8): () {
          FeedbackService.tap();
          _openDiscountDialog(context);
        },
        const SingleActivator(LogicalKeyboardKey.f9): () {
          FeedbackService.tap();
          final breakdown = context.read<CartCubit>().state.breakdown;
          _openSurchargeDialog(context, breakdown);
        },
        const SingleActivator(LogicalKeyboardKey.f10): () {
          FeedbackService.tap();
          _openOrderNotesDialog(context);
        },
        const SingleActivator(LogicalKeyboardKey.f12): () {
          final cartState = context.read<CartCubit>().state;
          if (cartState.items.isNotEmpty) {
            FeedbackService.tap();
            _openPaymentDialog(context, cartState.breakdown);
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _handleBackNavigation(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: MultiBlocListener(
          listeners: [
            BlocListener<ShiftCubit, ShiftState>(
              listener: (context, state) {
                if (state is ShiftInactive || state is ShiftClosed) {
                  ChangeFundDialog.show(context, cashierId: _getActiveCashierId(context));
                }
              },
            ),
            BlocListener<ServiceChargeCubit, ServiceChargeState>(
              listener: (context, state) {
                if (state is ServiceChargeLoaded) {
                  context.read<CartCubit>().setServiceChargeConfig(
                    ratePercent: state.config.ratePercent,
                    isActive: state.config.isActive,
                    computeBeforeDiscount: state.config.computeBeforeDiscount,
                  );
                }
              },
            ),
            BlocListener<OrderTypeCubit, OrderTypeState>(
              listener: (context, state) {
                if (state is OrderTypeLoaded && state.orderTypes.isNotEmpty) {
                  final activeId = _selectedOrderTypeId ?? 1;
                  final matching =
                      state.orderTypes.where((o) => o.id == activeId).firstOrNull ?? state.orderTypes.first;

                  if (_selectedOrderTypeId != matching.id) {
                    setState(() => _selectedOrderTypeId = matching.id);
                  }

                  final scState = context.read<ServiceChargeCubit>().state;
                  final isGloballyActive = scState is ServiceChargeLoaded ? scState.config.isActive : true;
                  final hasSc = isGloballyActive && matching.hasServiceCharge;
                  final effectiveRate = matching.additionalPercentage > 0
                      ? matching.additionalPercentage
                      : (scState is ServiceChargeLoaded ? scState.config.ratePercent : 10.0);

                  context.read<CartCubit>().setServiceChargeConfig(
                    ratePercent: effectiveRate,
                    isActive: hasSc,
                    computeBeforeDiscount: scState is ServiceChargeLoaded ? scState.config.computeBeforeDiscount : true,
                  );
                }
              },
            ),
          ],
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppUnifiedHeader(
              title: 'Sales Terminal',
              subtitle: 'Catalog & Fast Cashiering',
              parentHubTitle: 'POS Hub',
              parentHubRoute: '/pos',
              onBackPressed: () => _handleBackNavigation(context),
              badge: BlocBuilder<ShiftCubit, ShiftState>(
                builder: (context, shiftState) {
                  final isActive = shiftState is ShiftActive;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'ACTIVE SHIFT' : 'NO ACTIVE SHIFT',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                // Held Orders Counter Button
                BlocBuilder<CartCubit, CartState>(
                  builder: (context, cartState) {
                    final heldCount = cartState.heldOrders.length;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(color: heldCount > 0 ? Colors.amber.shade700 : const Color(0xFFCBD5E1)),
                            backgroundColor: heldCount > 0 ? Colors.amber.shade50 : Colors.transparent,
                          ),
                          icon: Icon(
                            Icons.pause_circle_outline_rounded,
                            size: 16,
                            color: heldCount > 0 ? Colors.amber.shade900 : const Color(0xFF64748B),
                          ),
                          label: Text(
                            isMobile ? 'Held' : 'Held Orders',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: heldCount > 0 ? Colors.amber.shade900 : const Color(0xFF475569),
                            ),
                          ),
                          onPressed: () => _openRecallHeldOrdersDialog(context),
                        ),
                        if (heldCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle),
                              child: Text(
                                '$heldCount',
                                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: isMobile ? _buildMobileLayout(theme) : _buildWideLayout(theme, isTablet: isTablet),
                ),
                // Hotkey Helper Bar (Hidden on Mobile)
                if (!isMobile) _buildHotkeyFooterBar(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LAYOUTS
  // ---------------------------------------------------------------------

  Widget _buildMobileLayout(ThemeData theme) {
    return Column(
      children: [
        _buildControlsBar(theme, isMobile: true),
        _buildCategoryPillsBar(theme),
        const Divider(height: 1),
        Expanded(child: _buildItemGrid(theme, crossAxisExtent: 170)),
        _buildMobileCartSummaryBar(theme),
      ],
    );
  }

  Widget _buildWideLayout(ThemeData theme, {required bool isTablet}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT PANEL: Product Catalog, Category Navigation & Filters
        Expanded(
          flex: isTablet ? 5 : 3,
          child: Column(
            children: [
              _buildControlsBar(theme, isMobile: false),
              _buildCategoryPillsBar(theme),
              const Divider(height: 1),
              Expanded(child: _buildItemGrid(theme, crossAxisExtent: isTablet ? 170 : 210)),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // RIGHT PANEL: Cart & Order Summary
        Expanded(
          flex: isTablet ? 4 : 2,
          child: _buildCartPanel(context, theme),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // CONTROLS: SEARCH & ORDER TYPE
  // ---------------------------------------------------------------------

  Widget _buildControlsBar(ThemeData theme, {required bool isMobile}) {
    final searchField = TextFormField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onFieldSubmitted: _handleBarcodeOrSearchSubmit,
      decoration: InputDecoration(
        hintText: 'Search product or scan barcode (F1)...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => _searchController.clear(),
              ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: HotkeyBadge(label: 'F1'),
            ),
          ],
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );

    final orderTypeDropdown = BlocBuilder<OrderTypeCubit, OrderTypeState>(
      builder: (context, state) {
        if (state is OrderTypeLoading) {
          return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
        }
        if (state is OrderTypeLoaded && state.orderTypes.isNotEmpty) {
          return Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedOrderTypeId ?? 1,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                dropdownColor: Colors.white,
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedOrderTypeId = value);
                    context.read<CartCubit>().setOrderType(value);

                    // Sync order type service charge & surcharge rules
                    final ot = state.orderTypes.where((o) => o.id == value).firstOrNull;
                    final scState = context.read<ServiceChargeCubit>().state;
                    final isGloballyActive = scState is ServiceChargeLoaded ? scState.config.isActive : true;
                    final hasSc = isGloballyActive && (ot == null || ot.hasServiceCharge);
                    final effectiveRate = (ot != null && ot.additionalPercentage > 0)
                        ? ot.additionalPercentage
                        : (scState is ServiceChargeLoaded ? scState.config.ratePercent : 10.0);

                    context.read<CartCubit>().setServiceChargeConfig(
                      ratePercent: effectiveRate,
                      isActive: hasSc,
                      computeBeforeDiscount: scState is ServiceChargeLoaded
                          ? scState.config.computeBeforeDiscount
                          : true,
                    );

                    // Trigger Guest Count or Pager/Ref Dialog if configured on Order Type
                    // if (ot != null && (ot.askGuestCount || ot.askRefNo)) {
                    //   WidgetsBinding.instance.addPostFrameCallback((_) {
                    //     _openTableCustomerDialog(context);
                    //   });
                    // }
                  }
                },
                items: ([...state.orderTypes]..sort((a, b) => a.id.compareTo(b.id))).map((ot) {
                  return DropdownMenuItem<int>(
                    value: ot.id,
                    child: Text(ot.name.toUpperCase()),
                  );
                }).toList(),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: isMobile
          ? Column(
              children: [
                searchField,
                const SizedBox(height: 8),
                orderTypeDropdown,
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: searchField),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: orderTypeDropdown),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------
  // CATEGORY NAVIGATION PILLS
  // ---------------------------------------------------------------------

  Widget _buildCategoryPillsBar(ThemeData theme) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        final categories = catState is CategoryLoaded ? catState.categories : <Category>[];

        return BlocBuilder<ItemBloc, ItemState>(
          builder: (context, itemState) {
            final allItems = itemState is ItemLoaded ? itemState.items : <Item>[];

            return Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "All Items" Chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('All Items (${allItems.length})'),
                      selected: _selectedCategoryId == null,
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.w500,
                        color: _selectedCategoryId == null ? Colors.white : const Color(0xFF475569),
                      ),
                      side: BorderSide(
                        color: _selectedCategoryId == null ? theme.colorScheme.primary : const Color(0xFFCBD5E1),
                      ),
                      onSelected: (val) {
                        FeedbackService.tap();
                        setState(() => _selectedCategoryId = null);
                      },
                    ),
                  ),

                  // Individual Category Chips
                  ...categories.map((cat) {
                    final isSelected = _selectedCategoryId == cat.id;
                    final catItemCount = allItems.where((i) => i.categoryId == cat.id).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${cat.name} ($catItemCount)'),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                        side: BorderSide(
                          color: isSelected ? theme.colorScheme.primary : const Color(0xFFCBD5E1),
                        ),
                        onSelected: (val) {
                          FeedbackService.tap();
                          setState(() => _selectedCategoryId = val ? cat.id : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // ITEM GRID & FILTER LOGIC
  // ---------------------------------------------------------------------

  List<Item> _filteredItems(List<Item> items, List<Category> allCategories) {
    return items.where((item) {
      if (_selectedDepartmentId != null) {
        final cat = allCategories.where((c) => c.id == item.categoryId).firstOrNull;
        if (cat == null || cat.departmentId != _selectedDepartmentId) return false;
      }
      if (_selectedCategoryId != null && item.categoryId != _selectedCategoryId) return false;

      if (_searchQuery.isNotEmpty) {
        final nameMatch = item.name.toLowerCase().contains(_searchQuery);
        final codeMatch = item.itemCode.toLowerCase().contains(_searchQuery);
        final barcodeMatch = item.barcode != null && item.barcode!.toLowerCase().contains(_searchQuery);
        if (!nameMatch && !codeMatch && !barcodeMatch) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildItemGrid(ThemeData theme, {required double crossAxisExtent}) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        final allCategories = categoryState is CategoryLoaded ? categoryState.categories : <Category>[];

        return BlocBuilder<ItemBloc, ItemState>(
          builder: (context, itemState) {
            if (itemState is ItemLoading) return const SkeletonGrid(itemCount: 8);
            if (itemState is ItemLoaded) {
              final items = _filteredItems(itemState.items, allCategories);

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty ? 'No items match "$_searchQuery"' : 'No items in this category.',
                        style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return BlocBuilder<StockCubit, StockState>(
                builder: (context, stockState) {
                  if (stockState is StockLoading) return const SkeletonGrid(itemCount: 8);
                  if (stockState is StockLoaded) {
                    final stockMap = {for (final s in stockState.stockList) s.stock.itemId: s};

                    return BlocBuilder<CartCubit, CartState>(
                      builder: (context, cartState) {
                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: crossAxisExtent,
                            childAspectRatio: 0.74,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, idx) {
                            final item = items[idx];
                            final defaultPrice = item.prices.isNotEmpty ? item.prices.first.price : 0.0;
                            final stockRecord = stockMap[item.id];
                            final qty = stockRecord?.stock.quantity ?? 0.0;
                            final minLevel = stockRecord?.stock.minLevel ?? 0.0;
                            final unit = stockRecord?.unitName ?? 'pcs';

                            // Compute currently in-cart quantity
                            final inCartQty = cartState.items
                                .where((c) => c.item.id == item.id)
                                .fold<int>(0, (sum, c) => sum + c.quantity);

                            final isOutOfStock = qty <= 0;
                            final isLowStock = qty > 0 && qty <= minLevel;

                            final badgeColor = isOutOfStock
                                ? const Color(0xFFDC2626)
                                : (isLowStock ? const Color(0xFFD97706) : const Color(0xFF16A34A));

                            final badgeText = isOutOfStock
                                ? 'Out of Stock'
                                : (isLowStock ? 'Low: ${qty.toInt()} $unit' : '${qty.toInt()} $unit');

                            return Card(
                              elevation: inCartQty > 0 ? 3 : 1,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: inCartQty > 0 ? theme.colorScheme.primary : const Color(0xFFE2E8F0),
                                  width: inCartQty > 0 ? 2 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  FeedbackService.tap();
                                  if (qty <= 0) {
                                    final proceed = await ConfirmationDialog.show(
                                      context,
                                      title: 'Out of Stock',
                                      message: '"${item.name}" is currently out of stock. Do you want to add anyway?',
                                      variant: DialogVariant.warning,
                                      confirmLabel: 'Proceed',
                                      cancelLabel: 'Cancel',
                                    );
                                    if (proceed != true || !context.mounted) return;
                                  }

                                  AddToCartModal.show(context, item: item);
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Thumbnail with In-Cart & Stock Badges
                                    Stack(
                                      children: [
                                        SizedBox(
                                          height: 105,
                                          width: double.infinity,
                                          child: _buildProductCardImage(theme, item),
                                        ),
                                        // Stock status badge
                                        Positioned(
                                          top: 6,
                                          left: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              badgeText,
                                              style: GoogleFonts.inter(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // In-Cart Badge Indicator
                                        if (inCartQty > 0)
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary,
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                                                ],
                                              ),
                                              child: Text(
                                                '$inCartQty in cart',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    // Item Details
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF1E293B),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '₱${defaultPrice.toStringAsFixed(2)}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Icon(
                                                    Icons.add_rounded,
                                                    size: 16,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            }
            return const Center(child: Text('No items available.'));
          },
        );
      },
    );
  }

  Widget _buildProductCardImage(ThemeData theme, Item item) {
    final hasImage = item.displayImage != null && item.displayImage!.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      child: hasImage
          ? FutureBuilder<String?>(
              future: ImageStorageService.resolveImagePath(item.displayImage),
              builder: (_, snap) {
                final path = snap.data;
                if (path != null) {
                  return Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _buildFallbackImage(theme),
                  );
                }
                return _buildFallbackImage(theme);
              },
            )
          : _buildFallbackImage(theme),
    );
  }

  Widget _buildFallbackImage(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
      ),
      child: Center(
        child: Icon(Icons.fastfood_outlined, size: 36, color: Colors.grey.shade400),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CART PANEL (SIDEBAR & BOTTOM SHEET)
  // ---------------------------------------------------------------------

  Widget _buildCartPanel(BuildContext context, ThemeData theme, {ScrollController? scrollController}) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final breakdown = cartState.breakdown;

        return Column(
          children: [
            // Cart Header Bar with Table Tag & Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFFF1F5F9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Active Table / Customer Indicator
                  InkWell(
                    onTap: () => _openAssignTableDialog(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.table_restaurant_outlined, size: 15, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            cartState.tableName ?? (cartState.customerName ?? 'Table / Cust [F4]'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Quick Action Icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hold Order Button
                      IconButton(
                        icon: const Icon(Icons.pause_circle_outline_rounded, size: 20),
                        tooltip: 'Hold / Suspend Order [F2]',
                        onPressed: cartState.items.isEmpty ? null : () => _openHoldOrderDialog(context),
                      ),
                      // Order Remarks / Kitchen Notes
                      IconButton(
                        icon: Icon(
                          Icons.edit_note_rounded,
                          size: 22,
                          color: (cartState.remarks != null && cartState.remarks!.isNotEmpty)
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        tooltip: 'Order Notes [F10]',
                        onPressed: () => _openOrderNotesDialog(context),
                      ),
                      // Clear Cart
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                        tooltip: 'Clear Cart',
                        onPressed: cartState.items.isEmpty
                            ? null
                            : () async {
                                final confirm = await ConfirmationDialog.show(
                                  context,
                                  title: 'Clear Active Cart',
                                  message: 'Are you sure you want to remove all items from the current cart?',
                                  variant: DialogVariant.danger,
                                  confirmLabel: 'Clear All',
                                );
                                if (confirm == true) context.read<CartCubit>().clearCart();
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cart Items List
            Expanded(
              child: cartState.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 44, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'Cart is empty',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'Tap items or scan barcode to add',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: cartState.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, idx) {
                        final cartItem = cartState.items[idx];
                        return CartLineItemTile(
                          cartItem: cartItem,
                          onTap: () {
                            LineItemActionDialog.show(
                              context,
                              cartItem: cartItem,
                              optionGroups: const [],
                              onSave: (updated) => context.read<CartCubit>().updateCartItem(cartItem.id, updated),
                              onRemove: () => context.read<CartCubit>().removeItem(cartItem.id),
                            );
                          },
                          onDecrease: () => context.read<CartCubit>().updateQuantity(cartItem.id, -1),
                          onIncrease: () => context.read<CartCubit>().updateQuantity(cartItem.id, 1),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),

            // BIR TAX & DISCOUNT BREAKDOWN SUMMARY
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Column(
                children: [
                  // Active Statutory Beneficiary Banner
                  if (cartState.appliedDiscount?.isSpecialVatExempt == true && cartState.beneficiaryName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 15, color: Color(0xFF059669)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${cartState.appliedDiscount!.name} • ${cartState.beneficiaryName} (${cartState.beneficiaryIdNo ?? "N/A"})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF065F46),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildSummaryRow('Gross Subtotal:', '₱${breakdown.grossSubtotal.toStringAsFixed(2)}'),
                  if (breakdown.itemDiscountAmount > 0)
                    _buildSummaryRow(
                      'Item Discounts / Free:',
                      '-₱${breakdown.itemDiscountAmount.toStringAsFixed(2)}',
                      textColor: const Color(0xFFB45309),
                      isBold: true,
                    ),
                  if (breakdown.vatExemptSales > 0 && cartState.appliedDiscount?.isSpecialVatExempt == true)
                    _buildSummaryRow(
                      'Less 12% VAT Exemption:',
                      '-₱${(breakdown.grossSubtotal - breakdown.vatableSales - breakdown.vatAmount).toStringAsFixed(2)}',
                      textColor: const Color(0xFF059669),
                      isBold: true,
                    ),
                  if (breakdown.manualDiscountAmount > 0)
                    _buildSummaryRow(
                      cartState.appliedDiscount?.isSpecialVatExempt == true
                          ? 'Less 20% SC/PWD Discount:'
                          : 'Order Discount:',
                      '-₱${breakdown.manualDiscountAmount.toStringAsFixed(2)}',
                      textColor: theme.colorScheme.error,
                      isBold: true,
                    ),
                  if (breakdown.surchargeAmount > 0 || (cartState.isServiceChargeActive && cartState.items.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Service Charge (${cartState.serviceChargeRate.toStringAsFixed(0)}%):',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: cartState.isServiceChargeWaived
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                  decoration: cartState.isServiceChargeWaived ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  FeedbackService.tap();
                                  context.read<CartCubit>().toggleServiceChargeWaived();
                                  AppToast.showInfo(
                                    context,
                                    message: cartState.isServiceChargeWaived
                                        ? 'Service charge restored'
                                        : 'Service charge waived for this order',
                                  );
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: cartState.isServiceChargeWaived
                                        ? const Color(0xFFECFDF5)
                                        : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: cartState.isServiceChargeWaived
                                          ? const Color(0xFFA7F3D0)
                                          : const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Text(
                                    cartState.isServiceChargeWaived ? 'Restore' : 'Waive',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: cartState.isServiceChargeWaived
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            cartState.isServiceChargeWaived
                                ? '₱0.00'
                                : '+₱${breakdown.surchargeAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: cartState.isServiceChargeWaived
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E293B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (breakdown.vatExemptSales > 0)
                    _buildSummaryRow(
                      'VAT-Exempt Sales:',
                      '₱${breakdown.vatExemptSales.toStringAsFixed(2)}',
                      isDimmed: true,
                    ),
                  _buildSummaryRow(
                    'VATable Sales (12%):',
                    '₱${breakdown.vatableSales.toStringAsFixed(2)}',
                    isDimmed: true,
                  ),
                  _buildSummaryRow('VAT Amount (12%):', '₱${breakdown.vatAmount.toStringAsFixed(2)}', isDimmed: true),

                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Due:',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '₱${breakdown.netTotal.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      // Discount Button
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.discount_outlined, size: 17),
                          label: Text(
                            cartState.appliedDiscount != null
                                ? cartState.appliedDiscount!.name
                                : (cartState.manualDiscountPercentage > 0
                                      ? '${cartState.manualDiscountPercentage.toInt()}% Off'
                                      : (cartState.manualDiscountFixed > 0
                                            ? '₱${cartState.manualDiscountFixed.toStringAsFixed(0)} Off'
                                            : 'Discount [F8]')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          onPressed: cartState.items.isEmpty ? null : () => _openDiscountDialog(context),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Surcharge Button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: cartState.surchargeAmount > 0
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(
                          Icons.room_service_outlined,
                          size: 20,
                          color: cartState.surchargeAmount > 0 ? theme.colorScheme.primary : const Color(0xFF475569),
                        ),
                        tooltip: 'Service Charge [F9]',
                        onPressed: cartState.items.isEmpty ? null : () => _openSurchargeDialog(context, breakdown),
                      ),
                      const SizedBox(width: 8),

                      // Checkout Button
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                          icon: const Icon(Icons.payments_rounded, size: 18),
                          label: Text(
                            'CHECKOUT [F12]',
                            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: cartState.items.isEmpty
                              ? null
                              : () {
                                  if (scrollController != null) {
                                    Navigator.of(context).pop();
                                  }
                                  _openPaymentDialog(context, breakdown);
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? textColor, bool isBold = false, bool isDimmed = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isDimmed ? 11 : 12.5,
              color: isDimmed ? const Color(0xFF94A3B8) : (textColor ?? const Color(0xFF475569)),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isDimmed ? 11 : 12.5,
              color: isDimmed ? const Color(0xFF94A3B8) : (textColor ?? const Color(0xFF1E293B)),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MOBILE BOTTOM CART SUMMARY BAR
  // ---------------------------------------------------------------------

  Widget _buildMobileCartSummaryBar(ThemeData theme) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        if (cartState.items.isEmpty) return const SizedBox.shrink();

        final breakdown = cartState.breakdown;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: InkWell(
              onTap: () => _openMobileCartSheet(context),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '${cartState.items.length} item${cartState.items.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '₱${breakdown.netTotal.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // FOOTER HOTKEYS STATUS BAR
  // ---------------------------------------------------------------------

  Widget _buildHotkeyFooterBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: const [
            HotkeyBadge(label: 'F1 Search / Scan', fontSize: 11),
            SizedBox(width: 8),
            HotkeyBadge(label: 'F2 Hold Order', fontSize: 11),
            SizedBox(width: 8),
            HotkeyBadge(label: 'F3 Recall Held', fontSize: 11),
            SizedBox(width: 8),
            HotkeyBadge(label: 'F4 Table & Cust', fontSize: 11),
            SizedBox(width: 8),
            HotkeyBadge(label: 'F8 Discount', fontSize: 11),
            SizedBox(width: 8),
            HotkeyBadge(label: 'F9 Surcharge', fontSize: 11),
            SizedBox(width: 8),
            HotkeyBadge(label: 'F10 Notes', fontSize: 11),
            SizedBox(width: 8),
            HotkeyBadge(label: 'F12 Checkout', fontSize: 11),
            SizedBox(width: 8),
            HotkeyBadge(label: 'Esc Back', fontSize: 11),
          ],
        ),
      ),
    );
  }
}
