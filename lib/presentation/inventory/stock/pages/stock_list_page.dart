import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/domain/entities/inventory/stock.dart';
import 'package:suki_pos/domain/entities/inventory/stock_with_item.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/presentation/inventory/stock_cubit.dart';
import 'package:suki_pos/presentation/inventory/stock_state.dart';
import 'package:suki_pos/presentation/inventory/stock/widgets/stock_record_dialog.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_event.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_state.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/responsive_data_page.dart';
import 'package:suki_pos/presentation/widgets/stock_adjustment_dialog.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  String _searchQuery = '';
  bool _showOnlyLowStock = false;

  @override
  void initState() {
    super.initState();
    context.read<StockCubit>().loadStockList();
    context.read<ItemBloc>().add(LoadItems());
  }

  void _showAdjustmentDialog(StockWithItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StockAdjustmentDialog(
        stockItem: item,
        onConfirm: (delta, remarks) {
          context.read<StockCubit>().adjustStock(
            itemId: item.stock.itemId,
            delta: delta,
            remarks: remarks,
          );
        },
      ),
    );
  }

  void _showAddStockDialog() {
    final itemState = context.read<ItemBloc>().state;
    List<Item> items = [];
    if (itemState is ItemLoaded) {
      items = itemState.items;
    }

    if (items.isEmpty) {
      AppToast.showWarning(
        context,
        message: 'No catalog items found. Please create items first.',
        title: 'No Catalog Items',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StockRecordDialog(
        availableItems: items,
        onSave: (stock) {
          context.read<StockCubit>().saveStock(stock);
          AppToast.showSuccess(context, message: 'Stock record saved');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StockCubit, StockState>(
      listener: (context, state) {
        if (state is StockError) {
          AppToast.showError(context, message: state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is StockLoading;
        List<StockWithItem> stocks = [];
        String? errorMessage;

        if (state is StockLoaded) {
          stocks = state.filteredList;
        } else if (state is StockError) {
          errorMessage = state.message;
        }

        final filtered = stocks.where((s) {
          if (_showOnlyLowStock && !s.isLowStock) return false;
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          return s.itemName.toLowerCase().contains(query) ||
              s.itemCode.toLowerCase().contains(query) ||
              (s.barcode?.toLowerCase().contains(query) ?? false);
        }).toList();

        final lowStockCount = stocks.where((s) => s.isLowStock).length;

        return ResponsiveDataPage<StockWithItem>(
          title: 'Stock Inventory',
          parentHubTitle: 'Maintenance Hub',
          parentHubRoute: '/maintenance',
          currentTab: MainTab.inventory,
          items: filtered,
          isLoading: isLoading,
          errorMessage: errorMessage,
          searchQuery: _searchQuery,
          searchHint: 'Search stocks by item name, SKU code or barcode...',
          onAddNew: _showAddStockDialog,
          fabLabel: 'New Stock',
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query.trim().toLowerCase();
            });
          },
          onRefresh: () async {
            context.read<StockCubit>().loadStockList();
          },
          filterWidgets: [
            FilterChip(
              label: Text(
                'Low Stock Alerts ($lowStockCount)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _showOnlyLowStock ? Colors.white : const Color(0xFFDC2626),
                ),
              ),
              selected: _showOnlyLowStock,
              selectedColor: const Color(0xFFDC2626),
              backgroundColor: const Color(0xFFFEE2E2),
              side: const BorderSide(color: Color(0xFFFECACA)),
              onSelected: (val) => setState(() => _showOnlyLowStock = val),
            ),
          ],
          columns: [
            ResponsiveTableColumn<StockWithItem>(
              title: 'ITEM NAME / SKU',
              flex: 4,
              cellBuilder: (item) => Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.isLowStock ? const Color(0xFFFEE2E2) : const Color(0xFF355C8F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                      size: 20,
                      color: item.isLowStock ? const Color(0xFFDC2626) : const Color(0xFF355C8F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Code: ${item.itemCode}${item.barcode != null ? ' • Barcode: ${item.barcode}' : ''}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveTableColumn<StockWithItem>(
              title: 'MIN LEVEL',
              flex: 2,
              cellBuilder: (item) => Text(
                '${item.stock.minLevel.toStringAsFixed(0)} ${item.unitName ?? ''}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            ResponsiveTableColumn<StockWithItem>(
              title: 'ON HAND QUANTITY',
              flex: 2,
              cellBuilder: (item) => Row(
                children: [
                  Text(
                    '${item.stock.quantity} ${item.unitName ?? ''}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: item.isLowStock ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                    ),
                  ),
                  if (item.isLowStock) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LOW',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ResponsiveTableColumn<StockWithItem>(
              title: 'ACTIONS',
              flex: 2,
              alignment: Alignment.centerRight,
              cellBuilder: (item) => ElevatedButton.icon(
                onPressed: () => _showAdjustmentDialog(item),
                icon: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF355C8F)),
                label: Text(
                  'Adjust Stock',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF355C8F)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
          ],
          mobileCardBuilder: (context, item) {
            final isLow = item.isLowStock;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLow ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isLow ? const Color(0xFFFEE2E2) : const Color(0xFF355C8F).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                      color: isLow ? const Color(0xFFDC2626) : const Color(0xFF355C8F),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Code: ${item.itemCode} • Min: ${item.stock.minLevel.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'On Hand: ${item.stock.quantity} ${item.unitName ?? ''}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isLow ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                              ),
                            ),
                            if (isLow) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'LOW STOCK',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showAdjustmentDialog(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF355C8F),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text('Adjust', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
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
