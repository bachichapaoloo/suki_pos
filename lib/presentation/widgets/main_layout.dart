import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suki_pos/core/enums/enums.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({
    super.key,
    required this.currentTab,
    required this.mobileBody,
    required this.desktopBody,
    this.mobileAppBar,
    this.desktopHeader,
    this.floatingActionButton,
  });

  final MainTab currentTab;
  final Widget mobileBody;
  final Widget desktopBody;
  final PreferredSizeWidget? mobileAppBar;
  final Widget? desktopHeader;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return _buildDesktopLayout(context);
        }
        return _buildMobileLayout(context);
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: mobileAppBar,
      body: mobileBody,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          // Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (desktopHeader != null) desktopHeader!,
                Expanded(child: desktopBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
