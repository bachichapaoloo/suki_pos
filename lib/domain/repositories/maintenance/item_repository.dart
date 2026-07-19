import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';

abstract class ItemRepository {
  Future<Either<Failure, List<Item>>> getItems();
  Future<Either<Failure, List<Item>>> getItemsByDepartment(int departmentId);
  Future<Either<Failure, Item?>> getItemById(int id);
  Future<Either<Failure, Item>> saveItem(Item item);
  Future<Either<Failure, void>> deleteItem(int id);
}
