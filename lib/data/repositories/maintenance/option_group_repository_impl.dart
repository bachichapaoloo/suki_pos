import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/data/dao/option_group_dao.dart';
import 'package:suki_pos/data/models/maintenance/option_group_model.dart';
import 'package:suki_pos/data/models/maintenance/option_value_model.dart';
import 'package:suki_pos/domain/entities/maintenance/option_group.dart';
import 'package:suki_pos/domain/repositories/maintenance/option_group_repository.dart';

class OptionGroupRepositoryImpl implements OptionGroupRepository {
  final OptionGroupDao optionGroupDao;

  OptionGroupRepositoryImpl({required this.optionGroupDao});

  @override
  Future<Either<Failure, List<OptionGroup>>> getOptionGroups() async {
    try {
      final groups = await optionGroupDao.getAllOptionGroups();
      return Right(groups);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OptionGroup>> saveOptionGroup(OptionGroup group) async {
    try {
      final model = OptionGroupModel(
        id: group.id,
        name: group.name,
        isRequired: group.isRequired,
        selectionType: group.selectionType,
        minSelect: group.minSelect,
        maxSelect: group.maxSelect,
        displayOrder: group.displayOrder,
        values: group.values
            .map(
              (v) => OptionValueModel(
                id: v.id,
                optionGroupId: v.optionGroupId,
                itemId: v.itemId,
                alias: v.alias,
                priceDelta: v.priceDelta,
                costPriceDelta: v.costPriceDelta,
                quantity: v.quantity,
                unitId: v.unitId,
                displayOrder: v.displayOrder,
              ),
            )
            .toList(),
      );

      final newId = await optionGroupDao.saveOptionGroupAggregate(model);
      return Right(
        OptionGroupModel(
          id: newId,
          name: group.name,
          isRequired: group.isRequired,
          selectionType: group.selectionType,
          minSelect: group.minSelect,
          maxSelect: group.maxSelect,
          displayOrder: group.displayOrder,
          values: group.values,
        ),
      );
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignOptionGroupToItem(int itemId, int optionGroupId, {int displayOrder = 0}) async {
    try {
      await optionGroupDao.assignOptionGroupToItem(itemId, optionGroupId, displayOrder: displayOrder);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeOptionGroupFromItem(int itemId, int optionGroupId) async {
    try {
      await optionGroupDao.removeOptionGroupFromItem(itemId, optionGroupId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
