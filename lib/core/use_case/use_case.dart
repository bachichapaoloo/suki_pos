import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';

/// Base class for all use cases in the application.
/// [Type] is the return type of the use case.
/// [Params] is the parameter type for the use case.
abstract class UseCase<Type, Params> {
  /// Executes the use case.
  Future<Either<Failure, Type>> call(Params params);
}

/// Class used when a use case does not require any parameters.
class NoParams {}
