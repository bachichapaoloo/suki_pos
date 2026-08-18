import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/discount_dao.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/maintenance/discount_type.dart';
import 'package:suki_pos/domain/repositories/maintenance/discount_repository.dart';

class DiscountRepositoryImpl implements DiscountRepository {
  const DiscountRepositoryImpl(this.discountDao);
  final DiscountDao discountDao;

  @override
  Future<Either<Failure, List<DiscountType>>> getDiscountTypes() async {
    try {
      final types = await discountDao.getDiscountTypes();
      return Right(types);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Discount>>> getDiscounts() async {
    try {
      final discounts = await discountDao.getAllDiscounts();
      return Right(discounts);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Discount>> createDiscount(Discount discount) async {
    try {
      final id = await discountDao.insertDiscount(discount.toMap());
      return Right(discount.copyWith(id: id));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Discount>> updateDiscount(Discount discount) async {
    try {
      if (discount.id == null) {
        return const Left(DatabaseFailure('Discount ID cannot be null for update.'));
      }
      await discountDao.updateDiscount(discount.id!, discount.toMap());
      return Right(discount);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDiscount(int id) async {
    try {
      await discountDao.deleteDiscount(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleDiscountStatus(int id, bool isActive) async {
    try {
      await discountDao.toggleDiscountStatus(id, isActive);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
