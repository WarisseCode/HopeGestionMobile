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

  /// Origine du serveur, sans le suffixe `/api` — même construction que
  /// `API_BASE` côté web (`frontend/src/config/api.ts`).
  static String get filesBaseUrl =>
      apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  /// Résout l'URL d'un fichier renvoyé par le backend (`photo`/`photos`
  /// d'un immeuble, etc.). `POST /api/upload` renvoie un chemin relatif
  /// (`/uploads/...`) tant que Digital Ocean Spaces n'est pas configuré —
  /// c'est le cas actuellement en production (`uploadRoutes.ts` : fallback
  /// disque local si `SPACES_KEY`/`SPACES_SECRET`/... sont absents),
  /// confirmé par le web qui préfixe systématiquement avec `API_BASE`
  /// avant d'afficher une image (`ImageUpload.tsx`). Si Spaces est activé
  /// un jour, l'URL renvoyée sera déjà absolue et cette fonction la laisse
  /// telle quelle.
  static String resolveFileUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$filesBaseUrl$path';
  }
}
