import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/domain/entities/maintenance/bank.dart';
import 'package:suki_pos/domain/entities/maintenance/charge.dart';
import 'package:suki_pos/domain/entities/maintenance/payment_method.dart';
import 'package:suki_pos/presentation/maintenance/payment_method/bloc/payment_maintenance_cubit.dart';
import 'package:suki_pos/presentation/maintenance/payment_method/bloc/payment_maintenance_state.dart';
import 'package:suki_pos/presentation/maintenance/payment_method/widget/bank_form_dialog.dart';
import 'package:suki_pos/presentation/maintenance/payment_method/widget/charge_form_dialog.dart';
import 'package:suki_pos/presentation/maintenance/payment_method/widget/payment_method_form_dialog.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/app_unified_header.dart';
import 'package:suki_pos/presentation/widgets/skeleton_loader.dart';

class PaymentMethodListPage extends StatefulWidget {
  const PaymentMethodListPage({super.key});

  @override
  State<PaymentMethodListPage> createState() => _PaymentMethodListPageState();
}

class _PaymentMethodListPageState extends State<PaymentMethodListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<PaymentMaintenanceCubit>().loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getMethodIcon(String code) {
    switch (code.toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'atm':
      case 'online':
        return Icons.account_balance_rounded;
      case 'charge':
        return Icons.receipt_long_rounded;
      case 'gift_check':
      case 'coupon':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  // ===========================================================================
  // BUILD MAIN SCAFFOLD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppUnifiedHeader(
        title: 'Payment & Tender Maintenance',
        subtitle: 'Configure payment methods, bank merchant terminals, digital wallets & charge accounts',
        parentHubTitle: 'Maintenance Hub',
        parentHubRoute: '/maintenance',
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.payments_outlined, size: 18), text: 'Payment Methods'),
            Tab(icon: Icon(Icons.account_balance_outlined, size: 18), text: 'Banks & E-Wallets'),
            Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Charge Accounts'),
          ],
        ),
      ),
      body: BlocConsumer<PaymentMaintenanceCubit, PaymentMaintenanceState>(
        listener: (context, state) {
          if (state is PaymentMaintenanceError) {
            AppToast.showError(context, message: state.message);
          }
        },
        builder: (context, state) {
          if (state is PaymentMaintenanceLoading) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: SkeletonGrid(itemCount: 6),
            );
          }

          if (state is PaymentMaintenanceLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentMethodsTab(state.paymentMethods),
                _buildBanksTab(state.banks),
                _buildChargesTab(state.charges),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ===========================================================================
  // TAB 1: PAYMENT METHODS (INTERACTIVE CRUD + TOGGLE)
  // ===========================================================================

  Widget _buildPaymentMethodsTab(List<PaymentMethod> methods) {
    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${methods.length} Payment Methods Configured',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Add Payment Method',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                onPressed: () {
                  FeedbackService.tap();
                  PaymentMethodFormDialog.show(
                    context,
                    onSave: (newMethod) {
                      context.read<PaymentMaintenanceCubit>().savePaymentMethod(newMethod);
                      AppToast.showSuccess(context, message: 'Payment method "${newMethod.name}" created');
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // Grid/List
        Expanded(
          child: methods.isEmpty
              ? _buildEmptyState('No payment methods configured.\nTap "Add Payment Method" to create one.')
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 800;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 2 : 1,
                        mainAxisExtent: 96,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: methods.length,
                      itemBuilder: (context, index) {
                        final method = methods[index];
                        return _buildPaymentMethodCard(method);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isCoreMethod = ['cash', 'card'].contains(method.code.toLowerCase());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: method.isActive ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: method.isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getMethodIcon(method.code),
              color: method.isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        method.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: method.isActive ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        method.code,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  method.isActive ? 'Active in POS Checkout' : 'Hidden from Checkout',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: method.isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Actions: Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
            tooltip: 'Edit Name/Code',
            onPressed: () {
              FeedbackService.tap();
              PaymentMethodFormDialog.show(
                context,
                paymentMethod: method,
                onSave: (updated) {
                  context.read<PaymentMaintenanceCubit>().savePaymentMethod(updated);
                  AppToast.showSuccess(context, message: 'Payment method "${updated.name}" updated');
                },
              );
            },
          ),

          // Delete button (for custom methods)
          if (!isCoreMethod)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
              tooltip: 'Delete',
              onPressed: () {
                if (method.id == null) return;
                showDialog(
                  context: context,
                  builder: (_) => ConfirmationDialog(
                    title: 'Delete Payment Method',
                    message: 'Are you sure you want to delete "${method.name}"?',
                    confirmLabel: 'Delete',
                    cancelLabel: 'Cancel',
                    onConfirm: () {
                      context.read<PaymentMaintenanceCubit>().deletePaymentMethod(method.id!);
                      AppToast.showSuccess(context, message: 'Payment method "${method.name}" deleted');
                    },
                  ),
                );
              },
            ),

          // Active Switch
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: method.isActive,
              activeColor: const Color(0xFF2563EB),
              onChanged: (val) {
                FeedbackService.tap();
                context.read<PaymentMaintenanceCubit>().togglePaymentMethod(method, val);
                AppToast.showSuccess(
                  context,
                  message: '${method.name} is now ${val ? "active" : "disabled"} in POS',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: BANKS & E-WALLETS
  // ===========================================================================

  Widget _buildBanksTab(List<Bank> banks) {
    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${banks.length} Bank & E-Wallet Providers',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Add Bank / E-Wallet',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                onPressed: () {
                  FeedbackService.tap();
                  BankFormDialog.show(
                    context,
                    onSave: (bank) {
                      context.read<PaymentMaintenanceCubit>().saveBank(bank);
                      AppToast.showSuccess(context, message: 'Bank "${bank.name}" saved successfully');
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: banks.isEmpty
              ? _buildEmptyState('No banks or e-wallets added yet.\nTap "Add Bank / E-Wallet" above to create one.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: banks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final bank = banks[index];
                    return _buildBankCard(bank);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBankCard(Bank bank) {
    // 1 = Debit, 2 = Credit, 3 = E-Wallet
    String typeLabel = 'Debit Card';
    Color badgeBg = const Color(0xFFDBEAFE);
    Color badgeColor = const Color(0xFF1E40AF);
    IconData icon = Icons.credit_card_rounded;

    if (bank.cardType == 2) {
      typeLabel = 'Credit Card';
      badgeBg = const Color(0xFFF3E8FF);
      badgeColor = const Color(0xFF6B21A8);
      icon = Icons.credit_score_rounded;
    } else if (bank.cardType == 3) {
      typeLabel = 'E-Wallet / QR';
      badgeBg = const Color(0xFFD1FAE5);
      badgeColor = const Color(0xFF065F46);
      icon = Icons.qr_code_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: badgeColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bank.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        typeLabel,
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  bank.isActive ? 'Active in checkout' : 'Disabled',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: bank.isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
            tooltip: 'Edit',
            onPressed: () {
              FeedbackService.tap();
              BankFormDialog.show(
                context,
                bank: bank,
                onSave: (updated) {
                  context.read<PaymentMaintenanceCubit>().saveBank(updated);
                  AppToast.showSuccess(context, message: 'Bank "${updated.name}" updated');
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
            tooltip: 'Delete',
            onPressed: () {
              if (bank.id == null) return;
              showDialog(
                context: context,
                builder: (_) => ConfirmationDialog(
                  title: 'Delete Bank Provider',
                  message: 'Are you sure you want to delete "${bank.name}"?',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  onConfirm: () {
                    context.read<PaymentMaintenanceCubit>().deleteBank(bank.id!);
                    AppToast.showSuccess(context, message: 'Bank "${bank.name}" deleted');
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: CHARGE ACCOUNTS
  // ===========================================================================

  Widget _buildChargesTab(List<Charge> charges) {
    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${charges.length} Charge Accounts',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Add Charge Account',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                onPressed: () {
                  FeedbackService.tap();
                  ChargeFormDialog.show(
                    context,
                    onSave: (charge) {
                      context.read<PaymentMaintenanceCubit>().saveCharge(charge);
                      AppToast.showSuccess(context, message: 'Charge account "${charge.name}" saved');
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: charges.isEmpty
              ? _buildEmptyState('No charge accounts configured.\nTap "Add Charge Account" above to register clients.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: charges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final charge = charges[index];
                    return _buildChargeCard(charge);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChargeCard(Charge charge) {
    String typeLabel = 'Corporate / Client';
    Color badgeBg = const Color(0xFFEEF2FF);
    Color badgeColor = const Color(0xFF4F46E5);

    if (charge.chargeType == 2) {
      typeLabel = 'Staff / Employee';
      badgeBg = const Color(0xFFFEF3C7);
      badgeColor = const Color(0xFFD97706);
    } else if (charge.chargeType == 3) {
      typeLabel = 'VIP Account';
      badgeBg = const Color(0xFFFCE7F3);
      badgeColor = const Color(0xFFBE185D);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              charge.code,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      charge.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        typeLabel,
                        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  charge.isActive ? 'Active for charging' : 'Inactive',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: charge.isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
            tooltip: 'Edit',
            onPressed: () {
              FeedbackService.tap();
              ChargeFormDialog.show(
                context,
                charge: charge,
                onSave: (updated) {
                  context.read<PaymentMaintenanceCubit>().saveCharge(updated);
                  AppToast.showSuccess(context, message: 'Charge account "${updated.name}" updated');
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
            tooltip: 'Delete',
            onPressed: () {
              if (charge.id == null) return;
              showDialog(
                context: context,
                builder: (_) => ConfirmationDialog(
                  title: 'Delete Charge Account',
                  message: 'Are you sure you want to delete "${charge.name}"?',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  onConfirm: () {
                    context.read<PaymentMaintenanceCubit>().deleteCharge(charge.id!);
                    AppToast.showSuccess(context, message: 'Charge account "${charge.name}" deleted');
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
