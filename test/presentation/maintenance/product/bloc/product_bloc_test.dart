import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/product.dart';
import 'package:suki_pos/domain/use_cases/maintenance/product_use_cases.dart';
import 'package:suki_pos/presentation/maintenance/product/bloc/product_bloc.dart';

class MockGetProducts extends Mock implements GetProducts {}
class MockSaveProduct extends Mock implements SaveProduct {}
class MockDeleteProduct extends Mock implements DeleteProduct {}

void main() {
  late ProductBloc bloc;
  late MockGetProducts mockGetProducts;
  late MockSaveProduct mockSaveProduct;
  late MockDeleteProduct mockDeleteProduct;

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockGetProducts = MockGetProducts();
    mockSaveProduct = MockSaveProduct();
    mockDeleteProduct = MockDeleteProduct();
    bloc = ProductBloc(
      getProducts: mockGetProducts,
      saveProduct: mockSaveProduct,
      deleteProduct: mockDeleteProduct,
    );
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

  test('initial state should be ProductInitial', () {
    expect(bloc.state, equals(ProductInitial()));
  });

  blocTest<ProductBloc, ProductState>(
    'should emit [ProductLoading, ProductLoaded] when data is gotten successfully',
    build: () {
      when(() => mockGetProducts(any()))
          .thenAnswer((_) async => const Right(tProducts));
      return bloc;
    },
    act: (bloc) => bloc.add(GetProductsEvent()),
    expect: () => [
      ProductLoading(),
      const ProductLoaded(tProducts),
    ],
  );
}
