import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/database/schema_constants.dart';
import 'package:suki_pos/domain/entities/maintenance/bank.dart';

class BankDao {
  final DatabaseHelper _databaseHelper;

  BankDao(this._databaseHelper);

  Future<List<Bank>> getBanks() async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.bank,
      orderBy: 'id ASC',
    );

    return results.map(Bank.fromMap).toList();
  }

  Future<List<Bank>> getActiveBanks() async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      SchemaConstants.bank,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );

    return results.map(Bank.fromMap).toList();
  }

  Future<Bank?> getBankById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      SchemaConstants.bank,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Bank.fromMap(result.first);
    }

    return null;
  }

  Future<int> insertBank(Bank bank) async {
    final db = await _databaseHelper.database;
    return await db.insert(SchemaConstants.bank, bank.toMap());
  }

  Future<int> updateBank(Bank bank) async {
    final db = await _databaseHelper.database;
    return await db.update(
      SchemaConstants.bank,
      bank.toMap(),
      where: 'id = ?',
      whereArgs: [bank.id],
    );
  }

  Future<int> deleteBank(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      SchemaConstants.bank,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
