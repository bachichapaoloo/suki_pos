import 'dart:io';

import 'package:flutter/material.dart';
import 'package:suki_pos/core/utils/image_storage_service.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/option_group.dart';
import 'package:suki_pos/domain/entities/maintenance/option_value.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';

class ItemDetailModalDialog extends StatefulWidget {
  final Item item;
  final List<OptionGroup> optionGroups;
  final CartItem? existingCartItem;
  final Function({
    required List<OptionValue> selectedOptions,
    required int quantity,
    String? notes,
  })
  onConfirm;

  const ItemDetailModalDialog({
    super.key,
    required this.item,
    required this.optionGroups,
    this.existingCartItem,
    required this.onConfirm,
  });

  @override
  State<ItemDetailModalDialog> createState() => _ItemDetailModalDialogState();
}

class _ItemDetailModalDialogState extends State<ItemDetailModalDialog> {
  final Map<int, List<OptionValue>> _selectedSelections = {};
  late TextEditingController _notesController;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCartItem;
    _quantity = existing?.quantity ?? 1;
    _notesController = TextEditingController(text: existing?.notes ?? '');

    // Pre-populate selections if editing an existing cart item
    if (existing != null && existing.selectedOptions.isNotEmpty) {
      for (final option in existing.selectedOptions) {
        _selectedSelections.putIfAbsent(option.optionGroupId, () => []).add(option);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onOptionSelected(OptionGroup group, OptionValue val) {
    setState(() {
      final groupId = group.id!;
      if (group.selectionType == 0) {
        // Single Select (Radio)
        _selectedSelections[groupId] = [val];
      } else {
        // Multi Select (Checkbox)
        final current = _selectedSelections[groupId] ?? [];
        if (current.any((v) => v.id == val.id)) {
          current.removeWhere((v) => v.id == val.id);
        } else {
          current.add(val);
        }
        _selectedSelections[groupId] = current;
      }
    });
  }

  bool _validate() {
    for (final group in widget.optionGroups) {
      final selected = _selectedSelections[group.id!] ?? [];
      if (group.isRequired && selected.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a required option for ${group.name}')),
        );
        return false;
      }
    }
    return true;
  }

  double get _computedUnitPrice {
    final basePrice = widget.item.prices.isNotEmpty
        ? widget.item.prices.firstWhere((p) => p.priceLevel == 'default', orElse: () => widget.item.prices.first).price
        : widget.item.costPrice;

    final optionsDelta = _selectedSelections.values
        .expand((list) => list)
        .fold<double>(0.0, (sum, opt) => sum + opt.priceDelta);

    return basePrice + optionsDelta;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingCartItem != null;
    final allSelectedValues = _selectedSelections.values.expand((list) => list).toList();

    return AlertDialog(
      title: Row(
        children: [
          if (widget.item.displayImage != null && widget.item.displayImage!.isNotEmpty) ...[
            FutureBuilder<String?>(
              future: ImageStorageService.resolveImagePath(widget.item.displayImage),
              builder: (_, snap) {
                final path = snap.data;
                if (path == null) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(path),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_outlined, size: 36),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                );
              },
            ),
          ],
          Expanded(
            child: Text(
              isEditing ? 'Edit ${widget.item.name}' : widget.item.name,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₱${(_computedUnitPrice * _quantity).toStringAsFixed(2)}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 480,
        child: Column(
          children: [
            // Quantity Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '$_quantity',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Option Groups (Modifiers)
            Expanded(
              child: widget.optionGroups.isEmpty
                  ? const Center(child: Text('No customizable options for this item.'))
                  : ListView.builder(
                      itemCount: widget.optionGroups.length,
                      itemBuilder: (context, index) {
                        final group = widget.optionGroups[index];
                        final selectedForGroup = _selectedSelections[group.id!] ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  Text(
                                    group.name,
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (group.isRequired)
                                    Text(
                                      ' *',
                                      style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                            ...group.values.map((val) {
                              final isSelected = selectedForGroup.any((v) => v.id == val.id);

                              return CheckboxListTile(
                                dense: true,
                                title: Text(val.alias ?? ''),
                                subtitle: val.priceDelta != 0 ? Text('+₱${val.priceDelta.toStringAsFixed(2)}') : null,
                                value: isSelected,
                                onChanged: (_) => _onOptionSelected(group, val),
                              );
                            }),
                            const Divider(),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),

            // Item Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Item Special Instructions / Notes',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_validate()) {
              widget.onConfirm(
                selectedOptions: allSelectedValues,
                quantity: _quantity,
                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              );
              Navigator.of(context).pop();
            }
          },
          child: Text(isEditing ? 'Update Cart' : 'Add to Cart'),
        ),
      ],
    );
  }
}
