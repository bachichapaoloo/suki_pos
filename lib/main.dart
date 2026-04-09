import 'package:device_preview/device_preview.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/pos/pos_dashboard_page.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(DevicePreview(enabled: !kReleaseMode, builder: (context) => const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suki POS',
      debugShowCheckedModeBanner: false,
      // The Mandy red, light theme.
      theme: FlexThemeData.light(scheme: FlexScheme.mandyRed),
      // The Mandy red, dark theme.
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.mandyRed),
      // Use dark or light theme based on system setting.
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {'/': (context) => const LoginPage(), '/pos': (context) => const PosDashboardPage()},
    );
  }
}
