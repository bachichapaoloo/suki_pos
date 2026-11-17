import 'package:flutter_test/flutter_test.dart';
import 'package:suki_pos/services/store_settings_service.dart';

void main() {
  test('StoreSettingsService provides valid default store branding', () {
    final service = StoreSettingsService.instance;
    expect(service.storeName, isNotEmpty);
    expect(service.taxId, isNotEmpty);
    expect(service.branchName, isNotEmpty);
    expect(service.receiptHeader, isNotEmpty);
    expect(service.receiptFooter, isNotEmpty);
  });
}
