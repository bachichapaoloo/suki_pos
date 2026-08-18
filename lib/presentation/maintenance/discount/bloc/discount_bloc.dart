import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/domain/repositories/maintenance/discount_repository.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_event.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_state.dart';

class DiscountBloc extends Bloc<DiscountEvent, DiscountState> {
  final DiscountRepository discountRepository;

  DiscountBloc({required this.discountRepository}) : super(DiscountInitial()) {
    on<GetDiscountsEvent>(_onGetDiscounts);
    on<SaveDiscountEvent>(_onSaveDiscount);
    on<DeleteDiscountEvent>(_onDeleteDiscount);
    on<ToggleDiscountStatusEvent>(_onToggleDiscountStatus);
  }

  Future<void> _onGetDiscounts(DiscountEvent event, Emitter<DiscountState> emit) async {
    emit(DiscountLoading());

    final discountsResult = await discountRepository.getDiscounts();
    final typesResult = await discountRepository.getDiscountTypes();

    discountsResult.fold((failure) => emit(DiscountError(message: 'Failed to load discounts')), (discounts) {
      typesResult.fold(
        (failure) => emit(DiscountError(message: 'Failed to load types')),
        (discountTypes) => emit(DiscountLoaded(discounts: discounts, discountTypes: discountTypes)),
      );
    });
  }

  Future<void> _onSaveDiscount(SaveDiscountEvent event, Emitter<DiscountState> emit) async {
    emit(DiscountLoading());

    final result = event.discount.id == null
        ? await discountRepository.createDiscount(event.discount)
        : await discountRepository.updateDiscount(event.discount);

    result.fold(
      (failure) =>
          emit(DiscountError(message: 'Failed to ${event.discount.id == null ? 'created' : 'updated'} discount')),
      (_) {
        emit(
          DiscountSuccess(message: 'Discount ${event.discount.id == null ? 'created' : 'updated'} successfully'),
        );
        add(GetDiscountsEvent());
      },
    );
  }

  Future<void> _onDeleteDiscount(DeleteDiscountEvent event, Emitter<DiscountState> emit) async {
    emit(DiscountLoading());

    final result = await discountRepository.deleteDiscount(event.id);

    result.fold((failure) => emit(DiscountError(message: 'Failed to delete discount.')), (_) {
      emit(DiscountSuccess(message: 'Discount deleted successfully.'));
      add(GetDiscountsEvent());
    });
  }

  Future<void> _onToggleDiscountStatus(ToggleDiscountStatusEvent event, Emitter<DiscountState> emit) async {
    if (event.discount.id == null) return;

    final result = await discountRepository.toggleDiscountStatus(event.discount.id!, event.isActive);

    result.fold((failure) => emit(DiscountError(message: 'Failed to update discount status.')), (_) {
      add(GetDiscountsEvent());
    });
  }
}
