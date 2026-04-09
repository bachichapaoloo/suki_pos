import 'package:equatable/equatable.dart';

/// [DOMAIN LAYER]
class User extends Equatable {
  const User({
    required this.id,
    required this.roleId,
    required this.name,
    required this.passwordHash,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.roleName, // Extra field for convenience in lists
  });

  final int id;
  final int roleId;
  final String name;
  final String passwordHash;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Non-persisted field for display
  final String? roleName;

  @override
  List<Object?> get props => [
    id,
    roleId,
    name,
    passwordHash,
    isActive,
    createdAt,
    updatedAt,
    roleName,
  ];

  User copyWith({
    int? id,
    int? roleId,
    String? name,
    String? passwordHash,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? roleName,
  }) {
    return User(
      id: id ?? this.id,
      roleId: roleId ?? this.roleId,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roleName: roleName ?? this.roleName,
    );
  }
}
