import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/data/dao/order_dao.dart';
import 'package:suki_pos/injection_container.dart' as di;
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_state.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_state.dart';
import 'package:suki_pos/presentation/pos/bloc/transaction_history_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/transaction_history_state.dart';
import 'package:suki_pos/presentation/pos/widgets/shift_reconciliation_dialog.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/app_unified_header.dart';
import 'package:suki_pos/presentation/widgets/hotkey_badge.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';

class PosDashboardPage extends StatefulWidget {
  const PosDashboardPage({super.key});

  @override
  State<PosDashboardPage> createState() => _PosDashboardPageState();
}

class _PosDashboardPageState extends State<PosDashboardPage> {
  late Timer _timer;
  late DateTime _currentTime;
  DateTime? _shiftStartTime;

  double _totalSalesToday = 0.0;
  int _completedCountToday = 0;
  int _activeOrdersCount = 0;
  int _totalOrdersToday = 0;
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardMetrics();
      context.read<TransactionHistoryCubit>().loadHistory();
      
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<ShiftCubit>().checkActiveShift(authState.user.id);
      }
    });
  }

  Future<void> _loadDashboardMetrics() async {
    try {
      final metrics = await di.sl<OrderDao>().getDashboardMetrics();
      if (mounted) {
        setState(() {
          _totalSalesToday = (metrics['total_sales'] as num?)?.toDouble() ?? 0.0;
          _completedCountToday = (metrics['completed_count'] as int?) ?? 0;
          _activeOrdersCount = (metrics['active_count'] as int?) ?? 0;
          _totalOrdersToday = (metrics['total_orders_today'] as int?) ?? 0;
          _isLoadingMetrics = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMetrics = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _formattedTime => DateFormat('h:mm:ss a').format(_currentTime);
  String get _formattedDate => DateFormat('EEEE, MMMM d, yyyy').format(_currentTime);

  String _formatShiftDuration(DateTime? start) {
    if (start == null) return '00:00:00';
    final diff = _currentTime.difference(start);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f1): () {
          FeedbackService.tap();
          Navigator.of(context).pushNamed('/pos/sales-entry');
        },
        const SingleActivator(LogicalKeyboardKey.f2): () {
          FeedbackService.tap();
          Navigator.of(context).pushNamed('/pos/sales-reading');
        },
        const SingleActivator(LogicalKeyboardKey.f3): () {
          FeedbackService.tap();
          Navigator.of(context).pushNamed('/pos/transaction-history');
        },
        const SingleActivator(LogicalKeyboardKey.f4): () {
          FeedbackService.tap();
          Navigator.of(context).pushNamed('/inventory/stocks');
        },
        const SingleActivator(LogicalKeyboardKey.f5): () {
          FeedbackService.tap();
          _loadDashboardMetrics();
          context.read<TransactionHistoryCubit>().loadHistory();
          AppToast.showInfo(context, message: 'Dashboard metrics refreshed');
        },
        const SingleActivator(LogicalKeyboardKey.f6): () {
          FeedbackService.tap();
          Navigator.of(context).pushNamed('/maintenance');
        },
        const SingleActivator(LogicalKeyboardKey.f7): () {
          FeedbackService.tap();
          Navigator.of(context).pushNamed('/admin');
        },
      },
      child: Focus(
        autofocus: true,
        child: MainLayout(
          currentTab: MainTab.home,
          mobileAppBar: AppUnifiedHeader(
            title: 'SukiPOS',
            subtitle: 'Register #01 • Online',
            showBackButton: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 4, right: 8),
              child: Icon(Icons.storefront_outlined, color: colorScheme.primary, size: 24),
            ),
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formattedTime,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: colorScheme.primary, size: 22),
                tooltip: 'Refresh (F5)',
                onPressed: () {
                  FeedbackService.tap();
                  _loadDashboardMetrics();
                  context.read<TransactionHistoryCubit>().loadHistory();
                  AppToast.showInfo(context, message: 'Dashboard metrics refreshed');
                },
              ),
              IconButton(
                icon: Icon(Icons.logout_rounded, color: colorScheme.onSurfaceVariant, size: 22),
                tooltip: 'Logout',
                onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              ),
            ],
          ),
          desktopHeader: AppUnifiedHeader(
            title: 'SukiPOS Dashboard',
            subtitle: 'Terminal #01 • Point of Sale & Store Management',
            showBackButton: false,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.storefront_outlined, color: colorScheme.primary, size: 28),
            ),
            badge: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        _formattedTime,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                tooltip: 'Refresh (F5)',
                onPressed: () {
                  FeedbackService.tap();
                  _loadDashboardMetrics();
                  context.read<TransactionHistoryCubit>().loadHistory();
                  AppToast.showInfo(context, message: 'Dashboard metrics refreshed');
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.logout_rounded, color: colorScheme.onSurfaceVariant),
                tooltip: 'Logout',
                onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              ),
            ],
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
        ),
      ),
    );
  }

  Widget _buildDesktopWelcomeSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthAuthenticated ? authState.user.name : 'Cashier';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName 👋',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Shift Active',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileWelcomeSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthAuthenticated ? authState.user.name : 'Cashier';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, $userName 👋',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
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
    return BlocBuilder<ShiftCubit, ShiftState>(
      builder: (context, shiftState) {
        final shiftStart = shiftState is ShiftActive ? shiftState.shift.startTime : null;
        final formattedSales = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2).format(_totalSalesToday);

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.payments_outlined,
                iconBg: const Color(0xFFE2E8F0),
                iconColor: const Color(0xFF355C8F),
                title: 'Total Sales (Today)',
                value: formattedSales,
                badgeText: '$_completedCountToday Completed',
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
                value: '$_totalOrdersToday',
                badgeText: '$_activeOrdersCount pending',
                badgeBg: _activeOrdersCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
                badgeColor: _activeOrdersCount > 0 ? const Color(0xFFB45309) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildShiftDurationCard(shiftStart: shiftStart, isActive: shiftState is ShiftActive),
            ),
          ],
        );
      },
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

  Widget _buildShiftDurationCard({DateTime? shiftStart, required bool isActive}) {
    final durationStr = isActive ? _formatShiftDuration(shiftStart) : 'Shift Inactive';
    final elapsedSeconds = shiftStart != null ? _currentTime.difference(shiftStart).inSeconds : 0;
    // 8 hour target progress bar
    final progress = (elapsedSeconds / (8 * 3600)).clamp(0.0, 1.0);

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF16A34A) : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'Active' : 'Closed',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF15803D) : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
            durationStr,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: const Color(0xFF355C8F),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
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
                          title: 'Sales Reading',
                          icon: Icons.request_quote_outlined,
                          iconBg: const Color(0xFFA5DDF1),
                          iconColor: const Color(0xFF0369A1),
                          height: cardHeight,
                          route: '/pos/sales-reading',
                          hotkey: 'F2',
                        ),
                      ),
                      const SizedBox(width: spacing),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Sales Inquiry',
                          icon: Icons.search_rounded,
                          iconBg: const Color(0xFF355C8F),
                          iconColor: Colors.white,
                          height: cardHeight,
                          route: '/pos/transaction-history',
                          hotkey: 'F3',
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
                          title: 'Inventory',
                          icon: Icons.inventory_2_outlined,
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF15803D),
                          height: cardHeight,
                          route: '/inventory/stocks',
                          hotkey: 'F4',
                        ),
                      ),
                      const SizedBox(width: spacing),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Maintenance',
                          icon: Icons.build_outlined,
                          iconBg: const Color(0xFFE2E8F0),
                          iconColor: const Color(0xFF475569),
                          height: cardHeight,
                          route: '/maintenance',
                          hotkey: 'F6',
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
                      title: 'Admin Panel',
                      icon: Icons.admin_panel_settings_outlined,
                      iconBg: const Color(0xFFFECACA),
                      iconColor: const Color(0xFFB91C1C),
                      height: cardHeight,
                      route: '/admin',
                      hotkey: 'F7',
                    ),
                  ),
                  const SizedBox(width: spacing),
                  const Expanded(child: SizedBox()),
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
      onTap: () {
        FeedbackService.tap();
        Navigator.of(context).pushNamed('/pos/sales-entry');
      },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 32),
                ),
                const HotkeyBadge(label: 'F1', isLight: true, fontSize: 12),
              ],
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
    String? hotkey,
  }) {
    return InkWell(
      onTap: () {
        FeedbackService.tap();
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
        child: Stack(
          children: [
            if (hotkey != null)
              Positioned(
                top: 14,
                right: 14,
                child: HotkeyBadge(label: hotkey),
              ),
            Center(
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
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSalesCard() {
    final formattedSales = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2).format(_totalSalesToday);

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
            formattedSales,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                '$_completedCountToday completed orders today',
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
    return BlocBuilder<ShiftCubit, ShiftState>(
      builder: (context, shiftState) {
        final shiftStart = shiftState is ShiftActive ? shiftState.shift.startTime : null;
        final durationStr = shiftState is ShiftActive ? _formatShiftDuration(shiftStart) : 'Closed';

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
                      '$_activeOrdersCount pending',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _activeOrdersCount > 0 ? const Color(0xFFB45309) : const Color(0xFF1E293B),
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
                      durationStr,
                      style: GoogleFonts.inter(
                        fontSize: 16,
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
      },
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
                route: '/pos/sales-entry',
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
                route: '/orders',
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
                route: '/pos/sales-reading',
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
                route: '/pos/transaction-history',
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
                route: '/inventory/stocks',
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
          onTap: () {
            Navigator.of(context).pushNamed('/admin');
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
