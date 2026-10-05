import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contrôleur global du thème clair/sombre de l'application.
///
/// `AppColors` lit `isDark` en temps réel pour retourner la bonne teinte,
/// et `main.dart` écoute ce contrôleur pour piloter `MaterialApp.themeMode`.
///
/// Le choix est persisté via `shared_preferences`, sur le même modèle que
/// `OnboardingStore` : [load] (appelé dans `main()` avant `runApp`) remplit
/// le cache mémoire, lu ensuite de façon synchrone via [isDark].
class ThemeController extends ChangeNotifier {
  ThemeController._();

  /// Instance indépendante du singleton, pour simuler un redémarrage de
  /// l'app dans les tests (nouveau cache mémoire, même stockage).
  @visibleForTesting
  ThemeController.forTesting();

  static final ThemeController instance = ThemeController._();

  static const _key = 'theme_is_dark';

  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  // `SharedPreferencesAsync()` reconstruit à chaque appel plutôt que stocké
  // dans un champ : voir la justification dans `OnboardingStore.load`.
  Future<void> load() async {
    final saved = await SharedPreferencesAsync().getBool(_key);
    if (saved == null || saved == _isDark) return;
    _isDark = saved;
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    // Persistance au mieux : un échec d'écriture (ou l'absence de plugin,
    // ex. widget tests sans double de stockage) ne doit pas casser le
    // changement de thème en cours, déjà appliqué en mémoire.
    try {
      await SharedPreferencesAsync().setBool(_key, value);
    } catch (_) {}
  }
}
