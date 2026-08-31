import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/domain/entities/maintenance/bank.dart';
import 'package:suki_pos/domain/entities/maintenance/charge.dart';
import 'package:suki_pos/domain/entities/maintenance/payment_method.dart';
import 'package:suki_pos/domain/repositories/maintenance/payment_maintenance_repositories.dart';
import 'package:suki_pos/presentation/maintenance/payment_method/bloc/payment_maintenance_state.dart';

class PaymentMaintenanceCubit extends Cubit<PaymentMaintenanceState> {
  final PaymentMaintenanceRepositories repository;

  PaymentMaintenanceCubit({required this.repository}) : super(PaymentMaintenanceInitial());

  Future<void> loadAll() async {
    emit(PaymentMaintenanceLoading());
    final methodsResult = await repository.getPaymentMethods();
    final banksResult = await repository.getBanks();
    final chargesResult = await repository.getCharges();

    methodsResult.fold(
      (f) => emit(PaymentMaintenanceError('Failed to load payment methods.')),
      (methods) => banksResult.fold(
        (f) => emit(PaymentMaintenanceError('Failed to load banks.')),
        (banks) => chargesResult.fold(
          (f) => emit(PaymentMaintenanceError('Failed to load charges.')),
          (charges) => emit(
            PaymentMaintenanceLoaded(
              paymentMethods: methods,
              banks: banks,
              charges: charges,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> saveBank(Bank bank) async {
    final result = await repository.saveBank(bank);
    return result.fold(
      (failure) => false,
      (_) {
        loadAll(); // Auto-reload after saving!
        return true;
      },
    );
  }

  Future<bool> deleteBank(int id) async {
    final result = await repository.deleteBank(id);
    return result.fold((failure) => false, (_) {
      loadAll();
      return true;
    });
  }

  Future<bool> saveCharge(Charge charge) async {
    final result = await repository.saveCharge(charge);
    return result.fold((failure) => false, (_) {
      loadAll();
      return true;
    });
  }

  Future<bool> deleteCharge(int id) async {
    final result = await repository.deleteCharge(id);
    return result.fold((failure) => false, (_) {
      loadAll();
      return true;
    });
  }

  Future<bool> togglePaymentMethod(PaymentMethod method, bool isActive) async {
    final updated = method.copyWith(isActive: isActive);
    final result = await repository.savePaymentMethod(updated);
    return result.fold((f) => false, (_) {
      loadAll();
      return true;
    });
  }
}
