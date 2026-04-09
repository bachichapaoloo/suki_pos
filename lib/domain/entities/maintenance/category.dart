import 'package:equatable/equatable.dart';

/// Represents a product category.
class Category extends Equatable {
  /// Creates a [Category].
  const Category({
    required this.id,
    required this.departmentId,
    required this.name,
    this.code,
    this.displayOrder = 0,
    this.isAvailableOnline = true,
    this.recommendedCategoryId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier.
  final int id;

  /// Reference to the parent department.
  final int departmentId;

  /// Business code for the category.
  final String? code;

  /// Name of the category.
  final String name;

  /// Order in which the category is displayed.
  final int displayOrder;

  /// Whether the category is available for online orders.
  final bool isAvailableOnline;

  /// Optional reference to a recommended category.
  final int? recommendedCategoryId;

  /// Whether the category is active.
  final bool isActive;

  /// Timestamp of creation.
  final DateTime? createdAt;

  /// Timestamp of last update.
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    departmentId,
    code,
    name,
    displayOrder,
    isAvailableOnline,
    recommendedCategoryId,
    isActive,
    createdAt,
    updatedAt,
  ];

  /// Creates a copy of this [Category] with the given fields replaced.
  Category copyWith({
    int? id,
    int? departmentId,
    String? code,
    String? name,
    int? displayOrder,
    bool? isAvailableOnline,
    int? recommendedCategoryId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      code: code ?? this.code,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
      isAvailableOnline: isAvailableOnline ?? this.isAvailableOnline,
      recommendedCategoryId:
          recommendedCategoryId ?? this.recommendedCategoryId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
