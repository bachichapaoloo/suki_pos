import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/utils/image_storage_service.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/maintenance/option_group.dart';
import 'package:suki_pos/domain/entities/maintenance/option_value.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';

class ItemDetailModalDialog extends StatefulWidget {
  const ItemDetailModalDialog({
    super.key,
    required this.item,
    required this.optionGroups,
    this.existingCartItem,
    required this.onConfirm,
  });
  final Item item;
  final List<OptionGroup> optionGroups;
  final CartItem? existingCartItem;
  final Function({
    required List<OptionValue> selectedOptions,
    required int quantity,
    String? notes,
  })
  onConfirm;

  static Future<void> show(
    BuildContext context, {
    required Item item,
    required List<OptionGroup> optionGroups,
    CartItem? existingCartItem,
    required Function({
      required List<OptionValue> selectedOptions,
      required int quantity,
      String? notes,
    })
    onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ItemDetailModalDialog(
        item: item,
        optionGroups: optionGroups,
        existingCartItem: existingCartItem,
        onConfirm: onConfirm,
      ),
    );
  }

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
        // Single Select (Radio behavior)
        _selectedSelections[groupId] = [val];
      } else {
        // Multi Select (Checkbox behavior)
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
          SnackBar(
            content: Text('Please select a required option for "${group.name}".'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    }
    return true;
  }

  double get _computedUnitPrice {
    final basePrice = widget.item.prices.isNotEmpty
        ? widget.item.prices
              .firstWhere(
                (p) => p.priceLevel.toLowerCase() == 'default',
                orElse: () => widget.item.prices.first,
              )
              .price
        : widget.item.costPrice;

    final optionsDelta = _selectedSelections.values
        .expand((list) => list)
        .fold<double>(0.0, (sum, opt) => sum + opt.priceDelta);

    return basePrice + optionsDelta;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.existingCartItem != null;
    final allSelectedValues = _selectedSelections.values.expand((list) => list).toList();
    final totalPrice = _computedUnitPrice * _quantity;

    return ConfirmationDialog(
      title: isEditing ? 'Edit Item Details' : 'Customize Item',
      width: 520,
      maxHeight: 640,
      showCloseButton: true,
      showDividers: true,
      confirmLabel: isEditing ? 'Update Cart' : 'Add to Cart',
      cancelLabel: 'Cancel',
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () {
        if (_validate()) {
          widget.onConfirm(
            selectedOptions: allSelectedValues,
            quantity: _quantity,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
          Navigator.of(context).pop();
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Item Header Overview (Image, Name & Dynamic Price Badge)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                if (widget.item.displayImage != null && widget.item.displayImage!.isNotEmpty)
                  FutureBuilder<String?>(
                    future: ImageStorageService.resolveImagePath(widget.item.displayImage),
                    builder: (_, snap) {
                      final path = snap.data;
                      if (path == null) return _buildFallbackThumbnail(colorScheme);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(path),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackThumbnail(colorScheme),
                        ),
                      );
                    },
                  )
                else
                  _buildFallbackThumbnail(colorScheme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Base: ₱${widget.item.prices.first.price.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '₱${totalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Quantity Stepper
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Option Groups & Modifier Selections
          if (widget.optionGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No customizable options for this item.',
                  style: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...widget.optionGroups.map((group) {
              final selectedForGroup = _selectedSelections[group.id!] ?? [];
              final isSingleSelect = group.selectionType == 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Row(
                          children: [
                            Text(
                              group.name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (group.isRequired)
                              Text(
                                ' * (Required)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.error,
                                ),
                              )
                            else
                              Text(
                                ' (Optional)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Option Values (Radio for single select, Checkbox for multi select)
                      ...group.values.map((val) {
                        final isSelected = selectedForGroup.any((v) => v.id == val.id);
                        final priceDeltaText = val.priceDelta > 0
                            ? '+₱${val.priceDelta.toStringAsFixed(2)}'
                            : (val.priceDelta < 0 ? '-₱${val.priceDelta.abs().toStringAsFixed(2)}' : null);

                        if (isSingleSelect) {
                          return RadioListTile<int>(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            value: val.id!,
                            groupValue: selectedForGroup.isNotEmpty ? selectedForGroup.first.id : null,
                            onChanged: (_) => _onOptionSelected(group, val),
                            title: Text(
                              val.alias?.isNotEmpty == true ? val.alias! : val.alias!,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            secondary: priceDeltaText != null
                                ? Text(
                                    priceDeltaText,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                : null,
                          );
                        }

                        return CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          value: isSelected,
                          onChanged: (_) => _onOptionSelected(group, val),
                          title: Text(
                            val.alias?.isNotEmpty == true ? val.alias! : val.alias!,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          secondary: priceDeltaText != null
                              ? Text(
                                  priceDeltaText,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : null,
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 4),

          // 4. Special Instructions & Notes
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Special Instructions / Notes',
              hintText: 'e.g. Less ice, no sugar, extra sauce...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackThumbnail(ColorScheme colorScheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.fastfood_outlined, size: 24, color: colorScheme.primary),
    );
  }
}
