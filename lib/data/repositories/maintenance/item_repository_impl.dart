import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/item_dao.dart';
import 'package:suki_pos/data/models/maintenance/item_model.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/repositories/maintenance/item_repository.dart';

class ItemRepositoryImpl implements ItemRepository {
  final ItemDao itemDao;

  ItemRepositoryImpl({required this.itemDao});

  Future<Either<Failure, List<Item>>> getItems() async {
    try {
      final items = await itemDao.getAllItems();
      return Right(items);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Item>> saveItem(Item item) async {
    try {
      final itemModel = ItemModel(
        id: item.id,
        itemCode: item.itemCode,
        name: item.name,
        printName: item.printName,
        categoryId: item.categoryId,
        departmentId: item.departmentId,
        costPrice: item.costPrice,
        isActive: item.isActive,
        prices: item.prices,
      );

      final newId = await itemDao.saveItemAggregate(itemModel);

      // Return the item with its newly assigned SQLite ID
      return Right(
        ItemModel(
          id: newId,
          itemCode: item.itemCode,
          name: item.name,
          printName: item.printName,
          categoryId: item.categoryId,
          departmentId: item.departmentId,
          costPrice: item.costPrice,
          isActive: item.isActive,
          prices: item.prices,
        ),
      );
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem(int id) async {
    try {
      await itemDao.deleteItem(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Item?> getItemById(int id) async {
    try {
      final items = await itemDao.getAllItems();
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Item>> getItemsByDepartment(int departmentId) async {
    try {
      final items = await itemDao.getAllItems();
      return items.where((item) => item.departmentId == departmentId).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
