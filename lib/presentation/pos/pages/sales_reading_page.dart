import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_state.dart';
import 'package:suki_pos/presentation/pos/widgets/cash_fund_operations_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/change_fund_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/tender_declaration_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/x_reading_report_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/z_reading_report_dialog.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/app_unified_header.dart';
import 'package:suki_pos/presentation/widgets/hotkey_badge.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';

class SalesReadingPage extends StatefulWidget {
  const SalesReadingPage({super.key});

  @override
  State<SalesReadingPage> createState() => _SalesReadingPageState();
}

class _SalesReadingPageState extends State<SalesReadingPage> {
  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _refreshShift();
  }

  int _getCashierId() {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? (authState.user.id) : 1;
  }

  String _getCashierName() {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.name : 'Cashier';
  }

  void _refreshShift() {
    final cashierId = _getCashierId();
    context.read<ShiftCubit>().checkActiveShift(cashierId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): () {
          FeedbackService.tap();
          _refreshShift();
          AppToast.showInfo(context, message: 'Sales reading refreshed');
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          FeedbackService.tap();
          Navigator.of(context).pushReplacementNamed('/pos');
        },
      },
      child: Focus(
        autofocus: true,
        child: MainLayout(
          currentTab: MainTab.sales,
          mobileAppBar: AppUnifiedHeader(
            title: 'Sales Reading & Shift',
            parentHubTitle: 'POS Terminal',
            parentHubRoute: '/pos',
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                tooltip: 'Refresh',
                onPressed: () {
                  FeedbackService.tap();
                  _refreshShift();
                  AppToast.showInfo(
                    context,
                    message: 'Sales reading refreshed',
                  );
                },
              ),
            ],
          ),
          desktopHeader: AppUnifiedHeader(
            title: 'Sales Reading & Shift Closeout',
            subtitle:
                '1. Cash Fund In/Out • 2. Tender Declaration • 3. X-Reading (End of Shift) • 4. Z-Reading (End of Day)',
            parentHubTitle: 'POS Terminal',
            parentHubRoute: '/pos',
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  FeedbackService.tap();
                  _refreshShift();
                  AppToast.showInfo(
                    context,
                    message: 'Sales reading refreshed',
                  );
                },
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Refresh Reading',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const HotkeyBadge(label: 'F5'),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.outlineVariant),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          desktopBody: BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, state) => _buildContent(context, state, false),
          ),
          mobileBody: BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, state) => _buildContent(context, state, true),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ShiftState state,
    bool isMobile,
  ) {
    if (state is ShiftLoading || state is ShiftInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ShiftError) {
      return _buildErrorState(context, state.message);
    }

    if (state is ShiftInactive) {
      return _buildInactiveState(context, state);
    }

    if (state is ShiftActive) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: isMobile ? 16 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActiveShiftHeroCard(context, state, isMobile: isMobile),
            const SizedBox(height: 28),

            // Module 1: Cash Fund Operations (Cash In / Cash Out)
            Text(
              '1. Cash Fund Operations (Cash In / Cash Out)',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Record mid-shift cash deposits (Cash In) or petty cash withdrawals (Cash Out).',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            _buildCashFundModuleCard(context, state),
            const SizedBox(height: 28),

            // Module 2: Tender Declaration
            Text(
              '2. Cash Drawer Count (Tender Declaration)',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Count all 12 physical bill and coin denominations in the drawer before running X-Reading.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            _buildTenderDeclarationCard(context, state, isMobile: isMobile),
            const SizedBox(height: 28),

            // Module 3 & 4: X-Reading & Z-Reading
            Text(
              '3 & 4. Shift Closeout (X-Reading) & End-of-Day (Z-Reading)',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Run X-Reading to close your cashier shift and record Short/Over, then run Z-Reading to close the business day.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            if (isMobile) ...[
              _buildXReadingCard(context, state),
              const SizedBox(height: 16),
              _buildZReadingCard(context, state),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildXReadingCard(context, state)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildZReadingCard(context, state)),
                ],
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActiveShiftHeroCard(
    BuildContext context,
    ShiftActive state, {
    bool isMobile = false,
  }) {
    final shift = state.shift;
    final netCashInOut = state.cashIn - state.cashOut;
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: Color(0xFF15803D),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift #${shift.id} Active',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cashier #${shift.cashierId} • Started at ${shift.startTime.toString().substring(0, 16)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Register Open',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: surfaceBorder),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMetricItem(
                'Beginning Cash',
                '₱${shift.beginningCash.toStringAsFixed(2)}',
              ),
              _buildMetricItem(
                'Cash Sales',
                '₱${state.theoreticalCashSales.toStringAsFixed(2)}',
                color: const Color(0xFF0284C7),
              ),
              _buildMetricItem(
                'Net Cash In/Out',
                '${netCashInOut >= 0 ? "+" : ""}₱${netCashInOut.toStringAsFixed(2)}',
                color: netCashInOut >= 0
                    ? const Color(0xFF15803D)
                    : const Color(0xFFDC2626),
              ),
              _buildMetricItem(
                'Expected Cash',
                '₱${state.expectedTotalCash.toStringAsFixed(2)}',
                color: primaryBlue,
              ),
              if (!isMobile)
                _buildMetricItem(
                  'Declared Cash',
                  state.declaredCash != null
                      ? '₱${state.declaredCash!.toStringAsFixed(2)}'
                      : 'Not Counted',
                  color: state.declaredCash != null
                      ? const Color(0xFF15803D)
                      : const Color(0xFFD97706),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value, {
    Color color = textDark,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFundModuleCard(BuildContext context, ShiftActive state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.swap_vert_circle_outlined,
              color: Color(0xFF0284C7),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash In: ₱${state.cashIn.toStringAsFixed(2)}  •  Cash Out: ₱${state.cashOut.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.cashFundLogs.length} cash movement(s) logged in this shift.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CashFundOperationsDialog(
                  cashierId: _getCashierId(),
                  cashierName: _getCashierName(),
                ),
              );
            },
            icon: const Icon(
              Icons.currency_exchange_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              'Cash In / Out',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderDeclarationCard(
    BuildContext context,
    ShiftActive state, {
    bool isMobile = false,
  }) {
    final hasDeclared = state.declaredCash != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDeclared ? const Color(0xFFBBF7D0) : surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasDeclared
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasDeclared
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_rounded,
              color: hasDeclared
                  ? const Color(0xFF15803D)
                  : const Color(0xFFD97706),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDeclared
                      ? 'Declared Cash: ₱${state.declaredCash!.toStringAsFixed(2)}'
                      : 'No Cash Declaration Entered',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDeclared
                      ? '12 Denominations logged. Short/Over: ₱${state.variance.toStringAsFixed(2)}'
                      : 'Physical cash count required before X-Reading & Z-Reading.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: hasDeclared && state.variance < 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => TenderDeclarationDialog(
                  initialDenominations: state.denominations,
                  nonCashSummary: state.nonCashSummary,
                  onConfirm: (denominations, totalCash) {
                    context.read<ShiftCubit>().saveTenderDeclaration(
                      denominations,
                      totalCash,
                    );
                  },
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasDeclared
                  ? const Color(0xFFF1F5F9)
                  : primaryBlue,
              foregroundColor: hasDeclared ? textDark : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              hasDeclared ? 'Edit Cash Count' : 'Enter Cash Count',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXReadingCard(BuildContext context, ShiftActive state) {
    final canRunXRead = state.declaredCash != null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canRunXRead ? const Color(0xFFBAE6FD) : surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF0284C7),
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '3. X-Reading (End of Cashier Shift)',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Finalizes your cashier shift, records Short/Over, seals shift records (x_read_status = 1), and prepares for Z-Reading.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !canRunXRead
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => XReadingReportDialog(shiftState: state),
                      );
                      if (confirmed == true && mounted) {
                        await context
                            .read<ShiftCubit>()
                            .finalizeXReadingAndCloseShift();
                      }
                    },
              icon: const Icon(
                Icons.print_outlined,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                canRunXRead
                    ? 'Run X-Reading & End Shift'
                    : 'Complete Tender Declaration First',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZReadingCard(BuildContext context, ShiftActive state) {
    final canClose = state.declaredCash != null && !state.hasOpenOrders;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canClose ? const Color(0xFFFECACA) : surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              color: Color(0xFFDC2626),
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '4. Z-Reading (End of Day)',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.hasOpenOrders
                ? 'Blocked: Settle or cancel all open held orders before running Z-Reading.'
                : 'Consolidates all shifts for the day into daily_summary, increments Z-Counter, and seals z_number.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: state.hasOpenOrders
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !canClose
                  ? null
                  : () async {
                      final closed = await showDialog<bool>(
                        context: context,
                        builder: (_) => ZReadingReportDialog(shiftState: state),
                      );

                      if (closed == true && mounted) {
                        await context
                            .read<ShiftCubit>()
                            .finalizeZReadingCloseout(_getCashierId());
                        if (mounted) {
                          context.read<AuthBloc>().add(LogoutEvent());
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      }
                    },
              icon: const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                canClose
                    ? 'Close Shift & Execute Z-Read'
                    : (state.hasOpenOrders
                          ? 'Open Orders Pending'
                          : 'Count Cash First'),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading shift details',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshShift,
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveState(BuildContext context, ShiftInactive state) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: surfaceBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                state.canRunZReading
                    ? Icons.lock_clock_rounded
                    : Icons.point_of_sale_outlined,
                size: 48,
                color: state.canRunZReading
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              state.canRunZReading
                  ? 'Shift X-Reading Complete • Ready for Z-Reading'
                  : (state.isZReadingDoneToday
                        ? 'End-of-Day Z-Reading Completed'
                        : 'No Active Shift Open'),
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.canRunZReading
                  ? 'All cashier shifts have completed Tender Declaration and X-Reading. You can now execute the End-of-Day Z-Reading closeout or open a new cashier shift.'
                  : (state.isZReadingDoneToday
                        ? 'Today\'s Z-Reading closeout has already been sealed in daily_summary.'
                        : 'The register is currently closed. Enter a beginning change fund to open a shift.'),
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (state.canRunZReading) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final closed = await showDialog<bool>(
                      context: context,
                      builder: (_) => ZReadingReportDialog(
                        zReadingData: state.zReadingData,
                      ),
                    );
                    if (closed == true && mounted) {
                      await context.read<ShiftCubit>().finalizeZReadingCloseout(
                        _getCashierId(),
                      );
                      if (mounted) {
                        context.read<AuthBloc>().add(LogoutEvent());
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Execute End-of-Day Z-Reading',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (!state.isZReadingDoneToday)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => ChangeFundDialog(
                        onConfirm: (beginningCash) {
                          context.read<ShiftCubit>().openShift(
                            _getCashierId(),
                            beginningCash,
                          );
                        },
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Open Register & Enter Fund',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
