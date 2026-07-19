import 'dart:io';

import 'package:device_preview/device_preview.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:suki_pos/injection_container.dart' as di;
import 'package:suki_pos/presentation/admin/admin_page.dart';
import 'package:suki_pos/presentation/admin/role/bloc/role_bloc.dart';
import 'package:suki_pos/presentation/admin/role/pages/role_list_page.dart';
import 'package:suki_pos/presentation/admin/user/bloc/user_bloc.dart';
import 'package:suki_pos/presentation/admin/user/pages/user_list_page.dart';
import 'package:suki_pos/presentation/auth/bloc/auth_bloc.dart';
import 'package:suki_pos/presentation/auth/login_page.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/category/pages/category_list_page.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/pages/department_list_page.dart';
import 'package:suki_pos/presentation/maintenance/maintenance_page.dart';
import 'package:suki_pos/presentation/maintenance/item/bloc/item_bloc.dart';
import 'package:suki_pos/presentation/maintenance/item/pages/item_list_page.dart';
import 'package:suki_pos/presentation/pos/pos_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await di.init();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<DepartmentBloc>()),
        BlocProvider(create: (_) => di.sl<CategoryBloc>()),
        BlocProvider(create: (_) => di.sl<ItemBloc>()),
        BlocProvider(create: (_) => di.sl<RoleBloc>()),
        BlocProvider(create: (_) => di.sl<UserBloc>()),
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
      ],
      child: MaterialApp(
        title: 'Suki POS',
        debugShowCheckedModeBanner: false,
        theme: FlexThemeData.light(scheme: FlexScheme.mandyRed),
        darkTheme: FlexThemeData.dark(scheme: FlexScheme.mandyRed),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginPage(),
          '/pos': (context) => const PosDashboardPage(),
          '/maintenance': (context) => const MaintenancePage(),
          '/maintenance/departments': (context) => const DepartmentListPage(),
          '/maintenance/categories': (context) => const CategoryListPage(),
          '/maintenance/items': (context) => const ItemListPage(),
          '/admin': (context) => const AdminPage(),
          '/admin/users': (context) => const UserListPage(),
          '/admin/roles': (context) => const RoleListPage(),
        },
      ),
    );
  }
}

