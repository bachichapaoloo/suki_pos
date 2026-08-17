import 'package:equatable/equatable.dart';

/// Represents a discount classification (e.g., Senior, PWD, Employee, VIP).
class DiscountType extends Equatable {
  const DiscountType({
    required this.id,
    required this.code,
    required this.name,
    this.isActive = true,
  });

  factory DiscountType.fromMap(Map<String, dynamic> map) {
    return DiscountType(
      id: map['id'] as int,
      code: map['code'] as String,
      name: map['name'] as String,
      isActive: (map['is_active'] as int?) == 1,
    );
  }
  final int id;
  final String code;
  final String name;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'is_active': isActive ? 1 : 0,
    };
  }

  DiscountType copyWith({
    int? id,
    String? code,
    String? name,
    bool? isActive,
  }) {
    return DiscountType(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, code, name, isActive];
}
