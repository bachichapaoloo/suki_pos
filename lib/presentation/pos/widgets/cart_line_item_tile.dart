import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:suki_pos/core/utils/image_storage_service.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';

/// A single row in the cart list — the thumbnail, name/options/notes, and
/// the quantity stepper + line total. Extracted as a standalone widget so
/// it can be reused anywhere a cart line needs to be rendered (side panel,
/// mobile bottom sheet, receipt-style previews, etc).
///
/// The thumbnail and overall row height scale with the available width
/// (via [LayoutBuilder]) instead of being pinned to a fixed size, so the
/// tile reads comfortably on both a narrow phone sheet and a wide desktop
/// side panel.
class CartLineItemTile extends StatelessWidget {
  const CartLineItemTile({
    super.key,
    required this.cartItem,
    required this.onTap,
    required this.onDecrease,
    required this.onIncrease,
    this.minImageSize = 72,
    this.maxImageSize = 108,
  });

  final CartItem cartItem;
  final VoidCallback onTap;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  /// Thumbnail is sized relative to the tile's width, clamped between these.
  final double minImageSize;
  final double maxImageSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = (constraints.maxWidth * 0.24).clamp(minImageSize, maxImageSize);

        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: imageSize * 0.11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(item: cartItem.item, size: imageSize),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cartItem.item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (cartItem.selectedOptions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          cartItem.selectedOptions.map((o) => o.alias).join(', '),
                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 12.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (cartItem.notes != null && cartItem.notes!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Note: ${cartItem.notes}',
                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _QuantityStepper(
                            quantity: cartItem.quantity,
                            onDecrease: onDecrease,
                            onIncrease: onIncrease,
                          ),
                          Text(
                            '₱${cartItem.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item, required this.size});

  final Item item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = item.displayImage != null && item.displayImage!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: hasImage
            ? FutureBuilder<String?>(
                future: ImageStorageService.resolveImagePath(item.displayImage),
                builder: (_, snap) {
                  final path = snap.data;
                  if (path != null) {
                    return Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(size),
                    );
                  }
                  return _placeholder(size);
                },
              )
            : _placeholder(size),
      ),
    );
  }

  Widget _placeholder(double size) {
    return Icon(Icons.inventory_2_outlined, size: size * 0.4, color: Colors.grey[400]);
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(icon: Icons.remove, onPressed: onDecrease),
          SizedBox(
            width: 28,
            child: Text('$quantity', textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
          ),
          _stepperButton(icon: Icons.add, onPressed: onIncrease),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
