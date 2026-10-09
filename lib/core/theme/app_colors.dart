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
///
/// Charte graphique : Bleu profond `#0C3958`, Bleu Hope `#088FE1`, Noir texte
/// `#151B20`, Blanc `#FFFFFF`, Bleu pâle `#EDF6FA`, Gris `#F4F6F7`. Les
/// valeurs dérivées sont calculées ainsi (ratios de contraste WCAG) :
/// - `primaryStrong` : `#0C3958` × 0,9 par canal RGB (10 % de noir) ;
/// - `mutedForeground` : `#151B20` mélangé à 35 % de blanc → 4,9:1 à 5,4:1
///   sur blanc, `#F4F6F7` et `#EDF6FA` (≥ 4,5:1 texte courant) ;
/// - `border` : `#F4F6F7` × 0,9 (= `#151B20` + 85 % de blanc), gris neutre ;
/// - `infoSoft` : `#088FE1` mélangé à 90 % de blanc.
/// Les couleurs de statut (positive/warning/error et leurs Soft) sont
/// inchangées : fonctionnelles, hors charte.
const AppColorPalette lightPalette = AppColorPalette(
  primary: Color(0xFF0C3958),
  primaryStrong: Color(0xFF0B334F),
  primaryForeground: Color(0xFFFFFFFF),
  background: Color(0xFFFFFFFF),
  foreground: Color(0xFF151B20),
  card: Color(0xFFFFFFFF),
  cardForeground: Color(0xFF151B20),
  // Sur mobile, `secondary` est un fond doux (et non une couleur d'action
  // comme côté web) : le bleu pâle de la charte.
  secondary: Color(0xFFEDF6FA),
  muted: Color(0xFFF4F6F7),
  mutedForeground: Color(0xFF676B6E),
  border: Color(0xFFDCDDDE),
  inputBorder: Color(0xFFDCDDDE),
  inputFill: Color(0xFFF4F6F7),
  positive: Color(0xFF00A880),
  positiveSoft: Color(0xFFD6F5E9),
  warning: Color(0xFFE89A2E),
  warningSoft: Color(0xFFFDF2D9),
  error: Color(0xFFE53935),
  errorSoft: Color(0xFFFFEBEE),
  info: Color(0xFF088FE1),
  infoSoft: Color(0xFFE6F4FC),
  phoneFrame: Color(0xFFEDF6FA),
);

/// Palette officielle HopeGestion Mobile — mode sombre.
///
/// Même logique que le web : le Bleu profond `#0C3958` devient le fond, les
/// autres surfaces en sont dérivées par mélange avec du blanc (« tint »).
/// - `card` : fond + 10 % de blanc (`#244D69`) ; `secondary`/`inputFill` :
///   + 6 % ; `muted` : + 15 % ; `border` : + 20 %.
/// - `primary` : le Bleu Hope `#088FE1` n'offre que 3,5:1 sur le fond et
///   2,5:1 sur les cartes (texte < 4,5:1). `#4EBCFF` (choix web) monte à
///   5,7:1 sur le fond mais 4,3:1 seulement sur `card` ; `#6CC8FF` atteint
///   6,5:1 sur le fond et 4,9:1 sur `card`, d'où ce choix. `#4EBCFF` est
///   gardé pour `primaryStrong` (état sélectionné/pressé, composant ≥ 3:1)
///   et `info`.
/// - `primaryForeground` : le Bleu profond, 6,5:1 sur `#6CC8FF`.
/// - `mutedForeground` : `#F4F6F7` + 25 % du fond → 7,0:1 sur fond, 5,2:1
///   sur `card`.
/// Couleurs de statut inchangées (hors charte).
const AppColorPalette darkPalette = AppColorPalette(
  primary: Color(0xFF6CC8FF),
  primaryStrong: Color(0xFF4EBCFF),
  primaryForeground: Color(0xFF0C3958),
  background: Color(0xFF0C3958),
  foreground: Color(0xFFF4F6F7),
  card: Color(0xFF244D69),
  cardForeground: Color(0xFFF4F6F7),
  secondary: Color(0xFF1B4562),
  muted: Color(0xFF305771),
  mutedForeground: Color(0xFFBAC7CF),
  border: Color(0xFF3D6179),
  inputBorder: Color(0xFF3D6179),
  inputFill: Color(0xFF1B4562),
  positive: Color(0xFF2ED9A8),
  positiveSoft: Color(0xFF12332B),
  warning: Color(0xFFF0AE4E),
  warningSoft: Color(0xFF3A2E17),
  error: Color(0xFFFF6B64),
  errorSoft: Color(0xFF3A1616),
  info: Color(0xFF4EBCFF),
  // Bleu Hope à 25 % sur le fond.
  infoSoft: Color(0xFF0B4E7A),
  // Fond × 0,8 par canal : cadre légèrement plus sombre que l'écran.
  phoneFrame: Color(0xFF0A2E46),
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
