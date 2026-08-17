import 'package:equatable/equatable.dart';

/// Represents a configured discount rule.
class Discount extends Equatable {
  const Discount({
    this.id,
    required this.discountTypeId,
    this.discountTypeCode,
    this.discountTypeName,
    required this.name,
    this.percentage,
    this.fixedAmount,
    this.capAmount,
    this.capPercentage,
    this.limitExpr,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });
  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      id: map['id'] as int?,
      discountTypeId: map['discount_type_id'] as int,
      discountTypeCode: map['discount_type_code'] as String?,
      discountTypeName: map['discount_type_name'] as String?,
      name: map['name'] as String,
      percentage: (map['percentage'] as num?)?.toDouble(),
      fixedAmount: (map['fixed_amount'] as num?)?.toDouble(),
      capAmount: (map['cap_amount'] as num?)?.toDouble(),
      capPercentage: (map['cap_percentage'] as num?)?.toDouble(),
      limitExpr: map['limit_expr'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }
  final int? id;
  final int discountTypeId;
  final String? discountTypeCode; // Joined from discount_type.code
  final String? discountTypeName; // Joined from discount_type.name
  final String name;
  final double? percentage;
  final double? fixedAmount;
  final double? capAmount;
  final double? capPercentage;
  final String? limitExpr;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// True if this discount is a percentage-based discount.
  bool get isPercentage => (percentage ?? 0) > 0;

  /// True if this discount is a special statutory/government discount (e.g. Senior, PWD).
  bool get isSpecialVatExempt =>
      discountTypeCode == 'senior' ||
      discountTypeCode == 'pwd' ||
      discountTypeCode == 'solo_parent' ||
      discountTypeCode == 'athlete';

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'discount_type_id': discountTypeId,
      'name': name,
      'percentage': percentage,
      'fixed_amount': fixedAmount,
      'cap_amount': capAmount,
      'cap_percentage': capPercentage,
      'limit_expr': limitExpr,
      'is_active': isActive ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  Discount copyWith({
    int? id,
    int? discountTypeId,
    String? discountTypeCode,
    String? discountTypeName,
    String? name,
    double? percentage,
    double? fixedAmount,
    double? capAmount,
    double? capPercentage,
    String? limitExpr,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Discount(
      id: id ?? this.id,
      discountTypeId: discountTypeId ?? this.discountTypeId,
      discountTypeCode: discountTypeCode ?? this.discountTypeCode,
      discountTypeName: discountTypeName ?? this.discountTypeName,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      capAmount: capAmount ?? this.capAmount,
      capPercentage: capPercentage ?? this.capPercentage,
      limitExpr: limitExpr ?? this.limitExpr,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    discountTypeId,
    discountTypeCode,
    discountTypeName,
    name,
    percentage,
    fixedAmount,
    capAmount,
    capPercentage,
    limitExpr,
    isActive,
    createdAt,
    updatedAt,
  ];
}
