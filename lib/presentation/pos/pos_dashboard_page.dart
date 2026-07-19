import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';

class PosDashboardPage extends StatelessWidget {
  const PosDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentTab: MainTab.home,
      mobileAppBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: Color(0xFF355C8F)),
            const SizedBox(width: 8),
            Text(
              'SukiPOS',
              style: GoogleFonts.inter(
                color: const Color(0xFF355C8F),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      desktopHeader: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, color: Color(0xFF355C8F), size: 32),
            const SizedBox(width: 8),
            Text(
              'SukiPOS',
              style: GoogleFonts.inter(
                color: const Color(0xFF355C8F),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const Spacer(),
            // Center Title or Empty space
            const Spacer(),
            const Icon(Icons.access_time, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              '1:10 AM',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.grey),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      mobileBody: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMobileWelcomeSection(),
            const SizedBox(height: 24),
            _buildMobileSalesCard(),
            const SizedBox(height: 16),
            _buildMobileStatsRow(),
            const SizedBox(height: 32),
            _buildOperationsText(),
            const SizedBox(height: 16),
            _buildMobileOperationsGrid(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
      desktopBody: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopWelcomeSection(),
            const SizedBox(height: 32),
            _buildSummaryCards(),
            const SizedBox(height: 48),
            _buildStoreOperationsHeader(),
            const SizedBox(height: 24),
            _buildDesktopOperationsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Welcome back, Maria',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 12),
            const Text('👋', style: TextStyle(fontSize: 32)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Shift started at 08:00 AM • Main Store Branch',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Maria',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF355C8F),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Register #01 is open • Terminal online',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.payments_outlined,
            iconBg: const Color(0xFFE2E8F0),
            iconColor: const Color(0xFF355C8F),
            title: 'Total Sales (Today)',
            value: '₱ 24,500.00',
            badgeText: '+14% Today',
            badgeBg: const Color(0xFFBAE6FD),
            badgeColor: const Color(0xFF0369A1),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.list_alt_outlined,
            iconBg: const Color(0xFFE2E8F0),
            iconColor: const Color(0xFF355C8F),
            title: 'Active Orders',
            value: '128',
            badgeText: '4 pending',
            badgeBg: const Color(0xFFE2E8F0),
            badgeColor: const Color(0xFF475569),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildShiftDurationCard(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftDurationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer_outlined, color: Color(0xFF0369A1)),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Shift Duration',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '01:41:22',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 6,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF355C8F),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreOperationsHeader() {
    return Row(
      children: [
        const Icon(Icons.grid_view_rounded, color: Color(0xFF355C8F)),
        const SizedBox(width: 12),
        Text(
          'Store Operations',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopOperationsGrid(BuildContext context) {
    const double cardHeight = 160;
    const double spacing = 24;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSalesEntryCard(context, height: (cardHeight * 2) + spacing),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Sales Order',
                          icon: Icons.shopping_cart_outlined,
                          iconBg: const Color(0xFF355C8F),
                          iconColor: Colors.white,
                          height: cardHeight,
                        ),
                      ),
                      const SizedBox(width: spacing),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Sales Reading',
                          icon: Icons.request_quote_outlined,
                          iconBg: const Color(0xFFA5DDF1),
                          iconColor: const Color(0xFF0369A1),
                          height: cardHeight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacing),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Sales Inquiry',
                          icon: Icons.search,
                          iconBg: const Color(0xFF355C8F),
                          iconColor: Colors.white,
                          height: cardHeight,
                        ),
                      ),
                      const SizedBox(width: spacing),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Inventory',
                          icon: Icons.inventory_2_outlined,
                          iconBg: const Color(0xFFE2E8F0),
                          iconColor: const Color(0xFF475569),
                          height: cardHeight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: spacing),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Maintenance',
                      icon: Icons.build_outlined,
                      iconBg: const Color(0xFFE2E8F0),
                      iconColor: const Color(0xFF475569),
                      height: cardHeight,
                      route: '/maintenance',
                    ),
                  ),
                  const SizedBox(width: spacing),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Admin Panel',
                      icon: Icons.admin_panel_settings_outlined,
                      iconBg: const Color(0xFFFECACA),
                      iconColor: const Color(0xFFB91C1C),
                      height: cardHeight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: spacing),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildSalesEntryCard(BuildContext context, {required double height}) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF355C8F),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF355C8F).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 32),
            ),
            const Spacer(),
            Text(
              'Sales Entry',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new transaction or scan items.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required double height,
    String? route,
  }) {
    return InkWell(
      onTap: () {
        if (route != null) {
          Navigator.of(context).pushNamed(route);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
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
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSalesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF355C8F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Sales',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.trending_up, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₱14,520.00',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.arrow_upward, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                '12% higher than yesterday',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatsRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFBAE6FD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0369A1), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Active Orders',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1E293B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '24',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF355C8F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.access_time, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Shift Time',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1E293B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '4h 12m',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsText() {
    return Text(
      'Store Operations',
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildMobileOperationsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMobileActionCard(
                context,
                'Sales Entry',
                Icons.point_of_sale_rounded,
                const Color(0xFF355C8F),
                Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMobileActionCard(
                context,
                'Sales Order',
                Icons.list_alt_outlined,
                const Color(0xFFA5DDF1),
                const Color(0xFF0369A1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMobileActionCard(
                context,
                'Sales Reading',
                Icons.receipt_long_outlined,
                const Color(0xFF355C8F),
                Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMobileActionCard(
                context,
                'Sales Inquiry',
                Icons.search,
                const Color(0xFF355C8F),
                Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMobileActionCard(
                context,
                'Inventory',
                Icons.inventory_2_outlined,
                const Color(0xFFA5DDF1),
                const Color(0xFF0369A1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMobileActionCard(
                context,
                'Maintenance',
                Icons.build_outlined,
                const Color(0xFF355C8F),
                Colors.white,
                route: '/maintenance',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Admin Panel Row
        InkWell(
          onTap: () {},
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
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFECACA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFFB91C1C), size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  'Admin Panel',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
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
          Navigator.of(context).pushNamed(route);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
