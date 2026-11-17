import 'package:shared_preferences/shared_preferences.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';

/// Manages dynamic store profile, BIR/Tax header fields, and receipt messages.
/// Backed by the SQLite `bir_config` table with an in-memory cache so synchronous
/// reads work anywhere in the UI or PDF receipt generator.
class StoreSettingsService {
  StoreSettingsService([this._prefs, DatabaseHelper? databaseHelper])
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  static final StoreSettingsService instance = StoreSettingsService();

  final SharedPreferences? _prefs;
  final DatabaseHelper _databaseHelper;

  static const String _keyStoreName = 'store_name';
  static const String _keyTaxId = 'tax_id';
  static const String _keyBranchName = 'branch_name';
  static const String _keyAddress = 'store_address';
  static const String _keyPermitNumber = 'permit_number';
  static const String _keyReceiptHeader = 'receipt_header';
  static const String _keyReceiptFooter = 'receipt_footer';

  String _storeName = 'SUKIPOS STORE';
  String _taxId = '000-123-456-00000 VAT';
  String _branchName = 'Main Branch';
  String _address = 'Quezon City, Metro Manila';
  String _permitNumber = 'FP-012026-0001';
  String _receiptHeader = 'Official POS Terminal Receipt';
  String _receiptFooter = '*** THANK YOU & PLEASE COME AGAIN ***';

  String get storeName => _prefs?.getString(_keyStoreName) ?? _storeName;
  String get taxId => _prefs?.getString(_keyTaxId) ?? _taxId;
  String get branchName => _prefs?.getString(_keyBranchName) ?? _branchName;
  String get address => _prefs?.getString(_keyAddress) ?? _address;
  String get permitNumber => _prefs?.getString(_keyPermitNumber) ?? _permitNumber;
  String get receiptHeader => _prefs?.getString(_keyReceiptHeader) ?? _receiptHeader;
  String get receiptFooter => _prefs?.getString(_keyReceiptFooter) ?? _receiptFooter;

  /// Loads persisted settings from the SQLite `bir_config` table into memory.
  Future<void> loadFromDatabase() async {
    try {
      final db = await _databaseHelper.database;
      final rows = await db.query(
        SchemaConstants.birConfig,
        orderBy: 'id ASC',
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final row = rows.first;
        _storeName = (row['company_name'] as String?)?.isNotEmpty == true
            ? row['company_name'] as String
            : _storeName;
        _branchName = (row['branch_name'] as String?)?.isNotEmpty == true
            ? row['branch_name'] as String
            : _branchName;
        _address = (row['address_line_1'] as String?)?.isNotEmpty == true
            ? row['address_line_1'] as String
            : _address;
        _taxId = (row['tin'] as String?)?.isNotEmpty == true
            ? row['tin'] as String
            : _taxId;
        _permitNumber = (row['permit_number'] as String?)?.isNotEmpty == true
            ? row['permit_number'] as String
            : _permitNumber;
        _receiptHeader = (row['address_line_2'] as String?)?.isNotEmpty == true
            ? row['address_line_2'] as String
            : _receiptHeader;
        _receiptFooter = (row['receipt_footer_1'] as String?)?.isNotEmpty == true
            ? row['receipt_footer_1'] as String
            : _receiptFooter;
      }
    } catch (_) {
      // Keep default values if DB is not yet open
    }
  }

  Future<void> saveStoreSettings({
    required String storeName,
    required String taxId,
    required String branchName,
    String? address,
    String? permitNumber,
    required String receiptHeader,
    required String receiptFooter,
  }) async {
    _storeName = storeName.trim().isEmpty ? 'SUKIPOS STORE' : storeName.trim();
    _taxId = taxId.trim().isEmpty ? '000-123-456-00000 VAT' : taxId.trim();
    _branchName = branchName.trim().isEmpty ? 'Main Branch' : branchName.trim();
    if (address != null && address.trim().isNotEmpty) {
      _address = address.trim();
    }
    if (permitNumber != null && permitNumber.trim().isNotEmpty) {
      _permitNumber = permitNumber.trim();
    }
    _receiptHeader = receiptHeader.trim().isEmpty
        ? 'Official POS Terminal Receipt'
        : receiptHeader.trim();
    _receiptFooter = receiptFooter.trim().isEmpty
        ? '*** THANK YOU & PLEASE COME AGAIN ***'
        : receiptFooter.trim();

    if (_prefs != null) {
      await _prefs.setString(_keyStoreName, _storeName);
      await _prefs.setString(_keyTaxId, _taxId);
      await _prefs.setString(_keyBranchName, _branchName);
      await _prefs.setString(_keyAddress, _address);
      await _prefs.setString(_keyPermitNumber, _permitNumber);
      await _prefs.setString(_keyReceiptHeader, _receiptHeader);
      await _prefs.setString(_keyReceiptFooter, _receiptFooter);
    }

    try {
      final db = await _databaseHelper.database;
      final existing = await db.query(SchemaConstants.birConfig, limit: 1);
      final payload = {
        'company_name': _storeName,
        'branch_name': _branchName,
        'address_line_1': _address,
        'address_line_2': _receiptHeader,
        'tin': _taxId,
        'permit_number': _permitNumber,
        'receipt_footer_1': _receiptFooter,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (existing.isEmpty) {
        await db.insert(SchemaConstants.birConfig, payload);
      } else {
        await db.update(
          SchemaConstants.birConfig,
          payload,
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
    } catch (_) {}
  }
}
