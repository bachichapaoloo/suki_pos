import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The [AppTheme] defines light and dark themes for the app.
///
/// Theme setup for FlexColorScheme package v8.
abstract final class AppTheme {
  // The FlexColorScheme defined light mode ThemeData.
  static ThemeData get light {
    final theme = FlexThemeData.light(
      // Using FlexColorScheme built-in FlexScheme enum based colors
      scheme: FlexScheme.blueM3,
      // Component theme configurations for light mode.
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        useM2StyleDividerInM3: true,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        alignedDropdown: true,
        navigationRailUseIndicator: true,
      ),
      // Direct ThemeData properties.
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    );

    return theme.copyWith(
      textTheme: GoogleFonts.interTextTheme(theme.textTheme),
    );
  }

  // The FlexColorScheme defined dark mode ThemeData.
  static ThemeData get dark {
    final theme = FlexThemeData.dark(
      // Using FlexColorScheme built-in FlexScheme enum based colors.
      scheme: FlexScheme.blueM3,
      // Component theme configurations for dark mode.
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        blendOnColors: true,
        useM2StyleDividerInM3: true,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        alignedDropdown: true,
        navigationRailUseIndicator: true,
      ),
      // Direct ThemeData properties.
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    );

    return theme.copyWith(
      textTheme: GoogleFonts.interTextTheme(theme.textTheme),
    );
  }

  // Aliases for backwards compatibility
  static ThemeData get lightTheme => light;
  static ThemeData get darkTheme => dark;
}
