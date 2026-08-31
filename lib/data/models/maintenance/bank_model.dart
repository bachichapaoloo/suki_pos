class BankModel {
  final int? id;
  final String name;
  final int? cardType;
  final bool isActive;

  BankModel({
    this.id,
    required this.name,
    this.cardType,
    this.isActive = true,
  });

  factory BankModel.fromMap(Map<String, dynamic> map) {
    return BankModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      cardType: map['card_type'] as int?,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  BankModel copyWith({
    int? id,
    String? name,
    int? cardType,
    bool? isActive,
  }) {
    return BankModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cardType: cardType ?? this.cardType,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'card_type': cardType,
      'is_active': isActive ? 1 : 0,
    };
  }
}
