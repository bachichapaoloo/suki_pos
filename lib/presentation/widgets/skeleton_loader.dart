import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shimmer and Skeleton loading widgets for smooth transitions.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.6));
  }
}

/// Shimmer placeholder table for desktop views.
class SkeletonTable extends StatelessWidget {
  const SkeletonTable({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          color: const Color(0xFFF8FAFC),
          child: Row(
            children: const [
              Expanded(flex: 3, child: SkeletonBox(height: 16)),
              SizedBox(width: 16),
              Expanded(flex: 2, child: SkeletonBox(height: 16)),
              SizedBox(width: 16),
              Expanded(flex: 2, child: SkeletonBox(height: 16)),
              SizedBox(width: 16),
              Expanded(flex: 1, child: SkeletonBox(height: 16)),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: rows,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: const [
                  Expanded(flex: 3, child: SkeletonBox(height: 20)),
                  SizedBox(width: 16),
                  Expanded(flex: 2, child: SkeletonBox(height: 20)),
                  SizedBox(width: 16),
                  Expanded(flex: 2, child: SkeletonBox(height: 20)),
                  SizedBox(width: 16),
                  Expanded(flex: 1, child: SkeletonBox(height: 20)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shimmer placeholder grid for POS item catalog.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(child: SkeletonBox(borderRadius: 10)),
            SizedBox(height: 10),
            SkeletonBox(height: 14, width: 100),
            SizedBox(height: 6),
            SkeletonBox(height: 16, width: 60),
          ],
        ),
      ),
    );
  }
}
