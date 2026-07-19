import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentTab: MainTab.inventory,
      mobileAppBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/pos'),
        ),
        title: Text(
          'Maintenance',
          style: GoogleFonts.inter(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildMobileActionCard(
              context,
              'Items',
              Icons.category_outlined,
              const Color(0xFF355C8F),
              Colors.white,
              route: '/maintenance/items',
            ),
            const SizedBox(height: 12),
            _buildMobileActionCard(
              context,
              'Departments',
              Icons.account_balance_outlined,
              const Color(0xFFA5DDF1),
              const Color(0xFF0369A1),
              route: '/maintenance/departments',
            ),
            const SizedBox(height: 12),
            _buildMobileActionCard(
              context,
              'Categories',
              Icons.grid_view_outlined,
              const Color(0xFF355C8F),
              Colors.white,
              route: '/maintenance/categories',
            ),
            const SizedBox(height: 32),
            Text(
              'System Config',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildMobileActionCard(
              context,
              'Hardware',
              Icons.print_outlined,
              const Color(0xFFA5DDF1),
              const Color(0xFF0369A1),
            ),
            const SizedBox(height: 12),
            _buildMobileActionCard(context, 'Users', Icons.people_outline, const Color(0xFF355C8F), Colors.white),
            const SizedBox(height: 32),
          ],
        ),
      ),
      desktopBody: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Breadcrumbs
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb
                      Column(
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.of(context).pushReplacementNamed('/pos'),
                                borderRadius: BorderRadius.circular(4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.home_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Home',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Maintenance Hub',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Colors.grey),
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed('/pos');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF355C8F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.build_outlined, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Maintenance Hub',
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage system data and configurations',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.grey[600],
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
            const SizedBox(height: 48),

            // Master Data Section
            _buildSectionHeader(Icons.storage_outlined, 'Master Data'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDesktopActionCard(
                    context,
                    title: 'Items',
                    subtitle: 'Manage products and services',
                    icon: Icons.category_outlined,
                    iconBg: const Color(0xFF355C8F),
                    iconColor: Colors.white,
                    route: '/maintenance/items',
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildDesktopActionCard(
                    context,
                    title: 'Departments',
                    subtitle: 'Organize store departments',
                    icon: Icons.account_balance_outlined,
                    iconBg: const Color(0xFFA5DDF1),
                    iconColor: const Color(0xFF0369A1),
                    route: '/maintenance/departments',
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildDesktopActionCard(
                    context,
                    title: 'Categories',
                    subtitle: 'Manage item classifications',
                    icon: Icons.grid_view_outlined,
                    iconBg: const Color(0xFF355C8F),
                    iconColor: Colors.white,
                    route: '/maintenance/categories',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF355C8F), size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
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
    return InkWell(
      onTap: () {
        if (route != null) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Manage',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF355C8F),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: Color(0xFF355C8F), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileActionCard(
    BuildContext context,
    String title,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
