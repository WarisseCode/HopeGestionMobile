import 'dart:convert';

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
/// La paire est stockée sous une SEULE clé, encodée en JSON
/// (`{"access": ..., "refresh": ...}`) : une écriture unique est
/// réellement atomique, contrairement à deux écritures séparées où un
/// échec partiel pouvait laisser un ancien refresh token (déjà révoqué
/// par la rotation) associé à un nouvel access token sur le disque. Les
/// anciennes clés séparées (versions précédentes de cette classe) ne sont
/// jamais relues : sur un appareil qui les aurait, elles restent
/// simplement ignorées (équivalent à une absence de session).
///
/// [generation] identifie l'état d'authentification courant ; il avance à
/// chaque [clear] (déconnexion). [savePairIfCurrent] s'en sert pour qu'un
/// refresh qui se termine après une déconnexion ne réécrive jamais de
/// tokens (voir l'intercepteur Dio, phase 2.3).
///
/// Aucune méthode de cette classe ne doit jamais logger, imprimer ou
/// inclure un token (ni le JSON brut) dans un message d'erreur.
class TokenStorage {
  TokenStorage({this._secureStorage = const FlutterSecureStorage()});

  static const _storageKey = 'auth_token_pair';

  final FlutterSecureStorage _secureStorage;

  String? _accessToken;
  String? _refreshToken;
  int _generation = 0;

  /// Token d'accès en cache mémoire (null si jamais chargé/écrit, ou après [clear]).
  String? get accessToken => _accessToken;

  /// Token de rafraîchissement en cache mémoire.
  String? get refreshToken => _refreshToken;

  /// Identifiant de l'état d'authentification courant. Avance à chaque [clear].
  int get generation => _generation;

  /// Charge la paire de tokens depuis le stockage sécurisé vers le cache
  /// mémoire. Ne lance jamais d'exception : une lecture qui échoue (clé
  /// Keystore invalidée, stockage corrompu...) ou un contenu mal formé ou
  /// incomplet efface le stockage et laisse le cache à `null`, plutôt que
  /// de faire planter le démarrage de l'app.
  Future<void> load() async {
    String? raw;
    try {
      raw = await _secureStorage.read(key: _storageKey);
    } catch (_) {
      await _eraseStorageQuietly();
      _accessToken = null;
      _refreshToken = null;
      return;
    }

    if (raw == null) {
      _accessToken = null;
      _refreshToken = null;
      return;
    }

    final pair = _decodePair(raw);
    if (pair == null) {
      await _eraseStorageQuietly();
      _accessToken = null;
      _refreshToken = null;
      return;
    }

    _accessToken = pair.accessToken;
    _refreshToken = pair.refreshToken;
  }

  /// Écrit la nouvelle paire de tokens sans condition. Réservée au login
  /// (aucun refresh concurrent ne peut être en cours à ce moment) ; un
  /// refresh doit passer par [savePairIfCurrent].
  Future<void> savePair(TokenPair tokens) async {
    await _writeToStorage(tokens);
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
  }

  /// Écrit la nouvelle paire UNIQUEMENT si [generation] n'a pas changé
  /// depuis [expectedGeneration] (capturée par l'appelant au démarrage de
  /// son refresh) — vérifié avant l'écriture ET après. Si une déconnexion
  /// ([clear]) survient pendant l'écriture, ce qui vient d'être écrit est
  /// effacé et la méthode renvoie `false` sans mettre à jour le cache : un
  /// refresh qui se termine après une déconnexion ne doit jamais
  /// reconnecter l'utilisateur.
  ///
  /// Renvoie `true` si la paire a bien été écrite et mise en cache.
  Future<bool> savePairIfCurrent(
    TokenPair tokens,
    int expectedGeneration,
  ) async {
    if (_generation != expectedGeneration) return false;

    await _writeToStorage(tokens);

    if (_generation != expectedGeneration) {
      await _eraseStorageQuietly();
      return false;
    }

    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    return true;
  }

  /// Efface le token du stockage sécurisé et du cache mémoire
  /// (déconnexion), et fait avancer [generation] : un refresh déjà en
  /// cours ne pourra plus écrire son résultat (voir [savePairIfCurrent]).
  Future<void> clear() async {
    await _secureStorage.delete(key: _storageKey);
    _accessToken = null;
    _refreshToken = null;
    _generation++;
  }

  Future<void> _writeToStorage(TokenPair tokens) {
    return _secureStorage.write(
      key: _storageKey,
      value: jsonEncode({
        'access': tokens.accessToken,
        'refresh': tokens.refreshToken,
      }),
    );
  }

  Future<void> _eraseStorageQuietly() async {
    try {
      await _secureStorage.delete(key: _storageKey);
    } catch (_) {
      // Le stockage est déjà dans un état anormal (c'est pour ça qu'on
      // l'efface) : une erreur ici ne doit pas non plus faire planter l'app.
    }
  }

  TokenPair? _decodePair(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final access = decoded['access'];
        final refresh = decoded['refresh'];
        if (access is String && refresh is String) {
          return TokenPair(accessToken: access, refreshToken: refresh);
        }
      }
    } catch (_) {
      // JSON mal formé : traité comme un contenu absent ci-dessous.
    }
    return null;
  }
}
