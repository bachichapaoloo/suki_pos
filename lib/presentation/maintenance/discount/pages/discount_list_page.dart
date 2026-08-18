import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/core/enums/enums.dart' hide DiscountType;
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/maintenance/discount_type.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_bloc.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_event.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_state.dart';
import 'package:suki_pos/presentation/maintenance/discount/widgets/discount_form_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';

class DiscountListPage extends StatefulWidget {
  const DiscountListPage({super.key});

  @override
  State<DiscountListPage> createState() => _DiscountListPageState();
}

class _DiscountListPageState extends State<DiscountListPage> {
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<DiscountBloc>().add(GetDiscountsEvent());
    searchController.addListener(() {
      setState(() {
        _searchQuery = searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _showFormDialog([Discount? discount, List<DiscountType> types = const []]) async {
    final result = await showDialog<Discount>(
      context: context,
      builder: (ctx) => DiscountFormDialog(discount: discount, discountTypes: types),
    );

    if (result != null) {
      context.read<DiscountBloc>().add(SaveDiscountEvent(result));
    }
  }

  Future<void> _confirmDelete(Discount discount) async {
    if (discount.id == null) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Discount',
      message: 'Are you sure you want to delete "${discount.name}"?',
      confirmLabel: 'Delete',
      variant: DialogVariant.danger,
    );

    if (confirmed == true && mounted) {
      context.read<DiscountBloc>().add(DeleteDiscountEvent(discount.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discounts')),
      body: Column(
        children: [
          TextFormField(controller: searchController),
          Expanded(
            child: BlocBuilder<DiscountBloc, DiscountState>(
              builder: (context, state) {
                if (state is DiscountLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is DiscountError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                if (state is DiscountLoaded) {
                  final filtered = state.discounts.where((d) {
                    return d.name.toLowerCase().contains(_searchQuery) ||
                        (d.discountTypeName?.toLowerCase().contains(_searchQuery) ?? false);
                  }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final discount = filtered[index];
                      final rateLabel = discount.percentage != null
                          ? '${discount.percentage!.toStringAsFixed(0)}%'
                          : '₱${discount.fixedAmount!.toStringAsFixed(2)}';

                      final capLabel = discount.capAmount != null ? ' • Cap: ₱${discount.capAmount}' : '';
                      final typeName = discount.discountTypeName ?? '';
                      return ListTile(
                        title: Text(discount.name),
                        subtitle: Text('$typeName ($rateLabel)$capLabel'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: discount.isActive,
                              onChanged: (value) {
                                context.read<DiscountBloc>().add(
                                  ToggleDiscountStatusEvent(discount, value),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit Discount',
                              onPressed: () => _showFormDialog(discount, state.discountTypes),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete Discount',
                              onPressed: () => _confirmDelete(discount),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final state = context.read<DiscountBloc>().state;
          final types = state is DiscountLoaded ? state.discountTypes : <DiscountType>[];
          _showFormDialog(null, types);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Discount'),
      ),
    );
  }
}
