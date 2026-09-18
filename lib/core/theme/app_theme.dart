import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Configuration du thème global Flutter pour HopeGestion Mobile
class AppTheme {
  static ThemeData get lightTheme => _themeFrom(lightPalette, Brightness.light);

  static ThemeData get darkTheme => _themeFrom(darkPalette, Brightness.dark);

  static ThemeData _themeFrom(AppColorPalette p, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      primaryColor: p.primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.primary,
        onPrimary: p.primaryForeground,
        secondary: p.secondary,
        onSecondary: p.foreground,
        error: p.error,
        onError: p.primaryForeground,
        surface: p.card,
        onSurface: p.cardForeground,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: p.foreground),
        titleTextStyle: AppTypography.titleScreen(color: p.foreground),
        systemOverlayStyle: brightness == Brightness.dark
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: p.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodySmall(color: p.mutedForeground),
        labelStyle: AppTypography.body(color: p.foreground),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: p.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: p.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: p.error, width: 1),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.primaryForeground,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
          textStyle: AppTypography.button(),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: p.card,
          foregroundColor: p.cardForeground,
          minimumSize: const Size(double.infinity, 48),
          side: BorderSide(color: p.border, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
          textStyle: AppTypography.button(color: p.cardForeground),
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    );
  }
}
