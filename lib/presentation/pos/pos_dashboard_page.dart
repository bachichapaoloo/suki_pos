import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Fallback responsive extension if your core/utils/responsive_layout.dart differs
extension ResponsiveContext on BuildContext {
  T responsiveValue<T>({required T mobile, required T tablet, required T desktop}) {
    final width = MediaQuery.sizeOf(this).width;
    if (width >= 1100) return desktop;
    if (width >= 650) return tablet;
    return mobile;
  }
}

class _ModuleItem {
  const _ModuleItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    this.badgeCount = 0,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final int badgeCount;
}

class PosDashboardPage extends StatelessWidget {
  const PosDashboardPage({super.key});

  static const List<_ModuleItem> _modules = [
    _ModuleItem(
      title: 'Sales Entry',
      icon: Icons.point_of_sale_rounded,
      color: Colors.blue,
      route: '/sales/entry',
    ),
    _ModuleItem(
      title: 'Sales Order',
      icon: Icons.receipt_long_rounded,
      color: Colors.orange,
      route: '/sales/order',
      badgeCount: 4, // Example: Pending orders needing attention
    ),
    _ModuleItem(
      title: 'Sales Reading',
      icon: Icons.query_stats_rounded,
      color: Colors.teal,
      route: '/sales/reading',
    ),
    _ModuleItem(
      title: 'Sales Inquiry',
      icon: Icons.search_rounded,
      color: Colors.indigo,
      route: '/sales/inquiry',
    ),
    _ModuleItem(
      title: 'Inventory',
      icon: Icons.inventory_2_rounded,
      color: Colors.green,
      route: '/inventory',
      badgeCount: 2, // Example: Low stock alerts
    ),
    _ModuleItem(
      title: 'Maintenance',
      icon: Icons.settings_suggest_rounded,
      color: Colors.blueGrey,
      route: '/maintenance',
    ),
    _ModuleItem(
      title: 'Admin Panel',
      icon: Icons.admin_panel_settings_rounded,
      color: Colors.red,
      route: '/admin',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = context.responsiveValue(mobile: 16.0, tablet: 24.0, desktop: 36.0);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.08),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: _buildHeader(context),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverToBoxAdapter(
                  child: _buildQuickStatsRow(context),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.all(horizontalPadding),
                sliver: _buildModuleGrid(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'SukiPOS',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      actions: [
        IconButton.filledTonal(
          tooltip: 'Shift Settings',
          icon: const Icon(Icons.access_time_filled_rounded),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Superuser',
          style: GoogleFonts.poppins(
            fontSize: context.responsiveValue(mobile: 22.0, tablet: 26.0, desktop: 30.0),
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Register #01 is open • Terminal online',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsRow(BuildContext context) {
    // Adapts from a single-column stack on small phones to a 3-column row on tablets/desktop
    final isMobile = MediaQuery.sizeOf(context).width < 650;

    final stats = [
      const _StatCard(title: "Today's Sales", value: '₱ 45,230.00', icon: Icons.trending_up, color: Colors.green),
      const _StatCard(title: 'Active Orders', value: '12 Pending', icon: Icons.pending_actions, color: Colors.orange),
      const _StatCard(title: 'Shift Duration', value: '4h 15m', icon: Icons.timer, color: Colors.blue),
    ];

    if (isMobile) {
      return Column(
        children: stats.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: e)).toList(),
      );
    }

    return Row(
      children: stats
          .expand(
            (widget) => [
              Expanded(child: widget),
              const SizedBox(width: 16),
            ],
          )
          .take(stats.length * 2 - 1)
          .toList(),
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    // Restores strict, uniform column counts per device screen
    final crossAxisCount = context.responsiveValue(
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.05, // Slightly wider than tall for ergonomic touch targets
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _ModuleCard(module: _modules[index]),
        childCount: _modules.length,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final _ModuleItem module;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      // CRITICAL FIX: Forces the Material card to expand and fill the entire
      // grid cell identically, regardless of how much text is inside.
      fit: StackFit.expand,
      children: [
        Material(
          color: colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed(module.route),
            borderRadius: BorderRadius.circular(24),
            hoverColor: module.color.withValues(alpha: 0.05),
            splashColor: module.color.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: module.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      module.icon,
                      size: 32,
                      color: module.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // CRITICAL FIX: Locking the text container height ensures
                  // 1-line and 2-line titles don't push the icons up or down,
                  // keeping all icons on the exact same horizontal axis.
                  SizedBox(
                    height: 42,
                    child: Center(
                      child: Text(
                        module.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (module.badgeCount > 0)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${module.badgeCount}',
                style: GoogleFonts.poppins(
                  color: colorScheme.onError,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
