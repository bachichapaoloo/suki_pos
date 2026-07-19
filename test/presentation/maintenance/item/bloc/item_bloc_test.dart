import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/use_cases/maintenance/item_use_cases.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_event.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_state.dart';

class MockGetItems extends Mock implements GetItems {}
class MockSaveItem extends Mock implements SaveItem {}
class MockDeleteItem extends Mock implements DeleteItem {}

void main() {
  late ItemBloc bloc;
  late MockGetItems mockGetItems;
  late MockSaveItem mockSaveItem;
  late MockDeleteItem mockDeleteItem;

  setUpAll(() {
    registerFallbackValue(Item(
      itemCode: 'fallback',
      name: 'fallback',
      printName: 'fallback',
      categoryId: 1,
      departmentId: 1,
      costPrice: 0.0,
    ));
  });

  setUp(() {
    mockGetItems = MockGetItems();
    mockSaveItem = MockSaveItem();
    mockDeleteItem = MockDeleteItem();
    bloc = ItemBloc(
      getItems: mockGetItems,
      saveItem: mockSaveItem,
      deleteItem: mockDeleteItem,
    );
  });

  const tItems = [
    Item(
      id: 1,
      itemCode: 'I1',
      name: 'Item 1',
      printName: 'Item 1',
      categoryId: 1,
      departmentId: 1,
      costPrice: 0.0,
    ),
  ];

  test('initial state should be ItemInitial', () {
    expect(bloc.state, equals(ItemInitial()));
  });

  blocTest<ItemBloc, ItemState>(
    'should emit [ItemLoading, ItemLoaded] when data is gotten successfully',
    build: () {
      when(() => mockGetItems())
          .thenAnswer((_) async => const Right(tItems));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadItems()),
    expect: () => [
      ItemLoading(),
      const ItemLoaded(tItems),
    ],
  );
}

