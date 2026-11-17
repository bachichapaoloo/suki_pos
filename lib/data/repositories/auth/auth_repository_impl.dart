import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/core/utils/crypto_utils.dart';
import 'package:suki_pos/data/models/admin/user_model.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';
import 'package:suki_pos/domain/repositories/auth/auth_repository.dart';

/// [DATA LAYER]
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.databaseHelper);
  final DatabaseHelper databaseHelper;

  @override
  Future<Either<Failure, User>> login(String pin) async {
    try {
      final db = await databaseHelper.database;
      final cleanPin = pin.trim();
      final hashedPin = CryptoUtils.hashPin(cleanPin);

      // Look for an active user matching either the SHA-256 hash or legacy plaintext PIN,
      // joined with their role permission matrix.
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT 
          u.*, 
          r.name AS role_name,
          r.can_sales_entry,
          r.can_sales_order,
          r.can_sales_reading,
          r.can_sales_inquiry,
          r.can_file_maintenance,
          r.can_admin_mode,
          r.can_inventory
        FROM app_user u
        JOIN role r ON u.role_id = r.id
        WHERE (u.password_hash = ? OR u.password_hash = ?) AND u.is_active = 1
        LIMIT 1
        ''',
        [hashedPin, cleanPin],
      );

      if (maps.isNotEmpty) {
        final row = maps.first;
        final storedHash = row['password_hash'] as String;

        // Auto-upgrade legacy plaintext PINs to SHA-256 in the background
        if (!CryptoUtils.isHashed(storedHash)) {
          await db.update(
            'app_user',
            {
              'password_hash': hashedPin,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }

        final user = UserModel.fromMap(row).copyWith(passwordHash: hashedPin);
        return Right(user);
      } else {
        return Left(NotFoundFailure());
      }
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> verifyManagerPin(String pin) async {
    try {
      final db = await databaseHelper.database;
      final cleanPin = pin.trim();
      final hashedPin = CryptoUtils.hashPin(cleanPin);

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT 
          u.*, 
          r.name AS role_name,
          r.can_sales_entry,
          r.can_sales_order,
          r.can_sales_reading,
          r.can_sales_inquiry,
          r.can_file_maintenance,
          r.can_admin_mode,
          r.can_inventory
        FROM app_user u
        JOIN role r ON u.role_id = r.id
        WHERE (u.password_hash = ? OR u.password_hash = ?)
          AND u.is_active = 1
          AND r.can_admin_mode = 1
        LIMIT 1
        ''',
        [hashedPin, cleanPin],
      );

      if (maps.isNotEmpty) {
        final row = maps.first;
        return Right(UserModel.fromMap(row));
      } else {
        return Left(NotFoundFailure());
      }
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
