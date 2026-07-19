import 'package:suki_pos/domain/entities/maintenance/item_price.dart';

class ItemPriceModel extends ItemPrice {
  const ItemPriceModel({
    super.id,
    required super.priceLevel,
    required super.price,
  });

  factory ItemPriceModel.fromMap(Map<String, dynamic> map) {
    return ItemPriceModel(
      id: map['id'] as int?,
      priceLevel: map['price_level'] as String? ?? 'default',
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap(int itemId) {
    return {
      'item_id': itemId,
      'price_level': priceLevel,
      'price': price,
    };
  }
}
