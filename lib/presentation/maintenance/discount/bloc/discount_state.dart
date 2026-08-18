import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/maintenance/discount_type.dart';

abstract class DiscountState {}

class DiscountInitial extends DiscountState {}

class DiscountLoading extends DiscountState {}

class DiscountLoaded extends DiscountState {
  final List<Discount> discounts;
  final List<DiscountType> discountTypes;

  DiscountLoaded({required this.discounts, required this.discountTypes});
}

class DiscountSuccess extends DiscountState {
  final String message;
  DiscountSuccess({this.message = ''});
}

class DiscountError extends DiscountState {
  final String message;
  DiscountError({required this.message});
}
