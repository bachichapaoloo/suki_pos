import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/utils/responsive_layout.dart';

/// A module that can be navigated to from the dashboard.
class _ModuleItem {
  const _ModuleItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String route;
}

/// The main dashboard for the POS system.
class PosDashboardPage extends StatelessWidget {
  /// Creates a [PosDashboardPage].
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
      title: 'Maintenance',
      icon: Icons.settings_suggest_rounded,
      color: Colors.blueGrey,
      route: '/maintenance',
    ),
    _ModuleItem(
      title: 'Admin Maintenance',
      icon: Icons.admin_panel_settings_rounded,
      color: Colors.red,
      route: '/admin',
    ),
    _ModuleItem(
      title: 'Inventory',
      icon: Icons.inventory_2_rounded,
      color: Colors.green,
      route: '/inventory',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SukiPOS Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.05),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                Expanded(
                  child: _buildModuleGrid(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, Superuser',
          style: GoogleFonts.poppins(
            fontSize: context.responsiveValue(
              mobile: 24,
              tablet: 28,
              desktop: 32,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'What would you like to do today?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    final crossAxisCount = context.responsiveValue(
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.1,
      ),
      itemCount: _modules.length,
      itemBuilder: (context, index) => _ModuleCard(module: _modules[index]),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final _ModuleItem module;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Placeholder navigation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to ${module.title}')),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
              const SizedBox(height: 16),
              Text(
                module.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
