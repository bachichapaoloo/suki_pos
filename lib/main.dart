import 'package:device_preview/device_preview.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suki_pos/injection_container.dart' as di;
import 'package:suki_pos/presentation/auth/login_page.dart';
import 'package:suki_pos/presentation/maintenance/category/bloc/category_bloc.dart';
import 'package:suki_pos/presentation/maintenance/category/pages/category_list_page.dart';
import 'package:suki_pos/presentation/maintenance/department/bloc/department_bloc.dart';
import 'package:suki_pos/presentation/maintenance/department/pages/department_list_page.dart';
import 'package:suki_pos/presentation/maintenance/maintenance_page.dart';
import 'package:suki_pos/presentation/maintenance/product/bloc/product_bloc.dart';
import 'package:suki_pos/presentation/maintenance/product/pages/product_list_page.dart';
import 'package:suki_pos/presentation/pos/pos_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        BlocProvider(create: (_) => di.sl<ProductBloc>()),
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
          '/maintenance/products': (context) => const ProductListPage(),
        },
      ),
    );
  }
}
