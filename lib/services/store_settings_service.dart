import 'package:shared_preferences/shared_preferences.dart';

class StoreSettingsService {
  StoreSettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyStoreName = 'store_name';
  static const String _keyTaxId = 'tax_id';
  static const String _keyBranchName = 'branch_name';
  static const String _keyReceiptHeader = 'receipt_header';
  static const String _keyReceiptFooter = 'receipt_footer';

  String get storeName => _prefs.getString(_keyStoreName) ?? 'SukiPOS Store';
  String get taxId => _prefs.getString(_keyTaxId) ?? '000-000-000-000';
  String get branchName => _prefs.getString(_keyBranchName) ?? 'Main Branch';
  String get receiptHeader => _prefs.getString(_keyReceiptHeader) ?? 'Welcome to SukiPOS!';
  String get receiptFooter => _prefs.getString(_keyReceiptFooter) ?? 'Thank you for your business!';

  Future<void> saveStoreSettings({
    required String storeName,
    required String taxId,
    required String branchName,
    required String receiptHeader,
    required String receiptFooter,
  }) async {
    await _prefs.setString(_keyStoreName, storeName);
    await _prefs.setString(_keyTaxId, taxId);
    await _prefs.setString(_keyBranchName, branchName);
    await _prefs.setString(_keyReceiptHeader, receiptHeader);
    await _prefs.setString(_keyReceiptFooter, receiptFooter);
  }
}
