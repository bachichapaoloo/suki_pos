import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/utils/image_storage_service.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';

/// A single row in the cart list — the thumbnail, name/options/notes, and
/// the quantity stepper + line total with support for Free Items, Item Discounts,
/// and Discount Exemption indicators.
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

  final double minImageSize;
  final double maxImageSize;

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = cartItem.hasItemDiscount;
    final isFree = cartItem.isFreeItem;
    final isDiscExempt = cartItem.isDiscountExempt;

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = (constraints.maxWidth * 0.24).clamp(minImageSize, maxImageSize);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
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
                      // Item Name & Discount Badges
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              cartItem.item.name,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.5, color: textDark),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFree) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'FREE',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ] else if (hasDiscount) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cartItem.itemDiscountPercent > 0
                                    ? '-${cartItem.itemDiscountPercent.toStringAsFixed(0)}%'
                                    : '-₱${cartItem.itemDiscountAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Modifier Options List
                      if (cartItem.selectedOptions.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          cartItem.selectedOptions.map((o) => o.alias).join(', '),
                          style: GoogleFonts.inter(color: primaryBlue, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Special Notes & Discount Exemption Tag
                      if (isDiscExempt || (cartItem.notes != null && cartItem.notes!.isNotEmpty)) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (isDiscExempt) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Disc Exempt',
                                  style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (cartItem.notes != null && cartItem.notes!.isNotEmpty)
                              Expanded(
                                child: Text(
                                  'Note: ${cartItem.notes}',
                                  style: GoogleFonts.inter(fontStyle: FontStyle.italic, fontSize: 11, color: const Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Stepper and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _QuantityStepper(
                            quantity: cartItem.quantity,
                            onDecrease: onDecrease,
                            onIncrease: onIncrease,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (hasDiscount || isFree)
                                Text(
                                  '₱${cartItem.totalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                isFree ? '₱0.00' : '₱${cartItem.effectiveTotalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isFree ? const Color(0xFF15803D) : textDark,
                                ),
                              ),
                            ],
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(icon: Icons.remove, onPressed: onDecrease),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            ),
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
        child: Icon(icon, size: 16, color: const Color(0xFF475569)),
      ),
    );
  }
}
