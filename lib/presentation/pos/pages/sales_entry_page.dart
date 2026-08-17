import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/utils/image_storage_service.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/option_group.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_event.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_state.dart';
import 'package:suki_pos/presentation/maintenance/option_group/bloc/option_group_cubit.dart';
import 'package:suki_pos/presentation/maintenance/option_group/bloc/option_group_state.dart';
import 'package:suki_pos/presentation/maintenance/order_type/bloc/order_type_cubit.dart';
import 'package:suki_pos/presentation/maintenance/order_type/bloc/order_type_state.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_state.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_state.dart';
import 'package:suki_pos/presentation/pos/widgets/add_to_cart_modal.dart';
import 'package:suki_pos/presentation/pos/widgets/cart_line_item_tile.dart';
import 'package:suki_pos/presentation/pos/widgets/change_fund_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/discount_selection_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/item_detail_modal_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/payment_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/receipt_preview_dialog.dart';

/// Responsive breakpoints for the Sales Entry layout.
class _Breakpoints {
  static const double mobile = 700;
  static const double tablet = 1100;
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ItemBloc>().add(LoadItems());
    context.read<CategoryBloc>().add(GetCategoriesEvent());
    context.read<DepartmentBloc>().add(GetDepartmentsEvent());
    context.read<OptionGroupCubit>().loadOptionGroups();
    context.read<OrderTypeCubit>().loadOrderTypes();

    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() => _searchQuery = query);
      }
    });

    // Verify shift status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyShiftStatus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getActiveCashierId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final shiftState = context.read<ShiftCubit>().state;

    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return 1;
  }

  void _verifyShiftStatus() {
    final cashierId = _getActiveCashierId(context);
    final shiftState = context.read<ShiftCubit>().state;

    if (shiftState is ShiftInactive || shiftState is ShiftInitial) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeFundDialog(
          onConfirm: (beginningCash) {
            context.read<ShiftCubit>().openShift(cashierId, beginningCash);
          },
        ),
      );
    }
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

          // 1. Submit order with active cashier and payment info
          final completedTxn = await cartCubit.submitOrder(
            cashierId: cashierId,
            paymentMethodId: paymentMethodId,
            cashTendered: cashTendered,
          );

          // 2. Verify widget lifecycle and completion status
          if (!mounted) return;

          if (completedTxn != null) {
            // Success Feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Sale Completed! Transaction #${completedTxn.transactionNo}'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green[700],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );

            // 3. Open Receipt & Electronic Journal Preview
            showDialog(
              context: context,
              builder: (_) => ReceiptPreviewDialog(
                transaction: completedTxn,
              ),
            );
          } else {
            // Error Feedback
            final errorMsg = cartCubit.state.errorMessage ?? 'Checkout failed. Please try again.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
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

  List<Item> _filteredItems(List<Item> items, List<Category> allCategories) {
    Set<int>? validCategoryIds;
    if (_selectedDepartmentId != null) {
      validCategoryIds = allCategories
          .where((cat) => cat.departmentId == _selectedDepartmentId)
          .map((cat) => cat.id)
          .toSet();
    }

    return items.where((item) {
      if (validCategoryIds != null && !validCategoryIds.contains(item.categoryId)) {
        return false;
      }

      if (_selectedCategoryId != null && item.categoryId != _selectedCategoryId) {
        return false;
      }

      if (_searchQuery.isNotEmpty && !item.name.toLowerCase().contains(_searchQuery)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text('Sales Entry', style: TextStyle(color: theme.colorScheme.onPrimary)),
        actions: [
          // Cart icon + badge, shown only on mobile widths (search/order-type live in the body).
          Builder(
            builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < _Breakpoints.mobile;
              if (!isMobile) return const SizedBox.shrink();
              return BlocBuilder<CartCubit, CartState>(
                builder: (context, cartState) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined),
                          tooltip: 'View Cart',
                          onPressed: cartState.items.isEmpty ? null : () => _openMobileCartSheet(context),
                        ),
                        if (cartState.totalItemCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                '${cartState.totalItemCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < _Breakpoints.mobile;
            final isTablet = !isMobile && constraints.maxWidth < _Breakpoints.tablet;

            if (isMobile) {
              return _buildMobileLayout(theme);
            }
            return _buildWideLayout(theme, isTablet: isTablet);
          },
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
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 12, left: 12),
          child: Row(
            children: [
              Expanded(child: _buildDepartmentDropdown(theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildCategoryDropdown(theme)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildItemGrid(theme, crossAxisExtent: 180)),
        _buildMobileCartSummaryBar(theme),
      ],
    );
  }

  Widget _buildWideLayout(ThemeData theme, {required bool isTablet}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT PANEL: Product Grid & Category Filters
          Expanded(
            flex: isTablet ? 5 : 3,
            child: Column(
              children: [
                _buildControlsBar(theme, isMobile: false),
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 12, left: 12),
                  child: Row(
                    children: [
                      Expanded(child: _buildDepartmentDropdown(theme)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCategoryDropdown(theme)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: _buildItemGrid(theme, crossAxisExtent: isTablet ? 170 : 200)),
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
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CONTROLS: SEARCH + ORDER TYPE (moved out of the AppBar so it never
  // gets squeezed — stacks on mobile, sits side-by-side on wider screens)
  // ---------------------------------------------------------------------

  Widget _buildControlsBar(ThemeData theme, {required bool isMobile}) {
    final searchField = TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search items...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              )
            : null,
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
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
    );

    final orderTypeDropdown = BlocBuilder<OrderTypeCubit, OrderTypeState>(
      builder: (context, state) {
        if (state is OrderTypeLoading) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (state is OrderTypeError) {
          return Text(state.message, style: TextStyle(color: theme.colorScheme.error));
        }
        if (state is OrderTypeLoaded && state.orderTypes.isNotEmpty) {
          return Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedOrderTypeId ?? 1,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                borderRadius: BorderRadius.circular(12),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedOrderTypeId = (value == null || value == 0) ? null : value;
                    });
                    context.read<CartCubit>().setOrderType(value);
                  }
                },
                items: [
                  const DropdownMenuItem<int>(
                    enabled: false,
                    value: 0,
                    child: Text(
                      'Select Order Type',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
                    ),
                  ),
                  ...([...state.orderTypes]..sort((a, b) => a.id.compareTo(b.id))).map(
                    (orderType) => DropdownMenuItem<int>(
                      value: orderType.id,
                      child: Text(orderType.name.toUpperCase()),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );

    return Padding(
      padding: const EdgeInsets.all(12),
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
  // DEPARTMENT AND CATEGORY FILTER DROPDOWN
  // ---------------------------------------------------------------------

  Widget _buildDepartmentDropdown(ThemeData theme) {
    return BlocBuilder<DepartmentBloc, DepartmentState>(
      builder: (context, state) {
        if (state is! DepartmentLoaded) return const SizedBox.shrink();

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedDepartmentId ?? 0,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedDepartmentId = (value == null || value == 0) ? null : value;
                  _selectedCategoryId = null;
                });
              },
              items: [
                const DropdownMenuItem<int>(
                  value: 0,
                  child: Text(
                    'Select Department',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
                  ),
                ),
                ...state.departments.map(
                  (dept) => DropdownMenuItem<int>(
                    value: dept.id,
                    child: Text(dept.name.toUpperCase()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is! CategoryLoaded) return const SizedBox.shrink();

        final visibleCategories = state.categories.where((cat) {
          if (_selectedDepartmentId != null && cat.departmentId != _selectedDepartmentId) {
            return false;
          }
          return true;
        }).toList();

        final isValidSelection = visibleCategories.any((cat) => cat.id == _selectedCategoryId);
        final activeValue = isValidSelection ? _selectedCategoryId : 0;

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: activeValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategoryId = (value == null) || value == 0 ? null : value;
                  });
                }
              },
              items: [
                const DropdownMenuItem<int>(
                  value: 0,
                  child: Text(
                    'All Categories',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
                  ),
                ),
                ...visibleCategories.map(
                  (cat) => DropdownMenuItem<int>(
                    value: cat.id,
                    child: Text(cat.name.toUpperCase()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(ThemeData theme, {required String label, required bool selected, required VoidCallback onTap}) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: theme.colorScheme.primary,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? theme.colorScheme.primary : Colors.grey.shade300),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF374151),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // ---------------------------------------------------------------------
  // ITEM GRID (auto-fits columns to available width — no hardcoded count)
  // ---------------------------------------------------------------------

  Widget _buildItemGrid(ThemeData theme, {required double crossAxisExtent}) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        final allCategories = categoryState is CategoryLoaded ? categoryState.categories : <Category>[];

        return BlocBuilder<ItemBloc, ItemState>(
          builder: (context, itemState) {
            if (itemState is ItemLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (itemState is ItemLoaded) {
              final items = _filteredItems(itemState.items, allCategories);

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No items match "${_searchController.text}"'
                            : 'No items in this category.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: crossAxisExtent,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  final defaultPrice = item.prices.isNotEmpty ? item.prices.first.price : 0.0;

                  return Card(
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => AddToCartModal.show(context, item: item),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 1.1,
                            child: _buildProductCardImage(theme, item),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '₱${defaultPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                    errorBuilder: (_, __, ___) => _buildFallbackImage(theme, item),
                  );
                }
                return _buildFallbackImage(theme, item);
              },
            )
          : _buildFallbackImage(theme, item),
    );
  }

  Widget _buildFallbackImage(ThemeData theme, Item item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            theme.colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.fastfood_outlined,
          size: 36,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CART PANEL — shared by the wide side-panel and the mobile bottom sheet
  // ---------------------------------------------------------------------

  Widget _buildCartPanel(BuildContext context, ThemeData theme, {ScrollController? scrollController}) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final breakdown = cartState.breakdown;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Cart (${cartState.totalItemCount})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: cartState.items.isEmpty ? null : () => context.read<CartCubit>().clearCart(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cartState.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Cart is empty', style: TextStyle(color: Colors.grey[600])),
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
                          onTap: () => AddToCartModal.show(
                            context,
                            item: cartItem.item,
                            existingCartItem: cartItem,
                          ),
                          onDecrease: () => context.read<CartCubit>().updateQuantity(cartItem.id, -1),
                          onIncrease: () => context.read<CartCubit>().updateQuantity(cartItem.id, 1),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),

            // BIR TAX & DISCOUNT BREAKDOWN SUMMARY
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('₱${breakdown.grossSubtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  if (breakdown.manualDiscountAmount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text(
                          '-₱${breakdown.manualDiscountAmount.toStringAsFixed(2)}',
                          style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('VATable Sales:', style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
                      Text(
                        '₱${breakdown.vatableSales.toStringAsFixed(2)}',
                        style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('VAT Amount (12%):', style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
                      Text(
                        '₱${breakdown.vatAmount.toStringAsFixed(2)}',
                        style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Due:', style: theme.textTheme.titleLarge),
                      Flexible(
                        child: Text(
                          '₱${breakdown.netTotal.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.discount_outlined),
                          label: Text(
                            cartState.manualDiscountPercentage > 0
                                ? '${cartState.manualDiscountPercentage.toInt()}% Off'
                                : (cartState.manualDiscountFixed > 0
                                      ? '₱${cartState.manualDiscountFixed.toStringAsFixed(0)} Off'
                                      : 'Discount'),
                          ),
                          onPressed: cartState.items.isEmpty
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => DiscountSelectionDialog(
                                      currentPercentage: cartState.manualDiscountPercentage,
                                      currentFixed: cartState.manualDiscountFixed,
                                      onApplyPercentage: (p) => context.read<CartCubit>().applyDiscountPercentage(p),
                                      onApplyFixed: (a) => context.read<CartCubit>().applyDiscountFixed(a),
                                      onRemoveDiscount: () => context.read<CartCubit>().removeDiscount(),
                                    ),
                                  );
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.payments),
                          label: const Text('CHECKOUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          onPressed: cartState.items.isEmpty
                              ? null
                              : () {
                                  if (scrollController != null) {
                                    // Inside the mobile bottom sheet — close it before opening the dialog.
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
                        '${cartState.totalItemCount} item${cartState.totalItemCount == 1 ? '' : 's'}',
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
}
