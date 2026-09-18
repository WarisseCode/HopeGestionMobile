import 'package:flutter/material.dart';

/// Ombres portées officielles HopeGestion Mobile
abstract class AppShadows {
  /// Ombre douce pour les cartes standards
  /// 0 8px 24px rgba(26, 46, 42, 0.08)
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color.fromRGBO(26, 46, 42, 0.08),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  /// Ombre d'action pour le FAB et les boutons primaires
  /// 0 10px 20px rgba(0, 154, 159, 0.28)
  static const List<BoxShadow> action = [
    BoxShadow(
      color: Color.fromRGBO(0, 154, 159, 0.28),
      offset: Offset(0, 10),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  /// Ombre pour la barre de navigation flottante
  static const List<BoxShadow> navBar = [
    BoxShadow(
      color: Color.fromRGBO(26, 46, 42, 0.10),
      offset: Offset(0, 4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];
}
