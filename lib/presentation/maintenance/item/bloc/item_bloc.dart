import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:suki_pos/domain/use_cases/maintenance/item_use_cases.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_event.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_state.dart';

class ItemBloc extends Bloc<ItemEvent, ItemState> {
  final GetItems getItems;
  final SaveItem saveItem;
  final DeleteItem deleteItem;

  ItemBloc({
    required this.getItems,
    required this.saveItem,
    required this.deleteItem,
  }) : super(ItemInitial()) {
    on<LoadItems>(_onLoadItems);
    on<SaveItemEvent>(_onSaveItem);
    on<DeleteItemEvent>(_onDeleteItem);
  }

  Future<void> _onLoadItems(LoadItems event, Emitter<ItemState> emit) async {
    emit(ItemLoading());
    final result = await getItems();
    result.fold(
      (failure) => emit(const ItemError('Failed to load items')),
      (items) => emit(ItemLoaded(items)),
    );
  }

  Future<void> _onSaveItem(SaveItemEvent event, Emitter<ItemState> emit) async {
    emit(ItemLoading());
    final result = await saveItem(event.item);
    result.fold(
      (failure) => emit(const ItemError('Failed to save item')),
      (_) {
        emit(const ItemActionSuccess('Item saved successfully.'));
        add(LoadItems()); // Reload the list after saving
      },
    );
  }

  Future<void> _onDeleteItem(DeleteItemEvent event, Emitter<ItemState> emit) async {
    emit(ItemLoading());
    final result = await deleteItem(event.id);
    result.fold(
      (failure) => emit(const ItemError('Failed to delete item')),
      (_) {
        emit(const ItemActionSuccess('Item deleted successfully.'));
        add(LoadItems()); // Reload the list after deleting
      },
    );
  }
}

