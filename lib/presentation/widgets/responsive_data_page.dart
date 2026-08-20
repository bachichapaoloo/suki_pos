import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';

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
/// and Mobile Card/List views, search, empty/loading states, and header actions.
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
  static const Color bgGrey = Color(0xFFF7F8FA);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = totalCount ?? items.length;

    return MainLayout(
      currentTab: currentTab,
      mobileAppBar: AppBar(
        backgroundColor: bgGrey,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.of(context).pushReplacementNamed(parentHubRoute),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (onAddNew != null)
            IconButton(
              icon: const Icon(Icons.add_rounded, color: primaryBlue),
              onPressed: onAddNew,
            ),
        ],
      ),
      floatingActionButton: onAddNew != null
          ? (fabLabel != null
              ? FloatingActionButton.extended(
                  backgroundColor: primaryBlue,
                  onPressed: onAddNew,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(
                    fabLabel!,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                )
              : FloatingActionButton(
                  backgroundColor: primaryBlue,
                  elevation: 3,
                  onPressed: onAddNew,
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ))
          : null,
      mobileBody: _buildMobileBody(context),
      desktopHeader: _buildDesktopHeader(context),
      desktopBody: _buildDesktopBody(context, count),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: surfaceBorder)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pushReplacementNamed(parentHubRoute),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 18, color: primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    parentHubTitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 24, color: Colors.grey[300]),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const Spacer(),
          ...desktopActions,
          if (onAddNew != null) ...[
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: onAddNew,
              icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
              label: Text(
                'Add New',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopBody(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: surfaceBorder),
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
            _buildDesktopToolbar(),
            const Divider(height: 1, color: surfaceBorder),
            Expanded(child: _buildDesktopTableContent(context)),
            const Divider(height: 1, color: surfaceBorder),
            _buildDesktopPaginationFooter(count),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600], size: 20),
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
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
            Icon(emptyIcon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 15),
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
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: surfaceBorder)),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
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
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
    Widget content;

    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
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
            Icon(emptyIcon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 15),
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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: surfaceBorder),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600], size: 20),
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
