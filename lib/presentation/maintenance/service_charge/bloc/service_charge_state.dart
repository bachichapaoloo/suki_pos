import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/order_type.dart';
import 'package:suki_pos/domain/entities/maintenance/service_charge_config.dart';

abstract class ServiceChargeState extends Equatable {
  const ServiceChargeState();

  @override
  List<Object?> get props => [];
}

class ServiceChargeInitial extends ServiceChargeState {}

class ServiceChargeLoading extends ServiceChargeState {}

class ServiceChargeLoaded extends ServiceChargeState {
  final ServiceChargeConfig config;
  final List<OrderType> orderTypes;

  const ServiceChargeLoaded({
    required this.config,
    this.orderTypes = const [],
  });

  ServiceChargeLoaded copyWith({
    ServiceChargeConfig? config,
    List<OrderType>? orderTypes,
  }) {
    return ServiceChargeLoaded(
      config: config ?? this.config,
      orderTypes: orderTypes ?? this.orderTypes,
    );
  }

  @override
  List<Object?> get props => [config, orderTypes];
}

class ServiceChargeError extends ServiceChargeState {
  final String message;

  const ServiceChargeError(this.message);

  @override
  List<Object?> get props => [message];
}
