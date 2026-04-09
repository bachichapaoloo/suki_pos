import 'package:flutter_test/flutter_test.dart';
import 'package:suki_pos/data/models/maintenance/product_model.dart';
import 'package:suki_pos/domain/entities/maintenance/product.dart';

void main() {
  const tProductModel = ProductModel(
    id: 1,
    itemCode: 'ITEM01',
    name: 'Coke 330ml',
    printName: 'Coke 330ml',
    categoryId: 1,
    departmentId: 1,
    costPrice: 25.0,
    isActive: true,
  );

  group('ProductModel', () {
    test('should be a subclass of Product entity', () {
      expect(tProductModel, isA<Product>());
    });

    test('fromMap should return a valid model', () {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'barcode': null,
        'item_code': 'ITEM01',
        'name': 'Coke 330ml',
        'print_name': 'Coke 330ml',
        'label_name': null,
        'item_details': null,
        'is_label_same_as_receipt': 1,
        'category_id': 1,
        'department_id': 1,
        'unit_id': null,
        'cost_price': 25.0,
        'markup_percentage': null,
        'conversion_qty': 1.0,
        'assigned_printer': null,
        'display_image': null,
        'button_index': null,
        'min_stock_level': 0.0,
        'max_stock_level': 0.0,
        'is_discount_exempt': 0,
        'is_vat_exempt': 0,
        'is_combo': 0,
        'is_finished_good': 0,
        'is_composition': 0,
        'is_raw_material': 0,
        'is_gift_check': 0,
        'gift_check_id': null,
        'disc_cap_amount': 0.0,
        'disc_cap_percentage': 0.0,
        'is_active': 1,
        'created_at': null,
        'updated_at': null,
      };
      // act
      final result = ProductModel.fromMap(jsonMap);
      // assert
      expect(result, tProductModel);
    });

    test('toMap should return a JSON map containing proper data', () {
      // act
      final result = tProductModel.toMap();
      // assert
      final Map<String, dynamic> expectedMap = {
        'id': 1,
        'barcode': null,
        'item_code': 'ITEM01',
        'name': 'Coke 330ml',
        'print_name': 'Coke 330ml',
        'label_name': null,
        'item_details': null,
        'is_label_same_as_receipt': 1,
        'category_id': 1,
        'department_id': 1,
        'unit_id': null,
        'cost_price': 25.0,
        'markup_percentage': null,
        'conversion_qty': 1.0,
        'assigned_printer': null,
        'display_image': null,
        'button_index': null,
        'min_stock_level': 0.0,
        'max_stock_level': 0.0,
        'is_discount_exempt': 0,
        'is_vat_exempt': 0,
        'is_combo': 0,
        'is_finished_good': 0,
        'is_composition': 0,
        'is_raw_material': 0,
        'is_gift_check': 0,
        'gift_check_id': null,
        'disc_cap_amount': 0.0,
        'disc_cap_percentage': 0.0,
        'is_active': 1,
      };
      expect(result, expectedMap);
    });
  });
}
