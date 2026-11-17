import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/debug_seeder_service.dart';
import 'package:suki_pos/core/enums/enums.dart';
import 'package:suki_pos/core/services/feedback_service.dart';
import 'package:suki_pos/presentation/inventory/stock_cubit.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_bloc.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_event.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_event.dart';
import 'package:suki_pos/presentation/pos/widgets/confirmation_dialog.dart';
import 'package:suki_pos/presentation/widgets/app_toast.dart';
import 'package:suki_pos/presentation/widgets/app_unified_header.dart';
import 'package:suki_pos/presentation/widgets/main_layout.dart';
import 'package:suki_pos/services/store_settings_service.dart';

class StoreSettingsPage extends StatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends State<StoreSettingsPage> {
  static const Color primaryBlue = Color(0xFF355C8F);
  static const Color textDark = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _storeNameController;
  late final TextEditingController _branchNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _permitController;
  late final TextEditingController _headerController;
  late final TextEditingController _footerController;

  String _activeDbPath = 'Loading...';
  String? _lastBackupPath;
  bool _isSaving = false;
  bool _isBackingUp = false;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    final settings = StoreSettingsService.instance;
    _storeNameController = TextEditingController(text: settings.storeName);
    _branchNameController = TextEditingController(text: settings.branchName);
    _addressController = TextEditingController(text: settings.address);
    _taxIdController = TextEditingController(text: settings.taxId);
    _permitController = TextEditingController(text: settings.permitNumber);
    _headerController = TextEditingController(text: settings.receiptHeader);
    _footerController = TextEditingController(text: settings.receiptFooter);

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await StoreSettingsService.instance.loadFromDatabase();
    final dbPath = await DatabaseHelper().getDatabaseFilePath();
    if (!mounted) return;
    final s = StoreSettingsService.instance;
    setState(() {
      _activeDbPath = dbPath;
      _storeNameController.text = s.storeName;
      _branchNameController.text = s.branchName;
      _addressController.text = s.address;
      _taxIdController.text = s.taxId;
      _permitController.text = s.permitNumber;
      _headerController.text = s.receiptHeader;
      _footerController.text = s.receiptFooter;
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _branchNameController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _permitController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await StoreSettingsService.instance.saveStoreSettings(
        storeName: _storeNameController.text,
        branchName: _branchNameController.text,
        address: _addressController.text,
        taxId: _taxIdController.text,
        permitNumber: _permitController.text,
        receiptHeader: _headerController.text,
        receiptFooter: _footerController.text,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.showSuccess(
          context,
          title: 'Settings Saved',
          message: 'Store profile and receipt branding updated successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.showError(
          context,
          title: 'Save Failed',
          message: 'Could not save store settings: $e',
        );
      }
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String? chosenPath;
      try {
        chosenPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save SukiPOS Database Backup',
          fileName: 'suki_pos_backup_$timestamp.db',
          type: FileType.any,
        );
      } catch (_) {
        // Fallback to automatic local backups folder if native save dialog is unavailable
        chosenPath = null;
      }

      final savedPath = await DatabaseHelper().exportDatabaseBackup(
        destinationFilePath: chosenPath,
      );
      if (mounted) {
        setState(() {
          _isBackingUp = false;
          _lastBackupPath = savedPath;
        });
        AppToast.showSuccess(
          context,
          title: 'Database Backup Created',
          message: 'Saved backup to: $savedPath',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBackingUp = false);
        AppToast.showError(
          context,
          title: 'Backup Failed',
          message: 'Could not export database: $e',
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select SukiPOS Backup (.db) File',
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return;
      final selectedPath = result.files.single.path!;

      if (!mounted) return;
      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'Restore Database Backup?',
        message:
            'Restoring from "$selectedPath" will replace the current local database. Make sure you have exported a backup of your current data first.',
        confirmLabel: 'Restore Database',
        confirmColor: const Color(0xFFDC2626),
        variant: DialogVariant.danger,
      );

      if (confirmed != true || !mounted) return;

      await DatabaseHelper().restoreDatabaseBackup(selectedPath);
      await _loadInitialData();
      _reloadCatalogBlocs();

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Database Restored',
          message: 'Successfully restored database from backup.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Restore Failed',
          message: 'Could not restore database backup: $e',
        );
      }
    }
  }

  void _reloadCatalogBlocs() {
    if (!mounted) return;
    try {
      context.read<DepartmentBloc>().add(GetDepartmentsEvent());
      context.read<CategoryBloc>().add(GetCategoriesEvent());
      context.read<ItemBloc>().add(LoadItems());
      context.read<DiscountBloc>().add(GetDiscountsEvent());
      context.read<StockCubit>().loadStockList();
    } catch (_) {}
  }

  Future<void> _runSeedDemoCatalog() async {
    setState(() => _isSeeding = true);
    try {
      final summary = await DebugSeederService(DatabaseHelper()).seedDemoCatalog();
      _reloadCatalogBlocs();
      if (mounted) {
        setState(() => _isSeeding = false);
        AppToast.showSuccess(
          context,
          title: 'Demo Catalog Seeded',
          message:
              'Configured ${summary.departments} Depts, ${summary.categories} Categories, ${summary.items} Items, ${summary.discounts} Discounts, ${summary.stocks} Stocks, & ${summary.giftCheckSerials} GC Serials.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSeeding = false);
        AppToast.showError(
          context,
          title: 'Seeding Failed',
          message: 'Could not seed demo catalog: $e',
        );
      }
    }
  }

  Future<void> _runResetTransactionsAndReseed() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Reset All Transactions & Re-seed Demo State?',
      message:
          'This will clear all sales transactions, shifts, X/Z readings, and cash declarations, reset SI# and Z-Counter back to 0, restore all Gift Check serials, and re-seed fresh catalog & stock quantities.',
      confirmLabel: 'Reset & Re-seed Fresh State',
      confirmColor: const Color(0xFFDC2626),
      variant: DialogVariant.danger,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSeeding = true);
    try {
      final summary = await DebugSeederService(
        DatabaseHelper(),
      ).resetTransactionsAndReseed();
      _reloadCatalogBlocs();
      if (mounted) {
        setState(() => _isSeeding = false);
        AppToast.showSuccess(
          context,
          title: 'Fresh Demo State Ready',
          message:
              'Cleared all transactions/readings (SI# & Z-Read reset to 0) and seeded ${summary.items} Items & ${summary.stocks} Stocks.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSeeding = false);
        AppToast.showError(
          context,
          title: 'Reset & Seed Failed',
          message: 'Error resetting demo state: $e',
        );
      }
    }
  }

  Future<void> _runSeedSampleTransactions() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Seed Sample Shift & 5 QA Test Transactions?',
      message:
          'This will reset the database to a fresh demo state, open a ₱2,000.00 shift for Cashier Juan (PIN: 123456), and execute 5 test transactions (SI #1 Cash, SI #2 Senior Citizen + Card, SI #3 Recipe Ramen + Modifiers + VIP 10% + GCash, SI #4 Split Gift Check Excess + Cash, SI #5 Post-Voided) plus +₱300 / -₱100 Cash In/Out so you can immediately verify Transaction History and run X-Reading & Z-Reading.',
      confirmLabel: 'Seed Sample Shift & Transactions',
      confirmColor: primaryBlue,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSeeding = true);
    try {
      await DebugSeederService(
        DatabaseHelper(),
      ).seedSampleShiftAndTransactions();
      _reloadCatalogBlocs();
      if (mounted) {
        setState(() => _isSeeding = false);
        AppToast.showSuccess(
          context,
          title: 'Sample Shift & Transactions Seeded',
          message:
              'Created SI #1–#5 (Net Sales: ₱2,018.50, Expected Drawer Cash: ₱2,868.00) for Cashier Juan (PIN: 123456).',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSeeding = false);
        AppToast.showError(
          context,
          title: 'Sample Transaction Seed Failed',
          message: 'Could not seed sample transactions: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          FeedbackService.tap();
          Navigator.of(context).pushReplacementNamed('/admin');
        },
      },
      child: Focus(
        autofocus: true,
        child: MainLayout(
          currentTab: MainTab.inventory,
          mobileAppBar: const AppUnifiedHeader(
            title: 'Store & Backup Settings',
            parentHubTitle: 'Admin Hub',
            parentHubRoute: '/admin',
          ),
          desktopHeader: const AppUnifiedHeader(
            title: 'Store Profile, Receipt Branding & Database Backup',
            subtitle:
                'Configure BIR/Tax receipt headers and manage local SQLite database backups',
            parentHubTitle: 'Admin Hub',
            parentHubRoute: '/admin',
          ),
          mobileBody: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildContent(isDesktop: false),
          ),
          desktopBody: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: _buildContent(isDesktop: true),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({required bool isDesktop}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Store Identity & Receipt Header',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          Text(
                            'These details appear on all printed 80mm thermal receipts, X-Readings, and Z-Readings.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          label: 'Store / Company Name',
                          controller: _storeNameController,
                          hint: 'e.g., SUKIPOS STORE',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          label: 'Branch Name',
                          controller: _branchNameController,
                          hint: 'e.g., Main Branch',
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildField(
                    label: 'Store / Company Name',
                    controller: _storeNameController,
                    hint: 'e.g., SUKIPOS STORE',
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Branch Name',
                    controller: _branchNameController,
                    hint: 'e.g., Main Branch',
                  ),
                ],
                const SizedBox(height: 16),
                _buildField(
                  label: 'Store Address',
                  controller: _addressController,
                  hint: 'e.g., Quezon City, Metro Manila',
                ),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          label: 'Tax Identification Number (TIN)',
                          controller: _taxIdController,
                          hint: 'e.g., 000-123-456-00000 VAT',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField(
                          label: 'Permit / Accreditation Number',
                          controller: _permitController,
                          hint: 'e.g., FP-012026-0001',
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildField(
                    label: 'Tax Identification Number (TIN)',
                    controller: _taxIdController,
                    hint: 'e.g., 000-123-456-00000 VAT',
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Permit / Accreditation Number',
                    controller: _permitController,
                    hint: 'e.g., FP-012026-0001',
                  ),
                ],
                const SizedBox(height: 16),
                _buildField(
                  label: 'Receipt Subtitle / Header Line',
                  controller: _headerController,
                  hint: 'e.g., Official POS Terminal Receipt',
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'Receipt Footer Message',
                  controller: _footerController,
                  hint: 'e.g., *** THANK YOU & PLEASE COME AGAIN ***',
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: const Icon(
                      Icons.save_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Store Settings',
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storage_rounded,
                        color: Color(0xFF15803D),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Database Backup & Recovery',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          Text(
                            'Create a complete snapshot of products, stock levels, sales history, and shifts.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Database Location:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _activeDbPath,
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          color: textDark,
                        ),
                      ),
                      if (_lastBackupPath != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Last Exported Backup: $_lastBackupPath',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isBackingUp ? null : _exportBackup,
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isBackingUp
                            ? 'Exporting...'
                            : 'Export Database Backup',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _restoreBackup,
                      icon: const Icon(
                        Icons.restore_page_outlined,
                        size: 18,
                        color: Color(0xFFB91C1C),
                      ),
                      label: Text(
                        'Restore from Backup (.db)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.science_rounded,
                        color: Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developer / QA Debug Data Seeder',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          Text(
                            'Populate or reset realistic Departments, Categories, Items (VATable, VAT-Exempt, Discount-Exempt, Recipe/COGS, Modifiers), Discounts, Stocks, Banks, Gift Checks, and Test Cashiers.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick QA Verification Reference:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        '• Login PINs: Superuser = 050724 | Cashier Juan = 123456 | Cashier Maria = 654321\n'
                        '• Barcodes: 480001–480012 (480001 Tonkotsu Ramen w/ Recipe COGS & Modifiers | 480004 Crispy Katsudon ₱224 exact VAT test | 480009 Discount-Exempt | 480011 VAT-Exempt)\n'
                        '• Low-Stock Alert Items: Basque Cheesecake (4 left) & Chili Garlic Oil Jar (3 left)\n'
                        '• Gift Check Serials: GC-500-001 to GC-500-005 (₱500) | GC-1000-001 to GC-1000-003 (₱1,000)',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11.5,
                          height: 1.45,
                          color: const Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSeeding ? null : _runSeedDemoCatalog,
                      icon: const Icon(
                        Icons.auto_fix_high_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isSeeding
                            ? 'Seeding...'
                            : 'Seed / Top-Up Demo Catalog',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSeeding ? null : _runSeedSampleTransactions,
                      icon: const Icon(
                        Icons.playlist_add_check_circle_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Seed Sample Shift & 5 Test Transactions',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isSeeding
                          ? null
                          : _runResetTransactionsAndReseed,
                      icon: const Icon(
                        Icons.restart_alt_rounded,
                        size: 18,
                        color: Color(0xFFB91C1C),
                      ),
                      label: Text(
                        'Reset Transactions & Re-seed Fresh Demo State',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Required field' : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: surfaceBorder),
            ),
          ),
        ),
      ],
    );
  }
}
