import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/domain/entities/maintenance/option_group.dart';
import 'package:suki_pos/domain/repositories/maintenance/option_group_repository.dart';

class GetOptionGroups {
  final OptionGroupRepository repository;
  GetOptionGroups(this.repository);

  Future<Either<Failure, List<OptionGroup>>> call() async {
    return await repository.getOptionGroups();
  }
}

class SaveOptionGroup {
  final OptionGroupRepository repository;
  SaveOptionGroup(this.repository);

  Future<Either<Failure, OptionGroup>> call(OptionGroup optionGroup) async {
    return await repository.saveOptionGroup(optionGroup);
  }
}

class AssignOptionGroupToItem {
  final OptionGroupRepository repository;
  AssignOptionGroupToItem(this.repository);

  Future<Either<Failure, void>> call(int itemId, int optionGroupId, {int displayOrder = 0}) async {
    return await repository.assignOptionGroupToItem(itemId, optionGroupId, displayOrder: displayOrder);
  }
}
