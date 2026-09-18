import 'package:flutter/foundation.dart';

enum AppLanguage { fr, en }

/// Contrôleur global de la langue de l'application.
///
/// Implémentation volontairement légère (pas de package d'internationalisation,
/// pas de génération de code) : voir [AppStrings] pour le dictionnaire de
/// traductions associé. Périmètre actuel limité au Dashboard et aux
/// Paramètres, en attendant une éventuelle généralisation au reste de l'app.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  AppLanguage _language = AppLanguage.fr;

  AppLanguage get language => _language;

  bool get isEnglish => _language == AppLanguage.en;

  String get label => _language == AppLanguage.fr ? 'Français' : 'English';

  void setLanguage(AppLanguage value) {
    if (_language == value) return;
    _language = value;
    notifyListeners();
  }
}
