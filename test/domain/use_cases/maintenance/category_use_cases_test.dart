import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/repositories/maintenance/category_repository.dart';
import 'package:suki_pos/domain/use_cases/maintenance/category_use_cases.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late GetCategories useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = GetCategories(mockRepository);
  });

  const tCategories = [
    Category(id: 1, departmentId: 1, name: 'Cat 1'),
  ];

  test('should get categories from the repository', () async {
    // arrange
    when(() => mockRepository.getCategories())
        .thenAnswer((_) async => const Right(tCategories));
    // act
    final result = await useCase(NoParams());
    // assert
    expect(result, const Right(tCategories));
    verify(() => mockRepository.getCategories()).called(1);
  });
}
