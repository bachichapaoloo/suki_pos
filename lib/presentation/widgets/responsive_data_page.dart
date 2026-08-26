import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/presentation/widgets/app_unified_header.dart';
import 'package:suki_pos/presentation/widgets/hotkey_badge.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';
import 'package:suki_pos/presentation/widgets/skeleton_loader.dart';

/// Column definition for Desktop DataTable in [ResponsiveDataPage].
class ResponsiveTableColumn<T> {
  const ResponsiveTableColumn({
    required this.title,
    required this.cellBuilder,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
    this.numeric = false,
  });

  final String title;
  final Widget Function(T item) cellBuilder;
  final int flex;
  final Alignment alignment;
  final bool numeric;
}

/// A comprehensive responsive data page supporting Desktop DataTable
/// and Mobile Card/List views, search, empty/skeleton loading states, unified header, and hotkeys.
class ResponsiveDataPage<T> extends StatelessWidget {
  const ResponsiveDataPage({
    super.key,
    required this.title,
    required this.parentHubTitle,
    required this.parentHubRoute,
    required this.items,
    required this.columns,
    required this.mobileCardBuilder,
    this.onAddNew,
    this.currentTab = MainTab.inventory,
    this.isLoading = false,
    this.errorMessage,
    this.emptyMessage = 'No records found.',
    this.emptyIcon = Icons.inbox_outlined,
    this.searchQuery = '',
    this.onSearchChanged,
    this.searchHint = 'Search...',
    this.desktopActions = const [],
    this.filterWidgets = const [],
    this.totalCount,
    this.onRefresh,
    this.fabLabel,
  });

  final String title;
  final String parentHubTitle;
  final String parentHubRoute;
  final List<T> items;
  final List<ResponsiveTableColumn<T>> columns;
  final Widget Function(BuildContext context, T item) mobileCardBuilder;
  final VoidCallback? onAddNew;
  final MainTab currentTab;
  final bool isLoading;
  final String? errorMessage;
  final String emptyMessage;
  final IconData emptyIcon;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final List<Widget> desktopActions;
  final List<Widget> filterWidgets;
  final int? totalCount;
  final Future<void> Function()? onRefresh;
  final String? fabLabel;

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = totalCount ?? items.length;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          if (onAddNew != null) {
            FeedbackService.tap();
            onAddNew!();
          }
        },
        const SingleActivator(LogicalKeyboardKey.f5): () {
          if (onRefresh != null) {
            FeedbackService.tap();
            onRefresh!();
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacementNamed(parentHubRoute);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: MainLayout(
          currentTab: currentTab,
          mobileAppBar: AppUnifiedHeader(
            title: title,
            parentHubTitle: parentHubTitle,
            parentHubRoute: parentHubRoute,
            actions: [
              if (onAddNew != null)
                IconButton(
                  icon: Icon(Icons.add_rounded, color: colorScheme.primary),
                  tooltip: 'Add New',
                  onPressed: () {
                    FeedbackService.tap();
                    onAddNew!();
                  },
                ),
            ],
          ),
          floatingActionButton: onAddNew != null
              ? (fabLabel != null
                  ? FloatingActionButton.extended(
                      backgroundColor: colorScheme.primary,
                      onPressed: () {
                        FeedbackService.tap();
                        onAddNew!();
                      },
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: Text(
                        fabLabel!,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    )
                  : FloatingActionButton(
                      backgroundColor: colorScheme.primary,
                      elevation: 3,
                      onPressed: () {
                        FeedbackService.tap();
                        onAddNew!();
                      },
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                    ))
              : null,
          mobileBody: _buildMobileBody(context),
          desktopHeader: AppUnifiedHeader(
            title: title,
            parentHubTitle: parentHubTitle,
            parentHubRoute: parentHubRoute,
            actions: [
              ...desktopActions,
              if (onAddNew != null) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    FeedbackService.tap();
                    onAddNew!();
                  },
                  icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add New',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const HotkeyBadge(label: 'Ctrl+N', isLight: true, fontSize: 10),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
          desktopBody: _buildDesktopBody(context, count),
        ),
      ),
    );
  }

  Widget _buildDesktopBody(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDesktopToolbar(context),
            Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
            Expanded(child: _buildDesktopTableContent(context)),
            Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
            _buildDesktopPaginationFooter(count),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopToolbar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          if (filterWidgets.isNotEmpty) ...[
            const SizedBox(width: 16),
            ...filterWidgets,
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopTableContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const SkeletonTable(rows: 7);
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 48, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
          ),
          child: Row(
            children: columns.map((col) {
              return Expanded(
                flex: col.flex,
                child: Align(
                  alignment: col.alignment,
                  child: Text(
                    col.title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Data Rows
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: columns.map((col) {
                    return Expanded(
                      flex: col.flex,
                      child: Align(
                        alignment: col.alignment,
                        child: col.cellBuilder(item),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopPaginationFooter(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${items.length} of $count entries',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget content;

    if (isLoading) {
      content = ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => Container(
          height: 72,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Row(
            children: const [
              SkeletonBox(width: 44, height: 44, borderRadius: 10),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonBox(height: 16, width: 140),
                    SizedBox(height: 6),
                    SkeletonBox(height: 12, width: 90),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (errorMessage != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorMessage!,
            style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (items.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 48, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 15),
            ),
          ],
        ),
      );
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => mobileCardBuilder(context, items[index]),
      );
    }

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return Column(
      children: [
        if (onSearchChanged != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        Expanded(child: content),
      ],
    );
  }
}
