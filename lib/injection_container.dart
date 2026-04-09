import 'package:get_it/get_it.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/data/repositories/maintenance/category_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/department_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/product_repository_impl.dart';
import 'package:suki_pos/domain/repositories/maintenance/category_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/department_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/product_repository.dart';
import 'package:suki_pos/domain/use_cases/maintenance/category_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/delete_department.dart';
import 'package:suki_pos/domain/use_cases/maintenance/get_departments.dart';
import 'package:suki_pos/domain/use_cases/maintenance/product_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/save_department.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/product/bloc/product_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  //! Presentation - BLoCs
  sl..registerFactory(
    () => DepartmentBloc(
      getDepartments: sl(),
      saveDepartment: sl(),
      deleteDepartment: sl(),
    ),
  )
  ..registerFactory(
    () => CategoryBloc(
      getCategories: sl(),
      saveCategory: sl(),
      deleteCategory: sl(),
    ),
  )
  ..registerFactory(
    () => ProductBloc(
      getProducts: sl(),
      saveProduct: sl(),
      deleteProduct: sl(),
    ),
  )

  //! Domain - Use Cases
  ..registerLazySingleton(() => GetDepartments(sl()))
  ..registerLazySingleton(() => SaveDepartment(sl()))
  ..registerLazySingleton(() => DeleteDepartment(sl()))

  ..registerLazySingleton(() => GetCategories(sl()))
  ..registerLazySingleton(() => SaveCategory(sl()))
  ..registerLazySingleton(() => DeleteCategory(sl()))

  ..registerLazySingleton(() => GetProducts(sl()))
  ..registerLazySingleton(() => SaveProduct(sl()))
  ..registerLazySingleton(() => DeleteProduct(sl()))

  //! Data - Repositories
  ..registerLazySingleton<DepartmentRepository>(
    () => DepartmentRepositoryImpl(sl()),
  )
  ..registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl()),
  )
  ..registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );

  //! Core
  final dbHelper = DatabaseHelper();
  sl.registerLazySingleton(() => dbHelper);
  
  // Trigger eager database initialization
  await dbHelper.database;
}
