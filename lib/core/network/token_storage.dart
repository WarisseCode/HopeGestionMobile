import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Paire de tokens d'authentification (access + refresh).
class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Lecture/écriture des tokens d'authentification dans le stockage
/// sécurisé (`flutter_secure_storage`), avec cache mémoire.
///
/// [load] doit être appelée une fois au démarrage de l'app, avant toute
/// requête authentifiée. Une fois chargé, [accessToken]/[refreshToken]
/// sont des lectures synchrones sur le cache — l'intercepteur Dio (phase
/// 2.3) ne relit donc jamais le stockage sécurisé à chaque requête.
///
/// Aucune méthode de cette classe ne doit jamais logger, imprimer ou
/// inclure un token dans un message d'erreur.
class TokenStorage {
  TokenStorage({this._secureStorage = const FlutterSecureStorage()});

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  final FlutterSecureStorage _secureStorage;

  String? _accessToken;
  String? _refreshToken;

  /// Token d'accès en cache mémoire (null si jamais chargé/écrit, ou après [clear]).
  String? get accessToken => _accessToken;

  /// Token de rafraîchissement en cache mémoire.
  String? get refreshToken => _refreshToken;

  /// Charge la paire de tokens depuis le stockage sécurisé vers le cache mémoire.
  Future<void> load() async {
    _accessToken = await _secureStorage.read(key: _accessTokenKey);
    _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Écrit la nouvelle paire de tokens de façon atomique du point de vue de
  /// l'appelant : le cache mémoire n'est mis à jour qu'une fois les deux
  /// écritures sur le stockage sécurisé terminées.
  ///
  /// À utiliser après un refresh (phase 2.3) : le verrou de refresh ne doit
  /// être relâché qu'après le retour de cet appel, pour qu'aucune requête
  /// concurrente ne puisse lire un access token neuf couplé à un refresh
  /// token pas encore persisté (ou l'inverse).
  Future<void> savePair(TokenPair tokens) async {
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: tokens.accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: tokens.refreshToken),
    ]);
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
  }

  /// Efface les deux tokens du stockage sécurisé et du cache mémoire (déconnexion).
  Future<void> clear() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
    _accessToken = null;
    _refreshToken = null;
  }
}
