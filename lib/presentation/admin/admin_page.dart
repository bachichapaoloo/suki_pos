import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';

class _AdminModule {
  const _AdminModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String route;
}

/// A central responsive landing page for all admin maintenance modules.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color bgGrey = Color(0xFFF7F8FA);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  static const List<_AdminModule> _modules = [
    _AdminModule(
      title: 'User Maintenance',
      subtitle: 'Manage cashier and admin accounts, credentials and active status',
      icon: Icons.people_alt_rounded,
      iconBg: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0284C7),
      route: '/admin/users',
    ),
    _AdminModule(
      title: 'Role Maintenance',
      subtitle: 'Configure permission matrices and feature access levels',
      icon: Icons.security_rounded,
      iconBg: Color(0xFFFEF3C7),
      iconColor: Color(0xFFD97706),
      route: '/admin/roles',
    ),
    _AdminModule(
      title: 'Receipt Maintenance',
      subtitle: 'View historical transactions, receipts and audit logs',
      icon: Icons.receipt_long_rounded,
      iconBg: Color(0xFFF1F5F9),
      iconColor: Color(0xFF475569),
      route: '/pos/transaction-history',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentTab: MainTab.inventory,
      mobileAppBar: AppBar(
        backgroundColor: bgGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/maintenance'),
        ),
        title: Text(
          'Admin Hub',
          style: GoogleFonts.inter(
            color: textDark,
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
              'Security & Access',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            const SizedBox(height: 12),
            ..._modules.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMobileCard(context, m),
            )),
          ],
        ),
      ),
      desktopHeader: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: surfaceBorder)),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pushReplacementNamed('/maintenance'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back, size: 18, color: primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Maintenance Hub',
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
              'Admin Hub',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
      ),
      desktopBody: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security & User Management',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage system users, define permission roles, and review audit records.',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1100 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _modules.length,
                  itemBuilder: (context, index) => _buildDesktopCard(context, _modules[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context, _AdminModule module) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pushReplacementNamed(module.route),
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
                      color: module.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(module.icon, color: module.iconColor, size: 24),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.subtitle,
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

  Widget _buildMobileCard(BuildContext context, _AdminModule module) {
    return InkWell(
      onTap: () => Navigator.of(context).pushReplacementNamed(module.route),
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
                color: module.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(module.icon, color: module.iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
