import 'package:flutter/foundation.dart';

/// Configuration runtime de l'application.
///
/// L'URL de base de l'API est résolue à la compilation, dans cet ordre :
/// 1. `--dart-define=API_BASE_URL=...` si fourni (n'importe quel mode) ;
/// 2. sinon, un défaut par mode :
///    - debug : backend local, adresse `10.0.2.2` (loopback hôte vu depuis
///      un émulateur Android — ne fonctionne pas depuis un simulateur iOS
///      ni un appareil physique, qui devront passer
///      `--dart-define=API_BASE_URL=...` explicitement) ;
///    - profile et release : backend de production.
///
/// Le test se fait sur `kDebugMode` (et non `kReleaseMode`) car le trafic
/// HTTP en clair (`usesCleartextTraffic`) n'est autorisé que dans le
/// manifest Android debug — un build profile utilise le manifest main
/// (HTTPS strict) et doit donc pointer vers la production comme release.
///
/// Port du backend local : voir `HopeGestionV2/backend/.env` (`PORT=5001`,
/// prioritaire sur le défaut `5000` codé dans `index.ts`).
abstract final class AppConfig {
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _prodApiBaseUrl = 'https://hopegestion.com/api';
  static const String _localApiBaseUrl = 'http://10.0.2.2:5001/api';

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    return kDebugMode ? _localApiBaseUrl : _prodApiBaseUrl;
  }
}
