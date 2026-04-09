import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/department.dart';
import 'package:suki_pos/domain/repositories/maintenance/department_repository.dart';
import 'package:suki_pos/domain/use_cases/maintenance/get_departments.dart';

class MockDepartmentRepository extends Mock implements DepartmentRepository {}

void main() {
  late GetDepartments useCase;
  late MockDepartmentRepository mockRepository;

  setUp(() {
    mockRepository = MockDepartmentRepository();
    useCase = GetDepartments(mockRepository);
  });

  const tDepartments = [
    Department(id: 1, code: 'D1', name: 'Dept 1'),
    Department(id: 2, code: 'D2', name: 'Dept 2'),
  ];

  test('should get departments from the repository', () async {
    // arrange
    when(() => mockRepository.getDepartments())
        .thenAnswer((_) async => const Right(tDepartments));
    // act
    final result = await useCase(NoParams());
    // assert
    expect(result, const Right(tDepartments));
    verify(() => mockRepository.getDepartments()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
