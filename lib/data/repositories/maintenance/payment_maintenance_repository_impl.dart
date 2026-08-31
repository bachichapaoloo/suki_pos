// Suggested Outline for PaymentMaintenanceRepositoryImpl:
import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/bank_dao.dart';
import 'package:suki_pos/data/dao/charge_payment_dao.dart';
import 'package:suki_pos/data/dao/payment_method_dao.dart';
import 'package:suki_pos/domain/entities/maintenance/bank.dart';
import 'package:suki_pos/domain/entities/maintenance/charge.dart';
import 'package:suki_pos/domain/entities/maintenance/payment_method.dart';
import 'package:suki_pos/domain/repositories/maintenance/payment_maintenance_repositories.dart';

class PaymentMaintenanceRepositoryImpl implements PaymentMaintenanceRepositories {
  final PaymentMethodDao paymentMethodDao;
  final BankDao bankDao;
  final ChargePaymentDao chargePaymentDao;

  PaymentMaintenanceRepositoryImpl({
    required this.paymentMethodDao,
    required this.bankDao,
    required this.chargePaymentDao,
  });

  @override
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods() async {
    try {
      final results = await paymentMethodDao.getPaymentMethods();
      return Right(results);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBank(int id) async {
    try {
      await bankDao.deleteBank(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCharge(int id) async {
    try {
      await chargePaymentDao.deleteChargePayment(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePaymentMethod(int id) async {
    try {
      await paymentMethodDao.deletePaymentMethod(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Bank>>> getBanks() async {
    try {
      final results = await bankDao.getBanks();
      return Right(results);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Charge>>> getCharges() async {
    try {
      final results = await chargePaymentDao.getChargePayments();
      return Right(results);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveBank(Bank bank) async {
    try {
      await bankDao.insertBank(bank);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCharge(Charge charge) async {
    try {
      await chargePaymentDao.insertChargePayment(charge);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePaymentMethod(PaymentMethod method) async {
    try {
      await paymentMethodDao.insertPaymentMethod(method);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
