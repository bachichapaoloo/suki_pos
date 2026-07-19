import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../entities/maintenance/item.dart';
import '../../repositories/maintenance/item_repository.dart';

class GetItems {
  final ItemRepository repository;
  GetItems(this.repository);

  Future<Either<Failure, List<Item>>> call() {
    return repository.getItems();
  }
}

class SaveItem {
  final ItemRepository repository;
  SaveItem(this.repository);

  Future<Either<Failure, Item>> call(Item item) async {
    return repository.saveItem(item);
  }
}

class DeleteItem {
  final ItemRepository repository;
  DeleteItem(this.repository);

  Future<Either<Failure, void>> call(int id) async {
    return repository.deleteItem(id);
  }
}
