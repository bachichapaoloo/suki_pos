import 'package:flutter_test/flutter_test.dart';
import 'package:suki_pos/data/models/maintenance/category_model.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';

void main() {
  const tCategoryModel = CategoryModel(
    id: 1,
    departmentId: 1,
    name: 'Soft Drinks',
    code: 'CAT01',
    displayOrder: 1,
    isActive: true,
  );

  group('CategoryModel', () {
    test('should be a subclass of Category entity', () {
      expect(tCategoryModel, isA<Category>());
    });

    test('fromMap should return a valid model', () {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'department_id': 1,
        'name': 'Soft Drinks',
        'code': 'CAT01',
        'display_order': 1,
        'is_available_online': 1,
        'recommended_category_id': null,
        'is_active': 1,
        'created_at': null,
        'updated_at': null,
      };
      // act
      final result = CategoryModel.fromMap(jsonMap);
      // assert
      expect(result, tCategoryModel);
    });

    test('toMap should return a JSON map containing proper data', () {
      // act
      final result = tCategoryModel.toMap();
      // assert
      final expectedMap = {
        'id': 1,
        'department_id': 1,
        'name': 'Soft Drinks',
        'code': 'CAT01',
        'display_order': 1,
        'is_available_online': 1,
        'recommended_category_id': null,
        'is_active': 1,
      };
      expect(result, expectedMap);
    });
  });
}
