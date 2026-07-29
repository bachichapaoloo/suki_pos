import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import '../../entities/maintenance/option_group.dart';

abstract class OptionGroupRepository {
  Future<Either<Failure, List<OptionGroup>>> getOptionGroups();
  Future<Either<Failure, OptionGroup>> saveOptionGroup(OptionGroup optionGroup);
  Future<Either<Failure, void>> assignOptionGroupToItem(int itemId, int optionGroupId, {int displayOrder = 0});
  Future<Either<Failure, void>> removeOptionGroupFromItem(int itemId, int optionGroupId);
}
