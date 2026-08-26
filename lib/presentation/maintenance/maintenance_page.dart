import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/presentation/widgets/app_unified_header.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          FeedbackService.tap();
          Navigator.of(context).pushReplacementNamed('/pos');
        },
      },
      child: Focus(
        autofocus: true,
        child: MainLayout(
          currentTab: MainTab.inventory,
          mobileAppBar: const AppUnifiedHeader(
            title: 'Maintenance Hub',
            parentHubTitle: 'POS Terminal',
            parentHubRoute: '/pos',
          ),
          mobileBody: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master Data',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMobileActionCard(
                  context,
                  'Departments',
                  'Organize store departments',
                  Icons.account_balance_outlined,
                  const Color(0xFFA5DDF1),
                  const Color(0xFF0369A1),
                  route: '/maintenance/departments',
                ),
                const SizedBox(height: 12),
                _buildMobileActionCard(
                  context,
                  'Categories',
                  'Manage item classifications',
                  Icons.grid_view_outlined,
                  primaryBlue.withOpacity(0.12),
                  primaryBlue,
                  route: '/maintenance/categories',
                ),
                const SizedBox(height: 12),
                _buildMobileActionCard(
                  context,
                  'Items',
                  'Manage products and services',
                  Icons.category_outlined,
                  primaryBlue.withOpacity(0.12),
                  primaryBlue,
                  route: '/maintenance/items',
                ),
                const SizedBox(height: 12),
                _buildMobileActionCard(
                  context,
                  'Discounts',
                  'Manage promotions & discounts',
                  Icons.discount_outlined,
                  const Color(0xFFA5DDF1),
                  const Color(0xFF0369A1),
                  route: '/maintenance/discounts',
                ),
                const SizedBox(height: 12),
                _buildMobileActionCard(
                  context,
                  'Service Charge',
                  'Configure rate, auto-compute & order types',
                  Icons.room_service_outlined,
                  const Color(0xFFF3E8FF),
                  const Color(0xFF7E22CE),
                  route: '/maintenance/service-charge',
                ),
                const SizedBox(height: 12),
                _buildMobileActionCard(
                  context,
                  'Stock Inventory',
                  'Track on-hand stock and perform adjustments',
                  Icons.inventory_2_outlined,
                  const Color(0xFFDCFCE7),
                  const Color(0xFF15803D),
                  route: '/inventory/stocks',
                ),
                const SizedBox(height: 28),
                Text(
                  'System & Administration',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMobileActionCard(
                  context,
                  'Users & Roles',
                  'Manage security and permissions',
                  Icons.admin_panel_settings_outlined,
                  const Color(0xFFFED7AA),
                  const Color(0xFFC2410C),
                  route: '/admin',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          desktopHeader: const AppUnifiedHeader(
            title: 'Maintenance Hub',
            subtitle: 'Master Data, Catalog, and Store Configuration',
            parentHubTitle: 'POS Terminal',
            parentHubRoute: '/pos',
          ),
          desktopBody: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title description
                Text(
                  'Master Data Configuration',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Configure and maintain categories, items, departments, and system entities.',
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                // Master Data Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1100 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.4,
                      children: [
                        _buildDesktopActionCard(
                          context,
                          title: 'Departments',
                          subtitle: 'Organize store departments & divisions',
                          icon: Icons.account_balance_outlined,
                          iconBg: const Color(0xFFA5DDF1),
                          iconColor: const Color(0xFF0369A1),
                          route: '/maintenance/departments',
                        ),
                        _buildDesktopActionCard(
                          context,
                          title: 'Categories',
                          subtitle: 'Manage item classifications & groups',
                          icon: Icons.grid_view_outlined,
                          iconBg: primaryBlue.withOpacity(0.12),
                          iconColor: primaryBlue,
                          route: '/maintenance/categories',
                        ),
                        _buildDesktopActionCard(
                          context,
                          title: 'Items',
                          subtitle: 'Manage products, pricing & inventory',
                          icon: Icons.category_outlined,
                          iconBg: primaryBlue.withOpacity(0.12),
                          iconColor: primaryBlue,
                          route: '/maintenance/items',
                        ),
                        _buildDesktopActionCard(
                          context,
                          title: 'Discounts',
                          subtitle: 'Manage promotional rates & discounts',
                          icon: Icons.discount_outlined,
                          iconBg: const Color(0xFFA5DDF1),
                          iconColor: const Color(0xFF0369A1),
                          route: '/maintenance/discounts',
                        ),
                        _buildDesktopActionCard(
                          context,
                          title: 'Service Charge',
                          subtitle: 'Configure rate, auto-compute & order types',
                          icon: Icons.room_service_outlined,
                          iconBg: const Color(0xFFF3E8FF),
                          iconColor: const Color(0xFF7E22CE),
                          route: '/maintenance/service-charge',
                        ),
                        _buildDesktopActionCard(
                          context,
                          title: 'Stock Inventory',
                          subtitle: 'Monitor stock on-hand, reorders & low alerts',
                          icon: Icons.inventory_2_outlined,
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF15803D),
                          route: '/inventory/stocks',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  'Administration & Security',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Configure roles, user permissions, and security controls.',
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1100 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.4,
                      children: [
                        _buildDesktopActionCard(
                          context,
                          title: 'Admin Hub',
                          subtitle: 'Access security, users & role configurations',
                          icon: Icons.admin_panel_settings_outlined,
                          iconBg: const Color(0xFFFED7AA),
                          iconColor: const Color(0xFFC2410C),
                          route: '/admin',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    String? route,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (route != null) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconBg,
    Color iconColor, {
    String? route,
  }) {
    return InkWell(
      onTap: () {
        if (route != null) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
