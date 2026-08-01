import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_event.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_state.dart';
import 'package:suki_pos/presentation/maintenance/option_group/bloc/option_group_cubit.dart';
import 'package:suki_pos/presentation/maintenance/option_group/bloc/option_group_state.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/inventory/stock_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_state.dart';
import 'package:suki_pos/presentation/pos/widgets/item_modifier_model_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/payment_dialog.dart';

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

  void _handleItemClick(BuildContext context, Item item) {
    final optionGroupState = context.read<OptionGroupCubit>().state;

    if (optionGroupState is OptionGroupLoaded && optionGroupState.optionGroups.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => ItemModifierModalDialog(
          item: item,
          optionGroups: optionGroupState.optionGroups,
          onConfirm: (selectedOptions, notes) {
            context.read<CartCubit>().addItem(
              item,
              selectedOptions: selectedOptions,
              notes: notes,
            );
          },
        ),
      );
    } else {
      context.read<CartCubit>().addItem(item);
    }
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
                      if (state is ItemLoading) return const Center(child: CircularProgressIndicator());
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
                                onTap: () => _handleItemClick(context, item),
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
                                  title: Text(cartItem.item.name),
                                  subtitle: cartItem.selectedOptions.isNotEmpty
                                      ? Text(cartItem.selectedOptions.map((o) => o.alias).join(', '))
                                      : null,
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Due:', style: theme.textTheme.titleLarge),
                              Text(
                                '₱${cartState.totalAmount.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.payments),
                              label: const Text(
                                'PAY / CHECKOUT',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              onPressed: cartState.items.isEmpty
                                  ? null
                                  : () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogCtx) => PaymentDialog(
                                          totalAmount: cartState.totalAmount,
                                          onPay: (methodId, tendered) {
                                            final authState = context.read<AuthBloc>().state;
                                            final cashierId = authState is AuthAuthenticated ? (authState.user.id ?? 1) : 1;
                                            context.read<CartCubit>().submitOrder(
                                              cashierId: cashierId,
                                              paymentMethodId: methodId,
                                              cashTendered: tendered,
                                            );
                                          },
                                        ),
                                      );
                                    },
                            ),
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
