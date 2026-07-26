import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/presentation/inventory/stock_cubit.dart';
import 'package:suki_pos/presentation/inventory/stock_state.dart';
import 'package:suki_pos/presentation/widgets/stock_adjustment_dialog.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  @override
  void initState() {
    super.initState();
    context.read<StockCubit>().loadStockList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<StockCubit>().loadStockList(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Item Name, Code, or Barcode...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => context.read<StockCubit>().filterSearch(val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<StockCubit, StockState>(
                builder: (context, state) {
                  if (state is StockLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is StockError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }

                  if (state is StockLoaded) {
                    final stocks = state.filteredList;

                    if (stocks.isEmpty) {
                      return const Center(child: Text('No Stock Records Found'));
                    }

                    return ListView.separated(
                      itemCount: stocks.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = stocks[index];
                        final isLow = item.isLowStock;

                        return ListTile(
                          title: Text(
                            item.itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Code: ${item.itemCode} | Barcode: ${item.barcode ?? 'N/A'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.stock.quantity} ${item.unitName ?? ''}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: isLow ? theme.colorScheme.error : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isLow)
                                    Text(
                                      'Low Stock (Min: ${item.stock.minLevel})',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.edit_note),
                                tooltip: 'Adjust Stock',
                                onPressed: () {
                                  showDialog(
                                    context: context,
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
                                },
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
      ),
    );
  }
}
