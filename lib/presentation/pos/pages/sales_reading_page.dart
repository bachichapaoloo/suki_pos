import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_state.dart';
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
  static const Color bgGrey = Color(0xFFF7F8FA);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _refreshShift();
  }

  void _refreshShift() {
    final authState = context.read<AuthBloc>().state;
    final cashierId = authState is AuthAuthenticated ? (authState.user.id ?? 1) : 1;
    final shiftCubit = context.read<ShiftCubit>();
    if (shiftCubit.state is ShiftActive) {
      shiftCubit.refreshSalesReading();
    } else {
      shiftCubit.checkActiveShift(cashierId);
    }
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
                  AppToast.showInfo(context, message: 'Sales reading refreshed');
                },
              ),
            ],
          ),
          desktopHeader: AppUnifiedHeader(
            title: 'Sales Reading & Shift Closeout',
            subtitle: 'Mid-Day X-Reading and End-of-Day Z-Reading Shift Reports',
            parentHubTitle: 'POS Terminal',
            parentHubRoute: '/pos',
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  FeedbackService.tap();
                  _refreshShift();
                  AppToast.showInfo(context, message: 'Sales reading refreshed');
                },
                icon: Icon(Icons.refresh_rounded, size: 18, color: colorScheme.primary),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Refresh Reading', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.primary)),
                    const SizedBox(width: 8),
                    const HotkeyBadge(label: 'F5'),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.outlineVariant),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          desktopBody: BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, state) => _buildDesktopContent(context, state),
          ),
          mobileBody: BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, state) => _buildMobileContent(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context, ShiftState state) {
    if (state is ShiftLoading || state is ShiftInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ShiftError) {
      return _buildErrorState(context, state.message);
    }

    if (state is ShiftInactive) {
      return _buildInactiveState(context);
    }

    if (state is ShiftActive) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActiveShiftHeroCard(context, state),
            const SizedBox(height: 32),

            // Step 1: Cash Drawer Count
            Text(
              '1. Cash Drawer Count (Tender Declaration)',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Perform a physical cash count in the drawer before running reports.',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            _buildTenderDeclarationCard(context, state),
            const SizedBox(height: 36),

            // Step 2: Reports
            Text(
              '2. Shift Reports & Final Closeout',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Generate mid-shift X-Reading or execute final Z-Reading to close the shift.',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Row(
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

  Widget _buildMobileContent(BuildContext context, ShiftState state) {
    if (state is ShiftLoading || state is ShiftInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ShiftError) {
      return _buildErrorState(context, state.message);
    }

    if (state is ShiftInactive) {
      return _buildInactiveState(context);
    }

    if (state is ShiftActive) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActiveShiftHeroCard(context, state, isMobile: true),
            const SizedBox(height: 24),
            Text(
              '1. Cash Drawer Count',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 10),
            _buildTenderDeclarationCard(context, state, isMobile: true),
            const SizedBox(height: 28),
            Text(
              '2. Shift Reports',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 10),
            _buildXReadingCard(context, state),
            const SizedBox(height: 16),
            _buildZReadingCard(context, state),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActiveShiftHeroCard(BuildContext context, ShiftActive state, {bool isMobile = false}) {
    final shift = state.shift;
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF15803D), size: 24),
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
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Register Open',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: surfaceBorder),
          const SizedBox(height: 16),
          // Stats Row
          Row(
            children: [
              _buildMetricItem(
                'Beginning Cash',
                '₱${shift.beginningCash.toStringAsFixed(2)}',
                Icons.account_balance_wallet_outlined,
              ),
              _buildMetricItem(
                'Cash Sales',
                '₱${state.theoreticalCashSales.toStringAsFixed(2)}',
                Icons.trending_up_rounded,
                color: const Color(0xFF0284C7),
              ),
              _buildMetricItem(
                'Expected Total',
                '₱${state.expectedTotalCash.toStringAsFixed(2)}',
                Icons.calculate_outlined,
                color: primaryBlue,
              ),
              if (!isMobile)
                _buildMetricItem(
                  'Declared Cash',
                  state.declaredCash != null ? '₱${state.declaredCash!.toStringAsFixed(2)}' : 'Not Counted',
                  Icons.payments_outlined,
                  color: state.declaredCash != null ? const Color(0xFF15803D) : const Color(0xFFD97706),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, {Color color = textDark}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderDeclarationCard(BuildContext context, ShiftActive state, {bool isMobile = false}) {
    final hasDeclared = state.declaredCash != null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasDeclared ? const Color(0xFFBBF7D0) : surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasDeclared ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasDeclared ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
              color: hasDeclared ? const Color(0xFF15803D) : const Color(0xFFD97706),
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
                      ? 'Denominations logged. Short/Over: ₱${state.variance.toStringAsFixed(2)}'
                      : 'Physical cash count required before closing out register.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: hasDeclared && state.variance < 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
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
                  onConfirm: (denominations, totalCash) {
                    context.read<ShiftCubit>().saveTenderDeclaration(denominations, totalCash);
                  },
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasDeclared ? const Color(0xFFF1F5F9) : primaryBlue,
              foregroundColor: hasDeclared ? textDark : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              hasDeclared ? 'Edit Cash Count' : 'Enter Cash Count',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXReadingCard(BuildContext context, ShiftActive state) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            'X-Reading Report',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Mid-shift audit summary. Review cash drawer standing without closing register.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => XReadingReportDialog(shiftState: state),
                );
              },
              icon: const Icon(Icons.print_outlined, size: 18, color: primaryBlue),
              label: Text('View & Print X-Read', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: primaryBlue)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZReadingCard(BuildContext context, ShiftActive state) {
    final canClose = state.declaredCash != null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: canClose ? const Color(0xFFFECACA) : surfaceBorder),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFDC2626), size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            'Z-Reading (End of Day)',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Final shift closeout. Finalizes drawer figures and logs audit records to database.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
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
                        await context.read<ShiftCubit>().finalizeXReadingAndCloseShift();
                        if (mounted) {
                          Navigator.of(context).pushReplacementNamed('/pos');
                        }
                      }
                    },
              icon: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white),
              label: Text(
                canClose ? 'Close Shift & Z-Read' : 'Count Cash First',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text('Error loading shift details', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.inter(color: const Color(0xFF64748B))),
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

  Widget _buildInactiveState(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
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
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.point_of_sale_outlined, size: 48, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Shift Open',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'The register is currently closed. Please enter a beginning change fund to open shift.',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ChangeFundDialog(
                    onConfirm: (beginningCash) {
                      final authState = context.read<AuthBloc>().state;
                      final cashierId = authState is AuthAuthenticated ? (authState.user.id ?? 1) : 1;
                      context.read<ShiftCubit>().openShift(cashierId, beginningCash);
                    },
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              label: Text(
                'Open Register & Enter Fund',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
