import 'package:equatable/equatable.dart';
import 'package:suki_pos/domain/entities/maintenance/bank.dart';
import 'package:suki_pos/domain/entities/maintenance/charge.dart';
import 'package:suki_pos/domain/entities/maintenance/payment_method.dart';

abstract class PaymentMaintenanceState extends Equatable {
  const PaymentMaintenanceState();
  @override
  List<Object?> get props => [];
}

class PaymentMaintenanceInitial extends PaymentMaintenanceState {}

class PaymentMaintenanceLoading extends PaymentMaintenanceState {}

class PaymentMaintenanceLoaded extends PaymentMaintenanceState {
  final List<PaymentMethod> paymentMethods;
  final List<Bank> banks;
  final List<Charge> charges;

  const PaymentMaintenanceLoaded({
    required this.paymentMethods,
    required this.banks,
    required this.charges,
  });

  @override
  List<Object?> get props => [paymentMethods, banks, charges];
}

class PaymentMaintenanceError extends PaymentMaintenanceState {
  final String message;
  const PaymentMaintenanceError(this.message);

  @override
  List<Object?> get props => [message];
}
