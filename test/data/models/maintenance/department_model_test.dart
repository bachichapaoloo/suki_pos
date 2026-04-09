import 'package:flutter_test/flutter_test.dart';
import 'package:suki_pos/data/models/maintenance/department_model.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';

void main() {
  const tDepartmentModel = DepartmentModel(
    id: 1,
    code: 'DEPT01',
    name: 'Beverages',
    isActive: true,
  );

  group('DepartmentModel', () {
    test('should be a subclass of Department entity', () {
      expect(tDepartmentModel, isA<Department>());
    });

    test('fromMap should return a valid model', () {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'code': 'DEPT01',
        'name': 'Beverages',
        'is_active': 1,
        'created_at': null,
        'updated_at': null,
      };
      // act
      final result = DepartmentModel.fromMap(jsonMap);
      // assert
      expect(result, tDepartmentModel);
    });

    test('toMap should return a JSON map containing proper data', () {
      // act
      final result = tDepartmentModel.toMap();
      // assert
      final expectedMap = {
        'id': 1,
        'code': 'DEPT01',
        'name': 'Beverages',
        'is_active': 1,
      };
      expect(result, expectedMap);
    });
  });
}
