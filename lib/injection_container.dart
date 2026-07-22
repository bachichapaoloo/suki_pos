import 'package:get_it/get_it.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/data/dao/unit_dao.dart';
import 'package:suki_pos/data/repositories/admin/role_repository_impl.dart';
import 'package:suki_pos/data/repositories/admin/user_repository_impl.dart';
import 'package:suki_pos/data/repositories/auth/auth_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/category_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/department_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/item_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/unit_repository_impl.dart';
import 'package:suki_pos/domain/repositories/admin/role_repository.dart';
import 'package:suki_pos/domain/repositories/admin/user_repository.dart';
import 'package:suki_pos/domain/repositories/auth/auth_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/category_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/department_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/item_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/unit_repository.dart' show UnitRepository;
import 'package:suki_pos/domain/use_cases/admin/role_use_cases.dart';
import 'package:suki_pos/domain/use_cases/admin/user_use_cases.dart';
import 'package:suki_pos/domain/use_cases/auth/login.dart';
import 'package:suki_pos/domain/use_cases/maintenance/category_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/delete_department.dart';
import 'package:suki_pos/domain/use_cases/maintenance/get_departments.dart';
import 'package:suki_pos/domain/use_cases/maintenance/item_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/save_department.dart';
import 'package:suki_pos/domain/use_cases/maintenance/unit_use_cases.dart';
import 'package:suki_pos/presentation/admin/role/bloc/role_bloc.dart';
import 'package:suki_pos/presentation/admin/user/bloc/user_bloc.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/data/dao/department_dao.dart';
import 'package:suki_pos/data/dao/item_dao.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Presentation - BLoCs
  sl
    ..registerFactory(
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
      () => ItemBloc(
        getItems: sl(),
        saveItem: sl(),
        deleteItem: sl(),
      ),
    )
    ..registerFactory(
      () => RoleBloc(
        getRoles: sl(),
        saveRole: sl(),
        deleteRole: sl(),
      ),
    )
    ..registerFactory(
      () => UserBloc(
        getUsers: sl(),
        saveUser: sl(),
        deleteUser: sl(),
      ),
    )
    ..registerFactory(
      () => AuthBloc(
        loginUseCase: sl(),
      ),
    )
    //! Domain - Use Cases
    ..registerLazySingleton(() => GetDepartments(sl()))
    ..registerLazySingleton(() => SaveDepartment(sl()))
    ..registerLazySingleton(() => DeleteDepartment(sl()))
    ..registerLazySingleton(() => GetCategories(sl()))
    ..registerLazySingleton(() => SaveCategory(sl()))
    ..registerLazySingleton(() => DeleteCategory(sl()))
    ..registerLazySingleton(() => GetItems(sl()))
    ..registerLazySingleton(() => SaveItem(sl()))
    ..registerLazySingleton(() => DeleteItem(sl()))
    ..registerLazySingleton(() => GetRoles(sl()))
    ..registerLazySingleton(() => SaveRole(sl()))
    ..registerLazySingleton(() => DeleteRole(sl()))
    ..registerLazySingleton(() => GetUsers(sl()))
    ..registerLazySingleton(() => SaveUser(sl()))
    ..registerLazySingleton(() => DeleteUser(sl()))
    ..registerLazySingleton(() => Login(sl()))
    ..registerLazySingleton(() => GetUnits(sl()))
    ..registerLazySingleton(() => SaveUnit(sl()))
    ..registerLazySingleton(() => DeleteUnit(sl()))
    //! Data - Repositories
    ..registerLazySingleton<DepartmentRepository>(
      () => DepartmentRepositoryImpl(departmentDao: sl()),
    )
    ..registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(sl()),
    )
    ..registerLazySingleton<RoleRepository>(
      () => RoleRepositoryImpl(sl()),
    )
    ..registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ItemRepository>(
      () => ItemRepositoryImpl(itemDao: sl()),
    )
    ..registerLazySingleton<UnitRepository>(
      () => UnitRepositoryImpl(unitDao: sl()),
    )
    //! DAOs
    ..registerLazySingleton(() => DepartmentDao(sl()))
    ..registerLazySingleton(() => ItemDao(sl()))
    ..registerLazySingleton(() => UnitDao(sl()));

  //! Core
  final dbHelper = DatabaseHelper();
  sl.registerLazySingleton(() => dbHelper);

  // Trigger eager database initialization
  await dbHelper.database;
}
