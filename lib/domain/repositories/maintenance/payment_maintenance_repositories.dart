import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/bank.dart';
import 'package:suki_pos/domain/entities/maintenance/charge.dart';
import 'package:suki_pos/domain/entities/maintenance/payment_method.dart';

abstract class PaymentMaintenanceRepositories {
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods();
  Future<Either<Failure, void>> savePaymentMethod(PaymentMethod method);
  Future<Either<Failure, void>> deletePaymentMethod(int id);
  Future<Either<Failure, List<Bank>>> getBanks();
  Future<Either<Failure, void>> saveBank(Bank bank);
  Future<Either<Failure, void>> deleteBank(int id);
  Future<Either<Failure, List<Charge>>> getCharges();
  Future<Either<Failure, void>> saveCharge(Charge charge);
  Future<Either<Failure, void>> deleteCharge(int id);
}
