import 'package:sqflite/sqflite.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/data/models/maintenance/option_group_model.dart';
import 'package:suki_pos/data/models/maintenance/option_value_model.dart';

class OptionGroupDao {
  final DatabaseHelper _databaseHelper;

  OptionGroupDao(this._databaseHelper);

  Future<List<OptionGroupModel>> getAllOptionGroups() async {
    final db = await _databaseHelper.database;

    final groupMaps = await db.query(SchemaConstants.optionGroup, orderBy: 'display_order ASC, name ASC');
    final valueMaps = await db.query(SchemaConstants.optionValue, orderBy: 'display_order ASC');

    final Map<int, List<Map<String, dynamic>>> valuesByGroup = {};
    for (var val in valueMaps) {
      final groupId = val['option_group_id'] as int;
      valuesByGroup.putIfAbsent(groupId, () => []).add(val);
    }

    return groupMaps.map((groupMap) {
      final groupId = groupMap['id'] as int;
      return OptionGroupModel.fromRelationalMaps(
        groupMap: groupMap,
        valueMaps: valuesByGroup[groupId] ?? [],
      );
    }).toList();
  }

  /// Saves OptionGroup and its OptionValues inside a single SQLite transaction
  Future<int> saveOptionGroupAggregate(OptionGroupModel groupModel) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      int groupId;
      final isNew = groupModel.id == null || groupModel.id == 0;

      if (isNew) {
        final insertMap = groupModel.toMasterMap();
        insertMap['created_at'] = DateTime.now().toIso8601String();
        groupId = await txn.insert(SchemaConstants.optionGroup, insertMap);
      } else {
        groupId = groupModel.id!;
        await txn.update(
          SchemaConstants.optionGroup,
          groupModel.toMasterMap(),
          where: 'id = ?',
          whereArgs: [groupId],
        );
        await txn.delete(
          SchemaConstants.optionValue,
          where: 'option_group_id = ?',
          whereArgs: [groupId],
        );
      }

      final batch = txn.batch();
      for (final val in groupModel.values) {
        final valueModel = OptionValueModel(
          id: val.id,
          optionGroupId: groupId,
          itemId: val.itemId,
          alias: val.alias,
          priceDelta: val.priceDelta,
          costPriceDelta: val.costPriceDelta,
          quantity: val.quantity,
          unitId: val.unitId,
          displayOrder: val.displayOrder,
        );
        batch.insert(SchemaConstants.optionValue, valueModel.toMap(groupId));
      }

      await batch.commit(noResult: true);
      return groupId;
    });
  }

  /// Assigns an Option Group to an Item in item_option_group junction table
  Future<void> assignOptionGroupToItem(int itemId, int optionGroupId, {int displayOrder = 0}) async {
    final db = await _databaseHelper.database;
    await db.insert(
      SchemaConstants.itemOptionGroup,
      {
        'item_id': itemId,
        'option_group_id': optionGroupId,
        'display_order': displayOrder,
        'is_override': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Unassigns an Option Group from an Item
  Future<void> removeOptionGroupFromItem(int itemId, int optionGroupId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      SchemaConstants.itemOptionGroup,
      where: 'item_id = ? AND option_group_id = ?',
      whereArgs: [itemId, optionGroupId],
    );
  }
}
