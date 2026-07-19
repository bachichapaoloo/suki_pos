import 'package:equatable/equatable.dart';
import '../../../../domain/entities/maintenance/item.dart';

abstract class ItemEvent extends Equatable {
  const ItemEvent();

  @override
  List<Object> get props => [];
}

class LoadItems extends ItemEvent {}

class SaveItemEvent extends ItemEvent {
  final Item item;
  const SaveItemEvent(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteItemEvent extends ItemEvent {
  final int id;
  const DeleteItemEvent(this.id);

  @override
  List<Object> get props => [id];
}

