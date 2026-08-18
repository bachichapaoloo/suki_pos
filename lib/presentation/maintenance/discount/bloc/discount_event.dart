import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';

abstract class DiscountEvent extends Equatable {
  const DiscountEvent();
  @override
  List<Object?> get props => [];
}

class GetDiscountsEvent extends DiscountEvent {}

class GetDiscountTypesEvent extends DiscountEvent {}

class CreateDiscountEvent extends DiscountEvent {
  const CreateDiscountEvent(this.discount);
  final Discount discount;

  @override
  List<Object?> get props => [discount];
}

class SaveDiscountEvent extends DiscountEvent {
  const SaveDiscountEvent(this.discount);
  final Discount discount;

  @override
  List<Object?> get props => [discount];
}

class UpdateDiscountEvent extends DiscountEvent {
  const UpdateDiscountEvent(this.discount);
  final Discount discount;

  @override
  List<Object?> get props => [discount];
}

class DeleteDiscountEvent extends DiscountEvent {
  const DeleteDiscountEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class ToggleDiscountStatusEvent extends DiscountEvent {
  const ToggleDiscountStatusEvent(this.discount, this.isActive);
  final Discount discount;
  final bool isActive;

  @override
  List<Object?> get props => [discount, isActive];
}
