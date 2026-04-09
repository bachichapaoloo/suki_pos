import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/use_cases/maintenance/category_use_cases.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';

class MockGetCategories extends Mock implements GetCategories {}
class MockSaveCategory extends Mock implements SaveCategory {}
class MockDeleteCategory extends Mock implements DeleteCategory {}

void main() {
  late CategoryBloc bloc;
  late MockGetCategories mockGetCategories;
  late MockSaveCategory mockSaveCategory;
  late MockDeleteCategory mockDeleteCategory;

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockGetCategories = MockGetCategories();
    mockSaveCategory = MockSaveCategory();
    mockDeleteCategory = MockDeleteCategory();
    bloc = CategoryBloc(
      getCategories: mockGetCategories,
      saveCategory: mockSaveCategory,
      deleteCategory: mockDeleteCategory,
    );
  });

  const tCategories = [
    Category(id: 1, departmentId: 1, name: 'Cat 1'),
  ];

  test('initial state should be CategoryInitial', () {
    expect(bloc.state, equals(CategoryInitial()));
  });

  blocTest<CategoryBloc, CategoryState>(
    'should emit [CategoryLoading, CategoryLoaded] when data is gotten successfully',
    build: () {
      when(() => mockGetCategories(any()))
          .thenAnswer((_) async => const Right(tCategories));
      return bloc;
    },
    act: (bloc) => bloc.add(GetCategoriesEvent()),
    expect: () => [
      CategoryLoading(),
      const CategoryLoaded(tCategories),
    ],
  );
}
