import 'package:get_it/get_it.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/data/repositories/admin/role_repository_impl.dart';
import 'package:suki_pos/data/repositories/admin/user_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/category_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/department_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/product_repository_impl.dart';
import 'package:suki_pos/domain/repositories/admin/role_repository.dart';
import 'package:suki_pos/domain/repositories/admin/user_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/category_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/department_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/product_repository.dart';
import 'package:suki_pos/domain/use_cases/admin/role_use_cases.dart';
import 'package:suki_pos/domain/use_cases/admin/user_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/category_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/delete_department.dart';
import 'package:suki_pos/domain/use_cases/maintenance/get_departments.dart';
import 'package:suki_pos/domain/use_cases/maintenance/product_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/save_department.dart';
import 'package:suki_pos/presentation/admin/role/bloc/role_bloc.dart';
import 'package:suki_pos/presentation/admin/user/bloc/user_bloc.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/product/bloc/product_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Presentation - BLoCs
  sl.registerFactory(
    () => DepartmentBloc(
      getDepartments: sl(),
      saveDepartment: sl(),
      deleteDepartment: sl(),
    ),
  );
  sl.registerFactory(
    () => CategoryBloc(
      getCategories: sl(),
      saveCategory: sl(),
      deleteCategory: sl(),
    ),
  );
  sl.registerFactory(
    () => ProductBloc(
      getProducts: sl(),
      saveProduct: sl(),
      deleteProduct: sl(),
    ),
  );
  sl.registerFactory(
    () => RoleBloc(
      getRoles: sl(),
      saveRole: sl(),
      deleteRole: sl(),
    ),
  );
  sl.registerFactory(
    () => UserBloc(
      getUsers: sl(),
      saveUser: sl(),
      deleteUser: sl(),
    ),
  );

  //! Domain - Use Cases
  sl.registerLazySingleton(() => GetDepartments(sl()));
  sl.registerLazySingleton(() => SaveDepartment(sl()));
  sl.registerLazySingleton(() => DeleteDepartment(sl()));

  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => SaveCategory(sl()));
  sl.registerLazySingleton(() => DeleteCategory(sl()));

  sl.registerLazySingleton(() => GetProducts(sl()));
  sl.registerLazySingleton(() => SaveProduct(sl()));
  sl.registerLazySingleton(() => DeleteProduct(sl()));

  sl.registerLazySingleton(() => GetRoles(sl()));
  sl.registerLazySingleton(() => SaveRole(sl()));
  sl.registerLazySingleton(() => DeleteRole(sl()));

  sl.registerLazySingleton(() => GetUsers(sl()));
  sl.registerLazySingleton(() => SaveUser(sl()));
  sl.registerLazySingleton(() => DeleteUser(sl()));

  //! Data - Repositories
  sl.registerLazySingleton<DepartmentRepository>(
    () => DepartmentRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<RoleRepository>(
    () => RoleRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl()),
  );

  //! Core
  final dbHelper = DatabaseHelper();
  sl.registerLazySingleton(() => dbHelper);

  // Trigger eager database initialization
  await dbHelper.database;
}
