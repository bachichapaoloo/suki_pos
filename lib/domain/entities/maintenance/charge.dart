class Charge {
  final int? id;
  final String code;
  final String name;
  final int? chargeType;
  final bool isActive;

  Charge({
    this.id,
    required this.code,
    required this.name,
    this.chargeType,
    this.isActive = true,
  });

  factory Charge.fromMap(Map<String, dynamic> map) {
    return Charge(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      chargeType: map['charge_type'] as int?,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  Charge copyWith({
    int? id,
    String? code,
    String? name,
    int? chargeType,
    bool? isActive,
  }) {
    return Charge(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      chargeType: chargeType ?? this.chargeType,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'charge_type': chargeType,
      'is_active': isActive ? 1 : 0,
    };
  }
}
