import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/product.dart';
import 'package:suki_pos/domain/repositories/maintenance/product_repository.dart';
import 'package:suki_pos/domain/use_cases/maintenance/product_use_cases.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetProducts useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProducts(mockRepository);
  });

  const tProducts = [
    Product(
      id: 1,
      itemCode: 'I1',
      name: 'Item 1',
      printName: 'Item 1',
      categoryId: 1,
      departmentId: 1,
    ),
  ];

  test('should get products from the repository', () async {
    // arrange
    when(() => mockRepository.getProducts())
        .thenAnswer((_) async => const Right(tProducts));
    // act
    final result = await useCase(NoParams());
    // assert
    expect(result, const Right(tProducts));
    verify(() => mockRepository.getProducts()).called(1);
  });
}
