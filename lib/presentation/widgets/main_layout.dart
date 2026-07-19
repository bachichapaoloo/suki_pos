import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum MainTab { home, sales, inventory, reports }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: mobileAppBar,
      body: mobileBody,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
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
