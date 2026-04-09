import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
abstract class Failure extends Equatable {
  /// Creates a [Failure].
  const Failure([this.properties = const <dynamic>[]]);

  /// Properties of the failure.
  final List<dynamic> properties;

  @override
  List<dynamic> get props => properties;
}

/// Generic database failure.
class DatabaseFailure extends Failure {
  /// Creates a [DatabaseFailure].
  const DatabaseFailure(this.message) : super();

  /// The error message.
  final String message;
}

/// Failure occurring when an item is not found.
class NotFoundFailure extends Failure {}
