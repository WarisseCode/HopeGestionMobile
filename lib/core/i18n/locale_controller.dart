import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { fr, en }

/// Contrôleur global de la langue de l'application.
///
/// Implémentation volontairement légère (pas de package d'internationalisation,
/// pas de génération de code) : voir [AppStrings] pour le dictionnaire de
/// traductions associé. Périmètre actuel limité au Dashboard et aux
/// Paramètres, en attendant une éventuelle généralisation au reste de l'app.
///
/// Le choix est persisté via `shared_preferences` (nom de l'enum, ex. `en`),
/// sur le même modèle que `OnboardingStore` : [load] est appelé dans
/// `main()` avant `runApp`.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  /// Instance indépendante du singleton, pour simuler un redémarrage de
  /// l'app dans les tests (nouveau cache mémoire, même stockage).
  @visibleForTesting
  LocaleController.forTesting();

  static final LocaleController instance = LocaleController._();

  static const _key = 'app_language';

  AppLanguage _language = AppLanguage.fr;

  AppLanguage get language => _language;

  bool get isEnglish => _language == AppLanguage.en;

  String get label => _language == AppLanguage.fr ? 'Français' : 'English';

  // `SharedPreferencesAsync()` reconstruit à chaque appel plutôt que stocké
  // dans un champ : voir la justification dans `OnboardingStore.load`.
  Future<void> load() async {
    final saved = await SharedPreferencesAsync().getString(_key);
    // Valeur inconnue (ex. langue retirée dans une version ultérieure) :
    // on garde la langue courante plutôt que de lever une exception.
    final match = AppLanguage.values.where((l) => l.name == saved);
    if (match.isEmpty || match.first == _language) return;
    _language = match.first;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (_language == value) return;
    _language = value;
    notifyListeners();
    // Persistance au mieux : voir `ThemeController.setDark`.
    try {
      await SharedPreferencesAsync().setString(_key, value.name);
    } catch (_) {}
  }
}
