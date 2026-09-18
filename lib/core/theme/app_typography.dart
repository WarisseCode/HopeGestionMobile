import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typographie officielle HopeGestion Mobile
/// Basée sur IBM Plex Sans (corps & interface) et Libre Baskerville (titres d'accroche)
abstract class AppTypography {
  // --- Titres display / Marque (Libre Baskerville) ---
  static TextStyle displayBrand({
    Color? color,
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.libreBaskerville(
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.5,
    );
  }

  // --- Titres d'écrans (IBM Plex Sans) ---
  /// Utilisé pour "Bonjour, Awa Sarr", "Mes biens", "Nouveau bien" (21px)
  static TextStyle titleScreen({
    Color? color,
    double fontSize = 21,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.ibmPlexSans(
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.3,
    );
  }

  /// Titres de sections ou de cartes (16-18px)
  static TextStyle titleSection({
    Color? color,
    double fontSize = 17,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.ibmPlexSans(
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
    return GoogleFonts.ibmPlexSans(
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.2,
    );
  }

  // --- Corps de texte (IBM Plex Sans) ---
  /// Texte de base (13-14px)
  static TextStyle body({
    Color? color,
    double fontSize = 13.5,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.ibmPlexSans(
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
    return GoogleFonts.ibmPlexSans(
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
    return GoogleFonts.ibmPlexSans(
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
    return GoogleFonts.ibmPlexSans(
      color: color ?? AppColors.mutedForeground,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  // --- Étiquettes & En-têtes secondaires (Uppercase) ---
  /// Utilisé pour les dates ("LUNDI 14 AVRIL"), labels KPI ("ENCAISS.", "FLUX · 7 JOURS")
  static TextStyle labelUppercase({
    Color? color,
    double fontSize = 10.5,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 1.0,
  }) {
    return GoogleFonts.ibmPlexSans(
      color: color ?? AppColors.mutedForeground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  /// Note sous les KPIs (ex: "+12% ce mois", "3 factures")
  static TextStyle kpiNote({
    Color? color,
    double fontSize = 9.5,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.ibmPlexSans(
      color: color ?? AppColors.mutedForeground,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  /// Badges de statut ("PAYÉ", "EN ATTENTE", "OCCUPÉ")
  static TextStyle badge({
    required Color color,
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.ibmPlexSans(
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
    return GoogleFonts.ibmPlexSans(
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
    return GoogleFonts.ibmPlexSans(
      color: color ?? AppColors.foreground,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.1,
    );
  }
}
