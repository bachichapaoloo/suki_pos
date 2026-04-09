import 'package:flutter/material.dart';

/// A utility class for creating responsive layouts.
class ResponsiveLayout extends StatelessWidget {
  /// Creates a [ResponsiveLayout].
  const ResponsiveLayout({
    required this.mobile,
    required this.desktop,
    super.key,
    this.tablet,
  });

  /// Widget to display on mobile devices.
  final Widget mobile;

  /// Widget to display on tablet devices.
  final Widget? tablet;

  /// Widget to display on desktop devices.
  final Widget desktop;

  /// Breakpoint for tablet devices.
  static const double tabletBreakpoint = 600;

  /// Breakpoint for desktop devices.
  static const double desktopBreakpoint = 1024;

  /// Checks if the device is mobile.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  /// Checks if the device is tablet.
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint &&
      MediaQuery.sizeOf(context).width < desktopBreakpoint;

  /// Checks if the device is desktop.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= desktopBreakpoint) {
      return desktop;
    } else if (width >= tabletBreakpoint && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

/// Extension on [BuildContext] for easy access to responsiveness helpers.
extension ResponsiveContext on BuildContext {
  /// Checks if the device is mobile.
  bool get isMobile => ResponsiveLayout.isMobile(this);

  /// Checks if the device is tablet.
  bool get isTablet => ResponsiveLayout.isTablet(this);

  /// Checks if the device is desktop.
  bool get isDesktop => ResponsiveLayout.isDesktop(this);

  /// Gets the screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Gets the screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Returns a value based on the current screen size.
  T responsiveValue<T>({
    required T mobile,
    required T desktop,
    T? tablet,
  }) {
    if (isDesktop) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}
