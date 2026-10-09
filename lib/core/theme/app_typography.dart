import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typographie officielle HopeGestion Mobile : DejaVu Sans (charte
/// graphique), police locale déclarée dans `pubspec.yaml` (`assets/fonts/`).
///
/// Tailles : la charte est exprimée en points imprimés (titre 32-40,
/// sous-titre 16-22, texte 10-12, légende 8-10). Une conversion linéaire ne
/// convient pas (le rapport titre/texte de 4:1 de l'imprimé est trop large
/// pour un écran de téléphone) : on ancre le texte courant 11 pt sur 14 dp
/// (corps standard mobile) et on comprime les grandes tailles avec
/// `dp = 14 × (pt / 11)^(2/3)`, soit titre 28-33 dp, sous-titre 18-22 dp,
/// texte 13-15 dp, légende 11-13 dp.
///
/// DejaVu Sans n'existe qu'en Regular (400) et Bold (700) : les graisses
/// w500/w600 sont rendues avec la graisse disponible la plus proche.
abstract class AppTypography {
  /// Famille de la police locale (voir la section `fonts:` du pubspec).
  static const String fontFamily = 'DejaVu Sans';

  // --- Titres display / Marque (bande « titre » : 28-33 dp) ---
  static TextStyle displayBrand({
    Color? color,
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.5,
    );
  }

  // --- Titres d'écrans (DejaVu Sans) ---
  /// Utilisé pour "Bonjour, Awa Sarr", "Mes biens", "Nouveau bien" (21px)
  static TextStyle titleScreen({
    Color? color,
    double fontSize = 21,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.3,
    );
  }

  /// Titres de sections ou de cartes (bande « sous-titre » : 18-22 dp)
  static TextStyle titleSection({
    Color? color,
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.2,
    );
  }

  /// Valeurs principales de KPIs (18-24px)
  static TextStyle kpiValue({
    Color? color,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.2,
    );
  }

  // --- Corps de texte (DejaVu Sans) ---
  /// Texte de base (13-14px)
  static TextStyle body({
    Color? color,
    double fontSize = 13.5,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.4,
    );
  }

  /// Texte moyen (medium 500) pour libellés importants
  static TextStyle bodyMedium({
    Color? color,
    double fontSize = 13.5,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.4,
    );
  }

  /// Texte secondaire / muted (12px)
  static TextStyle bodySmall({
    Color? color,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.mutedForeground,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  /// Texte de légende ou sous-titre compact (11px)
  static TextStyle caption({
    Color? color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.mutedForeground,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  // --- Étiquettes & En-têtes secondaires (Uppercase) ---
  /// Utilisé pour les dates ("LUNDI 14 AVRIL"), labels KPI ("ENCAISS.", "FLUX · 7 JOURS")
  static TextStyle labelUppercase({
    Color? color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 1.0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.mutedForeground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  /// Note sous les KPIs (ex: "+12% ce mois", "3 factures") — bande
  /// « légende » : 11-13 dp.
  static TextStyle kpiNote({
    Color? color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.mutedForeground,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  /// Badges de statut ("PAYÉ", "EN ATTENTE", "OCCUPÉ")
  static TextStyle badge({
    required Color color,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.3,
    );
  }

  /// Bouton texte (14px semibold)
  static TextStyle button({
    Color? color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.primaryForeground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.2,
    );
  }

  /// Libellé de champ de formulaire (12px, semibold)
  static TextStyle labelField({
    Color? color,
    double fontSize = 12.5,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.1,
    );
  }
}
