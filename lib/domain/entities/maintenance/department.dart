import 'package:equatable/equatable.dart';

/// Represents a business department.
class Department extends Equatable {
  /// Creates a [Department].
  const Department({
    required this.id,
    required this.code,
    required this.name,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier.
  final int id;

  /// Business code for the department.
  final String code;

  /// Name of the department.
  final String name;

  /// Whether the department is active.
  final bool isActive;

  /// Timestamp of creation.
  final DateTime? createdAt;

  /// Timestamp of last update.
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, code, name, isActive, createdAt, updatedAt];

  /// Creates a copy of this [Department] with the given fields replaced.
  Department copyWith({
    int? id,
    String? code,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Department(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
