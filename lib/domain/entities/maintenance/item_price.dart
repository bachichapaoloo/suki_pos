import 'package:equatable/equatable.dart';

class ItemPrice extends Equatable {
  final int? id;
  final String priceLevel;
  final double price;

  const ItemPrice({required this.priceLevel, required this.price, this.id});

  @override
  List<Object?> get props => [id, priceLevel, price];
}
