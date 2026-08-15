import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_state.dart';
import 'package:suki_pos/presentation/pos/widgets/change_fund_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/tender_declaration_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/x_readomg_report_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/z_reading_report_dialog.dart';

class SalesReadingPage extends StatefulWidget {
  const SalesReadingPage({super.key});

  @override
  State<SalesReadingPage> createState() => _SalesReadingPageState();
}

class _SalesReadingPageState extends State<SalesReadingPage> {
  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Reading & Shift Closeout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              final cashierId = authState is AuthAuthenticated ? (authState.user.id) : 1;
              final shiftCubit = context.read<ShiftCubit>();
              if (shiftCubit.state is ShiftActive) {
                shiftCubit.refreshSalesReading();
              } else {
                shiftCubit.checkActiveShift(cashierId);
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ShiftCubit, ShiftState>(
        builder: (context, state) {
          if (state is ShiftLoading || state is ShiftInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ShiftError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading shift', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authState = context.read<AuthBloc>().state;
                      final cashierId = authState is AuthAuthenticated ? (authState.user.id ?? 1) : 1;
                      context.read<ShiftCubit>().checkActiveShift(cashierId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ShiftInactive) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.no_accounts_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No active shift open.', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Please open register and enter a change fund.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.add_card),
                    label: const Text('Open Register / Enter Change Fund'),
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
                  ),
                ],
              ),
            );
          }

          if (state is ShiftActive) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ACTIVE SHIFT HEADER CARD
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shift #${state.shift.id} Active',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cashier ID: #${state.shift.cashierId} • Started at ${state.shift.startTime.toString().substring(0, 16)}',
                              ),
                            ],
                          ),
                          Chip(
                            avatar: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            label: const Text('Register Open'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // STEP 3 & 4: TENDER DECLARATION STATUS
                  Text('1. Cash Drawer Count', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.payments, color: Color(0xFF355C8F)),
                      title: Text(
                        state.declaredCash != null
                            ? 'Declared Cash: ₱${state.declaredCash!.toStringAsFixed(2)}'
                            : 'No Tender Declaration Entered',
                      ),
                      subtitle: Text(
                        state.declaredCash != null
                            ? 'Denomination counts saved successfully.'
                            : 'Count the physical cash in the drawer before running X/Z-Readings.',
                      ),
                      trailing: FilledButton.tonal(
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
                        child: Text(state.declaredCash != null ? 'Edit Count' : 'Enter Cash Count'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // STEP 5 & 8: REPORTS & LOGOUT
                  Text(
                    '2. Shift Reports & Final Closeout',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.request_quote_outlined, size: 32, color: Color(0xFF0369A1)),
                                const SizedBox(height: 12),
                                Text(
                                  'X-Reading Report',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text('Mid-shift summary. Does not close the active register shift.'),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.print),
                                  label: const Text('View & Print X-Read'),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => XReadingReportDialog(shiftState: state),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.power_settings_new, size: 32, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(
                                  'Z-Reading (End of Day)',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text('Final shift closeout. Locks register and logs BIR audit summaries.'),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  icon: const Icon(Icons.lock),
                                  label: const Text('Close Shift & Z-Read'),
                                  onPressed: state.declaredCash == null
                                      ? null // Force tender declaration first
                                      : () async {
                                          final closed = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => ZReadingReportDialog(shiftState: state),
                                          );

                                          if (closed == true && mounted) {
                                            await context.read<ShiftCubit>().finalizeXReadingAndCloseShift();
                                            if (mounted) {
                                              Navigator.of(context).pushReplacementNamed('/');
                                            }
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
