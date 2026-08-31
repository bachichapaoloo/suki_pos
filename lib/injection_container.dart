import 'package:get_it/get_it.dart';
import 'package:suki_pos/core/database/database_helper.dart';
import 'package:suki_pos/data/dao/bank_dao.dart';
import 'package:suki_pos/data/dao/charge_payment_dao.dart';
import 'package:suki_pos/data/dao/department_dao.dart';
import 'package:suki_pos/data/dao/discount_dao.dart';
import 'package:suki_pos/data/dao/item_dao.dart';
import 'package:suki_pos/data/dao/option_group_dao.dart';
import 'package:suki_pos/data/dao/order_dao.dart';
import 'package:suki_pos/data/dao/order_type_dao.dart';
import 'package:suki_pos/data/dao/payment_method_dao.dart';
import 'package:suki_pos/data/dao/service_charge_dao.dart';
import 'package:suki_pos/data/dao/shift_dao.dart';
import 'package:suki_pos/data/dao/stock_dao.dart';
import 'package:suki_pos/data/dao/unit_dao.dart';
import 'package:suki_pos/data/repositories/admin/role_repository_impl.dart';
import 'package:suki_pos/data/repositories/admin/user_repository_impl.dart';
import 'package:suki_pos/data/repositories/auth/auth_repository_impl.dart';
import 'package:suki_pos/data/repositories/inventory/stock_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/category_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/department_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/discount_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/item_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/option_group_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/order_type_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/payment_maintenance_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/service_charge_repository_impl.dart';
import 'package:suki_pos/data/repositories/maintenance/unit_repository_impl.dart';
import 'package:suki_pos/data/repositories/orders/order_repository_impl.dart';
import 'package:suki_pos/domain/repositories/admin/role_repository.dart';
import 'package:suki_pos/domain/repositories/admin/user_repository.dart';
import 'package:suki_pos/domain/repositories/auth/auth_repository.dart';
import 'package:suki_pos/domain/repositories/inventory/stock_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/category_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/department_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/discount_repository.dart' show DiscountRepository;
import 'package:suki_pos/domain/repositories/maintenance/item_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/option_group_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/order_type_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/payment_maintenance_repositories.dart';
import 'package:suki_pos/domain/repositories/maintenance/service_charge_repository.dart';
import 'package:suki_pos/domain/repositories/maintenance/unit_repository.dart' show UnitRepository;
import 'package:suki_pos/domain/repositories/orders/order_repository.dart';
import 'package:suki_pos/domain/use_cases/admin/role_use_cases.dart';
import 'package:suki_pos/domain/use_cases/admin/user_use_cases.dart';
import 'package:suki_pos/domain/use_cases/auth/login.dart';
import 'package:suki_pos/domain/use_cases/inventory/stock_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/category_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/delete_department.dart';
import 'package:suki_pos/domain/use_cases/maintenance/get_departments.dart';
import 'package:suki_pos/domain/use_cases/maintenance/item_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/option_group_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/order_type_use_cases.dart';
import 'package:suki_pos/domain/use_cases/maintenance/save_department.dart';
import 'package:suki_pos/domain/use_cases/maintenance/unit_use_cases.dart';
import 'package:suki_pos/domain/use_cases/orders/get_transaction_history.dart';
import 'package:suki_pos/domain/use_cases/orders/process_checkout.dart';
import 'package:suki_pos/domain/use_cases/orders/void_order_transaction.dart';
import 'package:suki_pos/presentation/admin/role/bloc/role_bloc.dart';
import 'package:suki_pos/presentation/admin/user/bloc/user_bloc.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/inventory/stock_cubit.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/discount/bloc/discount_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/presentation/maintenance/option_group/bloc/option_group_cubit.dart';
import 'package:suki_pos/presentation/maintenance/order_type/bloc/order_type_cubit.dart';
import 'package:suki_pos/presentation/maintenance/payment_method/bloc/payment_maintenance_cubit.dart';
import 'package:suki_pos/presentation/maintenance/service_charge/bloc/service_charge_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/cart_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/shift_cubit.dart';
import 'package:suki_pos/presentation/pos/bloc/transaction_history_cubit.dart';

final GetIt sl = GetIt.instance;

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
      () => StockCubit(
        getStockWithDetails: sl(),
        updateStockQuantity: sl(),
      ),
    )
    ..registerFactory(
      () => OptionGroupCubit(
        getOptionGroups: sl(),
        saveOptionGroup: sl(),
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
    ..registerFactory(
      () => CartCubit(
        processCheckout: sl(),
      ),
    )
    ..registerFactory(
      () => TransactionHistoryCubit(
        getTransactionHistory: sl(),
        voidOrderTransaction: sl(),
      ),
    )
    ..registerFactory(
      () => ShiftCubit(
        shiftDao: sl(),
      ),
    )
    ..registerFactory(
      () => OrderTypeCubit(
        getOrderTypes: sl(),
        getOrderTypeById: sl(),
        saveOrderType: sl(),
        deleteOrderType: sl(),
      ),
    )
    ..registerFactory<DiscountBloc>(
      () => DiscountBloc(
        discountRepository: sl(),
      ),
    )
    ..registerFactory<ServiceChargeCubit>(
      () => ServiceChargeCubit(
        serviceChargeRepository: sl(),
        orderTypeRepository: sl(),
      ),
    )
    ..registerFactory<PaymentMaintenanceCubit>(
      () => PaymentMaintenanceCubit(
        repository: sl(),
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
    ..registerLazySingleton(() => GetStockByItemId(sl()))
    ..registerLazySingleton(() => UpdateStockQuantity(sl()))
    ..registerLazySingleton(() => GetStockWithDetails(sl()))
    ..registerLazySingleton(() => GetOptionGroups(sl()))
    ..registerLazySingleton(() => SaveOptionGroup(sl()))
    ..registerLazySingleton(() => AssignOptionGroupToItem(sl()))
    ..registerLazySingleton(() => ProcessCheckout(sl()))
    ..registerLazySingleton(() => GetTransactionHistory(sl()))
    ..registerLazySingleton(() => VoidOrderTransaction(sl()))
    ..registerLazySingleton(() => GetOrderTypes(sl()))
    ..registerLazySingleton(() => GetOrderTypeById(sl()))
    ..registerLazySingleton(() => SaveOrderType(sl()))
    ..registerLazySingleton(() => DeleteOrderType(sl()))
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
    ..registerLazySingleton<StockRepository>(
      () => StockRepositoryImpl(stockDao: sl()),
    )
    ..registerLazySingleton<OrderRepository>(
      () => OrderRepositoryImpl(orderDao: sl()),
    )
    ..registerLazySingleton<OptionGroupRepository>(
      () => OptionGroupRepositoryImpl(optionGroupDao: sl()),
    )
    ..registerLazySingleton<OrderTypeRepository>(
      () => OrderTypeRepositoryImpl(orderTypeDao: sl()),
    )
    ..registerLazySingleton<DiscountRepository>(
      () => DiscountRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ServiceChargeRepository>(
      () => ServiceChargeRepositoryImpl(serviceChargeDao: sl()),
    )
    ..registerLazySingleton<PaymentMaintenanceRepositories>(
      () => PaymentMaintenanceRepositoryImpl(
        paymentMethodDao: sl(),
        bankDao: sl(),
        chargePaymentDao: sl(),
      ),
    )
    //! DAOs
    ..registerLazySingleton(() => DepartmentDao(sl()))
    ..registerLazySingleton(() => ItemDao(sl()))
    ..registerLazySingleton(() => UnitDao(sl()))
    ..registerLazySingleton(() => StockDao(sl()))
    ..registerLazySingleton(() => OptionGroupDao(sl()))
    ..registerLazySingleton(() => OrderDao(sl()))
    ..registerLazySingleton(() => OrderTypeDao(sl()))
    ..registerLazySingleton(() => ShiftDao(sl()))
    ..registerLazySingleton(() => DiscountDao(sl()))
    ..registerLazySingleton(() => ServiceChargeDao(sl()))
    ..registerLazySingleton(() => PaymentMethodDao(sl()))
    ..registerLazySingleton(() => BankDao(sl()))
    ..registerLazySingleton(() => ChargePaymentDao(sl()));

  //! Core
  final dbHelper = DatabaseHelper();
  sl.registerLazySingleton(() => dbHelper);

  // Trigger eager database initialization
  await dbHelper.database;
}
