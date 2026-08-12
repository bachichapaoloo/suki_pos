import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/domain/entities/maintenance/option_group.dart';
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_event.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_state.dart';
import 'package:suki_pos/presentation/pos/widgets/receipt_preview_dialog.dart';
import '../../../../domain/entities/maintenance/item.dart';
import '../../../../domain/entities/orders/cart_item.dart';
import '../../maintenance/category/bloc/category_bloc.dart';
import '../../maintenance/item/bloc/item_bloc.dart';
import '../../maintenance/option_group/bloc/option_group_cubit.dart';
import '../../maintenance/option_group/bloc/option_group_state.dart';
import '../bloc/cart_cubit.dart';
import '../bloc/cart_state.dart';
import '../widgets/discount_selection_dialog.dart';
import '../widgets/item_detail_modal_dialog.dart';
import '../widgets/payment_dialog.dart';

class SalesEntryPage extends StatefulWidget {
  const SalesEntryPage({super.key});

  @override
  State<SalesEntryPage> createState() => _SalesEntryPageState();
}

class _SalesEntryPageState extends State<SalesEntryPage> {
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<ItemBloc>().add(LoadItems());
    context.read<CategoryBloc>().add(GetCategoriesEvent());
    context.read<OptionGroupCubit>().loadOptionGroups();
  }

  void _openItemDetailModal(BuildContext context, Item item, {CartItem? existingCartItem}) {
    final optionGroupState = context.read<OptionGroupCubit>().state;
    final List<OptionGroup> optionGroups;
    if (optionGroupState is OptionGroupLoaded) {
      optionGroups = optionGroupState.optionGroups;
    } else {
      optionGroups = [];
    }

    showDialog(
      context: context,
      builder: (_) => ItemDetailModalDialog(
        item: item,
        optionGroups: optionGroups,
        existingCartItem: existingCartItem,
        onConfirm:
            ({
              required selectedOptions,
              required quantity,
              notes,
            }) {
              if (existingCartItem != null) {
                // Edit existing item in cart
                final updated = existingCartItem.copyWith(
                  selectedOptions: selectedOptions,
                  quantity: quantity,
                  notes: notes,
                );
                context.read<CartCubit>().updateCartItem(existingCartItem.id, updated);
              } else {
                // Add new item to cart
                context.read<CartCubit>().addItem(
                  item: item,
                  selectedOptions: selectedOptions,
                  quantity: quantity,
                  notes: notes,
                );
              }
            },
      ),
    );
  }

  void _openPaymentDialog(BuildContext context, TaxDiscountBreakdown breakdown) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents accidental closing during processing
      builder: (dialogCtx) => PaymentDialog(
        totalAmount: breakdown.netTotal,
        onPay: (paymentMethodId, cashTendered) async {
          // 1. Submit order via CartCubit and receive the completed TransactionDetail
          final completedTxn = await context.read<CartCubit>().submitOrder(
            cashierId: 1, // ID of active cashier (can be linked to AuthBloc)
            paymentMethodId: paymentMethodId,
            cashTendered: cashTendered,
          );

          // 2. Validate completion and widget context
          if (completedTxn != null && mounted) {
            // Show success toast notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Sale Completed! ${completedTxn.transactionNo}'),
                  ],
                ),
                backgroundColor: Colors.green[700],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );

            // 3. Immediately open the Thermal Receipt & EJ Preview Dialog
            showDialog(
              context: context,
              builder: (_) => ReceiptPreviewDialog(
                transaction: completedTxn,
              ),
            );
          } else if (mounted) {
            // Handle error state
            final errorMsg = context.read<CartCubit>().state.errorMessage ?? 'Checkout failed. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier Terminal / Register'),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              return SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Dine-In')),
                  ButtonSegment(value: 2, label: Text('Take-Out')),
                ],
                selected: {state.orderTypeId},
                onSelectionChanged: (set) {
                  context.read<CartCubit>().setOrderType(set.first);
                },
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // LEFT PANEL: Product Grid & Category Filters
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Category Filter Bar
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    if (state is CategoryLoaded) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All Items'),
                              selected: _selectedCategoryId == null,
                              onSelected: (_) => setState(() => _selectedCategoryId = null),
                            ),
                            const SizedBox(width: 8),
                            ...state.categories.map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(cat.name),
                                  selected: _selectedCategoryId == cat.id,
                                  onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const Divider(height: 1),

                // Item Grid
                Expanded(
                  child: BlocBuilder<ItemBloc, ItemState>(
                    builder: (context, state) {
                      if (state is ItemLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is ItemLoaded) {
                        final items = _selectedCategoryId == null
                            ? state.items
                            : state.items.where((i) => i.categoryId == _selectedCategoryId).toList();

                        if (items.isEmpty) {
                          return const Center(child: Text('No items in this category.'));
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, idx) {
                            final item = items[idx];
                            final defaultPrice = item.prices.isNotEmpty ? item.prices.first.price : 0.0;

                            return Card(
                              elevation: 2,
                              child: InkWell(
                                onTap: () => _openItemDetailModal(context, item),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                      ),
                                      Text(
                                        '₱${defaultPrice.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const Center(child: Text('No items available.'));
                    },
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1),

          // RIGHT PANEL: Cart & Order Summary
          Expanded(
            flex: 2,
            child: BlocBuilder<CartCubit, CartState>(
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
                          ? const Center(child: Text('Cart is empty'))
                          : ListView.builder(
                              itemCount: cartState.items.length,
                              itemBuilder: (context, idx) {
                                final cartItem = cartState.items[idx];
                                return ListTile(
                                  onTap: () => _openItemDetailModal(
                                    context,
                                    cartItem.item,
                                    existingCartItem: cartItem,
                                  ),
                                  title: Text(cartItem.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (cartItem.selectedOptions.isNotEmpty)
                                        Text(
                                          cartItem.selectedOptions.map((o) => o.alias).join(', '),
                                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
                                        ),
                                      if (cartItem.notes != null)
                                        Text(
                                          'Note: ${cartItem.notes}',
                                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => context.read<CartCubit>().updateQuantity(cartItem.id, -1),
                                      ),
                                      Text('${cartItem.quantity}', style: theme.textTheme.titleMedium),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => context.read<CartCubit>().updateQuantity(cartItem.id, 1),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          '₱${cartItem.totalPrice.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
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
                              Text(
                                'VAT Amount (12%):',
                                style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                              ),
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
                              Text(
                                '₱${breakdown.netTotal.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
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
                                              onApplyPercentage: (p) =>
                                                  context.read<CartCubit>().applyDiscountPercentage(p),
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
                                  label: const Text(
                                    'CHECKOUT',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: cartState.items.isEmpty
                                      ? null
                                      : () {
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
            ),
          ),
        ],
      ),
    );
  }
}

class LoadCategories {}
