import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// Jeu de couleurs immuable pour un thème donné (clair ou sombre).
class AppColorPalette {
  final Color primary;
  final Color primaryStrong;
  final Color primaryForeground;
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color secondary;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color inputBorder;
  final Color inputFill;
  final Color positive;
  final Color positiveSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;
  final Color info;
  final Color infoSoft;
  final Color phoneFrame;

  const AppColorPalette({
    required this.primary,
    required this.primaryStrong,
    required this.primaryForeground,
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.secondary,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.inputBorder,
    required this.inputFill,
    required this.positive,
    required this.positiveSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.info,
    required this.infoSoft,
    required this.phoneFrame,
  });
}

/// Palette officielle HopeGestion Mobile — mode clair.
/// Extraite du Design System et alignée sur les 21 maquettes.
const AppColorPalette lightPalette = AppColorPalette(
  primary: Color(0xFF009A9F),
  primaryStrong: Color(0xFF007A7D),
  primaryForeground: Color(0xFFFFFFFF),
  background: Color(0xFFF0FCFA),
  foreground: Color(0xFF1A2E2A),
  card: Color(0xFFFFFFFF),
  cardForeground: Color(0xFF1A2E2A),
  secondary: Color(0xFFE6F5F3),
  muted: Color(0xFFE8EFEE),
  mutedForeground: Color(0xFF6B7D7A),
  border: Color(0xFFD4E0DE),
  inputBorder: Color(0xFFD4E0DE),
  inputFill: Color(0xFFF5FBFA),
  positive: Color(0xFF00A880),
  positiveSoft: Color(0xFFD6F5E9),
  warning: Color(0xFFE89A2E),
  warningSoft: Color(0xFFFDF2D9),
  error: Color(0xFFE53935),
  errorSoft: Color(0xFFFFEBEE),
  info: Color(0xFF0288D1),
  infoSoft: Color(0xFFE1F5FE),
  phoneFrame: Color(0xFFEDF6F5),
);

/// Palette officielle HopeGestion Mobile — mode sombre.
const AppColorPalette darkPalette = AppColorPalette(
  primary: Color(0xFF1AC4C9),
  primaryStrong: Color(0xFF00A6AB),
  primaryForeground: Color(0xFF00201F),
  background: Color(0xFF0D1512),
  foreground: Color(0xFFEAF3F1),
  card: Color(0xFF16211D),
  cardForeground: Color(0xFFEAF3F1),
  secondary: Color(0xFF1B2C29),
  muted: Color(0xFF223330),
  mutedForeground: Color(0xFF9AB0AC),
  border: Color(0xFF2A3B37),
  inputBorder: Color(0xFF2A3B37),
  inputFill: Color(0xFF1B2622),
  positive: Color(0xFF2ED9A8),
  positiveSoft: Color(0xFF12332B),
  warning: Color(0xFFF0AE4E),
  warningSoft: Color(0xFF3A2E17),
  error: Color(0xFFFF6B64),
  errorSoft: Color(0xFF3A1616),
  info: Color(0xFF4FC3F7),
  infoSoft: Color(0xFF13293A),
  phoneFrame: Color(0xFF10201D),
);

/// Palette de couleurs dynamique HopeGestion Mobile.
///
/// Chaque getter reflète le thème actif (voir [ThemeController]) : le reste
/// de l'app continue d'utiliser `AppColors.xxx` sans rien savoir du mode
/// clair/sombre.
abstract class AppColors {
  static AppColorPalette get _p =>
      ThemeController.instance.isDark ? darkPalette : lightPalette;

  static Color get primary => _p.primary;
  static Color get primaryStrong => _p.primaryStrong;
  static Color get primaryForeground => _p.primaryForeground;
  static Color get background => _p.background;
  static Color get foreground => _p.foreground;
  static Color get card => _p.card;
  static Color get cardForeground => _p.cardForeground;
  static Color get secondary => _p.secondary;
  static Color get muted => _p.muted;
  static Color get mutedForeground => _p.mutedForeground;
  static Color get border => _p.border;
  static Color get inputBorder => _p.inputBorder;
  static Color get inputFill => _p.inputFill;
  static Color get positive => _p.positive;
  static Color get positiveSoft => _p.positiveSoft;
  static Color get warning => _p.warning;
  static Color get warningSoft => _p.warningSoft;
  static Color get error => _p.error;
  static Color get errorSoft => _p.errorSoft;

  /// Alias de [error] pour les champs requis.
  static Color get negative => _p.error;

  static Color get info => _p.info;
  static Color get infoSoft => _p.infoSoft;

  /// Spécifique téléphone / surface.
  static Color get phoneFrame => _p.phoneFrame;
}
