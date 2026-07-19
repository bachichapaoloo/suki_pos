import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schena_constants.dart';
import 'package:suki_pos/data/models/maintenance/item_model.dart';
import 'package:suki_pos/data/models/maintenance/item_price_model.dart';

class ItemDao {
  final DatabaseHelper _databaseHelper;

  ItemDao(this._databaseHelper);

  /// Retrieves all items and maps their respective prices in memory.
  /// Doing two distinct queries is extremely fast in SQLite and avoids
  /// messy JOIN grouping logic in Dart.
  Future<List<ItemModel>> getAllItems() async {
    final db = await _databaseHelper.database;

    final itemMaps = await db.query(SchemaConstants.item);
    final priceMaps = await db.query(SchemaConstants.itemPrice);

    // Group prices by item_id for O(1) lookup
    final Map<int, List<Map<String, dynamic>>> pricesByItem = {};
    for (var price in priceMaps) {
      final itemId = price['item_id'] as int;
      pricesByItem.putIfAbsent(itemId, () => []).add(price);
    }

    return itemMaps.map((itemMap) {
      final itemId = itemMap['id'] as int;
      return ItemModel.fromRelationalMaps(
        itemMap: itemMap,
        priceMaps: pricesByItem[itemId] ?? [],
      );
    }).toList();
  }

  /// Atomically saves the Item and its Prices.
  Future<int> saveItemAggregate(ItemModel itemModel) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      int itemId;

      // 1. Upsert the Master Item Record
      if (itemModel.id == null || itemModel.id == 0) {
        final insertMap = itemModel.toMasterTableMap();
        insertMap['created_at'] = DateTime.now().toIso8601String();
        itemId = await txn.insert(SchemaConstants.item, insertMap);
      } else {
        itemId = itemModel.id!;
        await txn.update(
          SchemaConstants.item,
          itemModel.toMasterTableMap(),
          where: 'id = ?',
          whereArgs: [itemId],
        );

        // Wipe existing prices to perform a clean overwrite
        await txn.delete(
          SchemaConstants.itemPrice,
          where: 'item_id = ?',
          whereArgs: [itemId],
        );
      }

      // 2. Batch Insert the Prices
      final batch = txn.batch();
      for (final price in itemModel.prices) {
        final priceModel = ItemPriceModel(
          id: price.id,
          priceLevel: price.priceLevel,
          price: price.price,
        );
        batch.insert(SchemaConstants.itemPrice, priceModel.toMap(itemId));
      }

      await batch.commit(noResult: true);
      return itemId;
    });
  }

  Future<int> deleteItem(int id) async {
    final db = await _databaseHelper.database;
    // Because of ON DELETE CASCADE in the v2 schema, deleting the item
    // will automatically delete its related item_price rows.
    return await db.delete(
      SchemaConstants.item,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
