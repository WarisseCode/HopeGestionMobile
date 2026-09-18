import 'package:flutter/material.dart';

/// Contrôleur global du thème clair/sombre de l'application.
///
/// `AppColors` lit `isDark` en temps réel pour retourner la bonne teinte,
/// et `main.dart` écoute ce contrôleur pour piloter `MaterialApp.themeMode`.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void setDark(bool value) {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
  }
}
