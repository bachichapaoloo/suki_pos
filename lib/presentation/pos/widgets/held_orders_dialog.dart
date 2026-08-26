import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suki_pos/domain/entities/orders/held_order.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';

class HeldOrdersDialog extends StatelessWidget {
  final List<HeldOrder> heldOrders;
  final Function(String heldOrderId) onRecall;
  final Function(String heldOrderId) onDelete;

  const HeldOrdersDialog({
    super.key,
    required this.heldOrders,
    required this.onRecall,
    required this.onDelete,
  });

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}m ago';
    return DateFormat('MMM dd, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.pause_circle_outline_rounded, color: Colors.amber.shade900, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parked & Held Orders',
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          '${heldOrders.length} order${heldOrders.length == 1 ? '' : 's'} on hold',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Content List
              if (heldOrders.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No held orders in queue.',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                        ),
                        Text(
                          'Use [F2] or Hold Order button to park an active cart.',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    itemCount: heldOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = heldOrders[index];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        order.orderLabel,
                                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.amber.shade200),
                                        ),
                                        child: Text(
                                          _formatTimeAgo(order.heldAt),
                                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.totalItemCount} item${order.totalItemCount == 1 ? '' : 's'} (${order.items.map((i) => "${i.quantity}x ${i.item.name}").take(3).join(', ')}${order.items.length > 3 ? '...' : ''})',
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₱${order.grossSubtotal.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.primary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  tooltip: 'Discard Held Order',
                                  onPressed: () {
                                    onDelete(order.id);
                                    AppToast.showInfo(context, message: 'Held order discarded');
                                    Navigator.of(context).pop();
                                  },
                                ),
                                const SizedBox(width: 4),
                                FilledButton.icon(
                                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                  label: Text('Resume', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    onRecall(order.id);
                                    AppToast.showSuccess(context, message: 'Resumed ${order.orderLabel}');
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
