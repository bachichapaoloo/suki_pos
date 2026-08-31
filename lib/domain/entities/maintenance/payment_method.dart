class PaymentMethod {
  final int? id;
  final String code;
  final String name;
  final bool isActive;

  PaymentMethod({
    this.id,
    required this.code,
    required this.name,
    this.isActive = true,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  PaymentMethod copyWith({
    int? id,
    String? code,
    String? name,
    bool? isActive,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'is_active': isActive ? 1 : 0,
    };
  }
}
