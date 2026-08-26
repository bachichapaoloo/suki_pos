import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/domain/entities/maintenance/order_type.dart';
import 'package:suki_pos/domain/entities/maintenance/service_charge_config.dart';
import 'package:suki_pos/domain/repositories/maintenance/order_type_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/service_charge_repository.dart';
import 'package:suki_pos/presentation/maintenance/service_charge/bloc/service_charge_state.dart';

class ServiceChargeCubit extends Cubit<ServiceChargeState> {
  final ServiceChargeRepository serviceChargeRepository;
  final OrderTypeRepository orderTypeRepository;

  ServiceChargeCubit({
    required this.serviceChargeRepository,
    required this.orderTypeRepository,
  }) : super(ServiceChargeInitial());

  Future<void> loadServiceChargeConfig() async {
    emit(ServiceChargeLoading());
    try {
      final configResult = await serviceChargeRepository.getServiceChargeConfig();
      final orderTypesResult = await orderTypeRepository.getOrderTypes();

      configResult.fold(
        (failure) => emit(ServiceChargeError('Failed to load service charge configuration')),
        (config) {
          orderTypesResult.fold(
            (failure) => emit(ServiceChargeLoaded(config: config, orderTypes: const [])),
            (orderTypes) => emit(ServiceChargeLoaded(config: config, orderTypes: orderTypes)),
          );
        },
      );
    } catch (e) {
      emit(ServiceChargeError(e.toString()));
    }
  }

  Future<bool> saveConfig(ServiceChargeConfig config) async {
    final result = await serviceChargeRepository.saveServiceChargeConfig(config);
    return result.fold(
      (failure) {
        emit(ServiceChargeError('Failed to save service charge configuration'));
        return false;
      },
      (saved) {
        if (state is ServiceChargeLoaded) {
          emit((state as ServiceChargeLoaded).copyWith(config: saved));
        } else {
          emit(ServiceChargeLoaded(config: saved));
        }
        return true;
      },
    );
  }

  Future<bool> toggleOrderTypeServiceCharge(int orderTypeId, bool hasServiceCharge) async {
    if (state is! ServiceChargeLoaded) return false;
    final current = state as ServiceChargeLoaded;

    final targetOrderType = current.orderTypes.where((ot) => ot.id == orderTypeId).firstOrNull;
    if (targetOrderType == null) return false;

    final updated = targetOrderType.copyWith(hasServiceCharge: hasServiceCharge);
    final result = await orderTypeRepository.saveOrderType(updated);

    return result.fold(
      (failure) {
        emit(ServiceChargeError('Failed to update service charge configuration'));
        return false;
      },
      (_) {
        final updatedList = current.orderTypes.map((ot) => ot.id == orderTypeId ? updated : ot).toList();
        emit(current.copyWith(orderTypes: updatedList));
        return true;
      },
    );
  }
}
