import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/admin/user.dart';

/// [DOMAIN LAYER]
/// The AuthRepository handles credential verification.
abstract class AuthRepository {
  /// Verifies the user's PIN against the database.
  Future<Either<Failure, User>> login(String pin);
}
