import 'package:dartz/dartz.dart';
import 'package:suki_pos/core/error/failures.dart';
import 'package:suki_pos/core/use_case/use_case.dart';
import 'package:suki_pos/domain/entities/maintenance/category.dart';
import 'package:suki_pos/domain/repositories/maintenance/category_repository.dart';

class GetCategories implements UseCase<List<Category>, NoParams> {
  const GetCategories(this.repository);
  final CategoryRepository repository;

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) {
    return repository.getCategories();
  }
}

class SaveCategory implements UseCase<Category, Category> {
  const SaveCategory(this.repository);
  final CategoryRepository repository;

  @override
  Future<Either<Failure, Category>> call(Category category) {
    return repository.saveCategory(category);
  }
}

class DeleteCategory implements UseCase<void, int> {
  const DeleteCategory(this.repository);
  final CategoryRepository repository;

  @override
  Future<Either<Failure, void>> call(int id) {
    return repository.deleteCategory(id);
  }
}
