class Bank {
  final int? id;
  final String name;
  final int? cardType;
  final bool isActive;

  Bank({
    this.id,
    required this.name,
    this.cardType,
    this.isActive = true,
  });

  factory Bank.fromMap(Map<String, dynamic> map) {
    return Bank(
      id: map['id'] as int?,
      name: map['name'] as String,
      cardType: map['card_type'] as int?,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  Bank copyWith({
    int? id,
    String? name,
    int? cardType,
    bool? isActive,
  }) {
    return Bank(
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
