import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/maintenance/discount_type.dart';

abstract class DiscountRepository {
  Future<Either<Failure, List<DiscountType>>> getDiscountTypes();
  Future<Either<Failure, List<Discount>>> getDiscounts();
  Future<Either<Failure, Discount>> createDiscount(Discount discount);
  Future<Either<Failure, Discount>> updateDiscount(Discount discount);
  Future<Either<Failure, void>> deleteDiscount(int id);
  Future<Either<Failure, void>> toggleDiscountStatus(int id, bool isActive);
}
