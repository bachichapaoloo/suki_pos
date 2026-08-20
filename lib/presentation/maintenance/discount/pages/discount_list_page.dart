import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart' hide DiscountType;
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/maintenance/discount_type.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_bloc.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_event.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_state.dart';
import 'package:suki_pos/presentation/maintenance/discount/widgets/discount_form_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';
import 'package:suki_pos/presentation/widgets/responsive_data_page.dart';

class DiscountListPage extends StatefulWidget {
  const DiscountListPage({super.key});

  @override
  State<DiscountListPage> createState() => _DiscountListPageState();
}

class _DiscountListPageState extends State<DiscountListPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<DiscountBloc>().add(GetDiscountsEvent());
  }

  Future<void> _showFormDialog([Discount? discount, List<DiscountType> types = const []]) async {
    final result = await showDialog<Discount>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DiscountFormDialog(discount: discount, discountTypes: types),
    );

    if (result != null && mounted) {
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
    return BlocConsumer<DiscountBloc, DiscountState>(
      listener: (context, state) {
        if (state is DiscountSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is DiscountError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is DiscountLoading;
        List<Discount> discounts = [];
        List<DiscountType> discountTypes = [];
        String? errorMessage;

        if (state is DiscountLoaded) {
          discounts = state.discounts;
          discountTypes = state.discountTypes;
        } else if (state is DiscountError) {
          errorMessage = state.message;
        }

        final filtered = discounts.where((d) {
          if (_searchQuery.isEmpty) return true;
          return d.name.toLowerCase().contains(_searchQuery) ||
              (d.discountTypeName?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();

        return ResponsiveDataPage<Discount>(
          title: 'Discounts',
          parentHubTitle: 'Maintenance Hub',
          parentHubRoute: '/maintenance',
          items: filtered,
          isLoading: isLoading,
          errorMessage: errorMessage,
          searchQuery: _searchQuery,
          searchHint: 'Search discounts by name or type...',
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query.trim().toLowerCase();
            });
          },
          onAddNew: () => _showFormDialog(null, discountTypes),
          onRefresh: () async {
            context.read<DiscountBloc>().add(GetDiscountsEvent());
          },
          columns: [
            ResponsiveTableColumn<Discount>(
              title: 'DISCOUNT NAME',
              flex: 3,
              cellBuilder: (discount) => Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF355C8F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.discount_outlined, size: 20, color: Color(0xFF355C8F)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      discount.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveTableColumn<Discount>(
              title: 'TYPE',
              flex: 2,
              cellBuilder: (discount) => Text(
                discount.discountTypeName ?? '—',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            ResponsiveTableColumn<Discount>(
              title: 'RATE / VALUE',
              flex: 2,
              cellBuilder: (discount) {
                final rateLabel = discount.percentage != null
                    ? '${discount.percentage!.toStringAsFixed(0)}%'
                    : '₱${(discount.fixedAmount ?? 0.0).toStringAsFixed(2)}';
                final capLabel = discount.capAmount != null ? ' (Cap: ₱${discount.capAmount})' : '';
                return Text(
                  '$rateLabel$capLabel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                );
              },
            ),
            ResponsiveTableColumn<Discount>(
              title: 'STATUS',
              flex: 2,
              cellBuilder: (discount) => Row(
                children: [
                  Switch(
                    value: discount.isActive,
                    activeColor: const Color(0xFF355C8F),
                    onChanged: (value) {
                      context.read<DiscountBloc>().add(
                        ToggleDiscountStatusEvent(discount, value),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    discount.isActive ? 'Active' : 'Inactive',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: discount.isActive ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveTableColumn<Discount>(
              title: 'ACTIONS',
              flex: 1,
              alignment: Alignment.centerRight,
              cellBuilder: (discount) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                    tooltip: 'Edit',
                    onPressed: () => _showFormDialog(discount, discountTypes),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(discount),
                  ),
                ],
              ),
            ),
          ],
          mobileCardBuilder: (context, discount) {
            final rateLabel = discount.percentage != null
                ? '${discount.percentage!.toStringAsFixed(0)}%'
                : '₱${(discount.fixedAmount ?? 0.0).toStringAsFixed(2)}';
            final capLabel = discount.capAmount != null ? ' • Cap: ₱${discount.capAmount}' : '';
            final typeName = discount.discountTypeName ?? '';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA5DDF1).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.discount_outlined, color: Color(0xFF0369A1), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discount.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$typeName ($rateLabel)$capLabel',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: discount.isActive,
                    activeColor: const Color(0xFF355C8F),
                    onChanged: (value) {
                      context.read<DiscountBloc>().add(
                        ToggleDiscountStatusEvent(discount, value),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => _showFormDialog(discount, discountTypes),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(discount),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
