import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Pourquoi le token n'a pas pu être rafraîchi (voir [_RefreshOutcome]).
enum _RefreshFailureKind {
  /// Le serveur a explicitement refusé le refresh token (401/400) : la
  /// session est bien terminée, les tokens sont effacés et
  /// [ApiClient.sessionExpired] est émis.
  deauth,

  /// Échec réseau/timeout/429/5xx, ou réponse 200 mal formée : on ne SAIT
  /// PAS si la session est valide ou non, donc on la garde. L'appelant
  /// reçoit une erreur reflétant cette cause précise, pas le 401 d'origine.
  transient,

  /// Le refresh a réussi côté serveur mais [TokenStorage.savePairIfCurrent]
  /// a refusé d'écrire : une déconnexion volontaire a eu lieu pendant
  /// l'appel réseau. Pas de nouvel événement (déjà géré par le [clear]
  /// explicite), le 401 d'origine est la bonne erreur à remonter.
  aborted,
}

class _RefreshOutcome {
  const _RefreshOutcome.success(this.accessToken)
    : failureKind = null,
      failureError = null;

  const _RefreshOutcome.failure(this.failureKind, this.failureError)
    : accessToken = null;

  final String? accessToken;
  final _RefreshFailureKind? failureKind;
  final Object? failureError;
}

/// Client HTTP unique pour parler au backend HopeGestionV2.
///
/// Deux responsabilités, via un intercepteur Dio sur [dio] :
/// 1. Attache `Authorization: Bearer <accessToken>` (depuis le cache mémoire
///    de [TokenStorage], jamais une relecture du stockage sécurisé) sur
///    chaque requête sortante — sauf vers `/auth/mobile/*` (login/refresh/
///    logout), qui ne doit jamais porter un ancien token.
/// 2. Sur un 401 (hors routes publiques `/auth/*` sans token — voir
///    [_isPublicAuthRoute] — qui ne peuvent de toute façon jamais y
///    répondre légitimement), tente un refresh (`POST /auth/mobile/refresh`,
///    contrat vérifié dans
///    `HopeGestionV2/backend/routes/authRoutes.ts` — access token 15 min /
///    refresh token 7 jours, voir `AuthService.ts`) puis rejoue la requête
///    d'origine avec le nouveau token. Les 401 concurrents partagent un seul
///    appel réseau ([_refreshFuture]).
///
/// Le refresh est fait sur [_refreshDio], une instance Dio séparée SANS
/// l'intercepteur ci-dessus : sinon un 401 sur l'appel de refresh
/// déclencherait une nouvelle tentative de refresh, en boucle.
///
/// Seul un refresh **explicitement refusé** par le serveur (401/400)
/// efface les tokens et émet [sessionExpired] : un réseau mobile
/// intermittent (coupure, timeout, 429, 5xx, réponse mal formée) ne doit
/// jamais déconnecter l'utilisateur — les tokens sont conservés et
/// l'appelant reçoit une erreur typée reflétant la vraie cause.
///
/// Pour des exceptions typées ([ApiException]) plutôt que des
/// [DioException] brutes, utiliser [request] plutôt que [dio] directement.
class ApiClient {
  // Le paramètre public reste `tokenStorage` (API de construction lisible)
  // alors que le champ est privé (`_tokenStorage`) ; les deux ne peuvent pas
  // partager un nom, d'où l'affectation explicite ci-dessous plutôt qu'un
  // "initializing formal".
  ApiClient({required TokenStorage tokenStorage, Dio? dio, Dio? refreshDio})
    // ignore: prefer_initializing_formals
    : _tokenStorage = tokenStorage,
      dio = dio ?? Dio(_defaultBaseOptions()),
      _refreshDio = refreshDio ?? Dio(_defaultBaseOptions()) {
    this.dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
    // Ajouté APRÈS l'intercepteur d'auth : ne voit donc que le résultat
    // final (après un éventuel refresh+rejeu), jamais le 401 intermédiaire.
    // Ni en-têtes ni corps : jamais de token ou de données utilisateur dans
    // les logs, même en debug.
    if (kDebugMode) {
      this.dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
        ),
      );
    }
  }

  // Valeurs adaptées à un réseau mobile 2G/3G intermittent (contexte Bénin) :
  // assez généreuses pour ne pas déclencher de faux timeouts sur une
  // connexion lente, assez courtes pour ne pas bloquer l'UI indéfiniment.
  // Pas d'en-tête `Origin` (spécifique navigateur/web, non pertinent ici) ni
  // de cookie manager (le mobile transporte le refresh token dans le corps
  // JSON, jamais par cookie — voir `TokenStorage`).
  static BaseOptions _defaultBaseOptions() => BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  );

  /// Client HTTP applicatif : intercepteur d'auth/refresh actif. Accès
  /// direct disponible pour les cas bas niveau ; préférer [request] pour des
  /// erreurs typées ([ApiException]).
  final Dio dio;

  /// Client dédié à l'appel de refresh, sans l'intercepteur ci-dessus.
  final Dio _refreshDio;

  final TokenStorage _tokenStorage;

  /// Refresh en cours, partagé par tous les 401 concurrents. `null` quand
  /// aucun refresh n'est en vol.
  Future<_RefreshOutcome>? _refreshFuture;

  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  /// Émis UNIQUEMENT quand un refresh est explicitement refusé par le
  /// serveur (401/400) et que les tokens viennent d'être effacés. Jamais
  /// émis pour un [TokenStorage.clear] volontaire (déconnexion depuis
  /// l'app), ni pour un échec réseau/timeout/429/5xx transitoire.
  Stream<void> get sessionExpired => _sessionExpiredController.stream;

  void dispose() {
    unawaited(_sessionExpiredController.close());
  }

  /// Enveloppe [dio] et convertit toute [DioException] en [ApiException].
  /// Voir la documentation de classe : c'est la surface publique
  /// recommandée pour le code applicatif (repositories, écrans...).
  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // `/auth/mobile/*` (login/refresh/logout) : jamais d'Authorization, un
  // ancien token n'y a aucun sens.
  bool _isMobileAuthRoute(String path) => path.contains('/auth/mobile/');

  // Routes `/auth/*` PUBLIQUES (aucun token requis côté backend) : un 401
  // qui en provient ne peut jamais être résolu par un refresh (ex. mauvais
  // mot de passe sur `/auth/mobile/login`), et ne doit ni en déclencher un,
  // ni toucher aux tokens déjà stockés.
  //
  // Liste vérifiée route par route dans le code réel (pas de mémoire) :
  // `HopeGestionV2/backend/routes/authRoutes.ts` et `googleAuthRoutes.ts`,
  // en cherchant l'absence des deux middlewares d'auth (`protect`,
  // `verifyToken`). Volontairement PAS un simple `path.contains('/auth/')` :
  // des routes protégées existent sous `/auth/*` — `GET/PUT /auth/profile`,
  // `POST /auth/change-password`, `POST /auth/invite-user`,
  // `POST /auth/create-guest`, `GET /auth/test-email` (toutes `verifyToken`
  // ou `protect`) et `PATCH /auth/complete-profile` (`protect`, depuis le
  // correctif lot 1b) — qui DOIVENT pouvoir déclencher un refresh sur un
  // 401 (access token expiré), sans quoi un utilisateur qui rouvre l'app
  // après 15 min serait bloqué malgré un refresh token valide.
  static const Set<String> _publicAuthPaths = {
    '/auth/register',
    '/auth/login',
    '/auth/verify-email',
    '/auth/resend-otp',
    '/auth/refresh', // Web (cookie httpOnly) — non utilisée par le mobile,
    '/auth/logout', // mais publique aussi côté backend : cohérence de la règle.
    '/auth/mobile/login',
    '/auth/mobile/refresh',
    '/auth/mobile/logout',
    // Connexion Google mobile : un 401 (jeton Google invalide, compte
    // inactif...) ne doit jamais déclencher de refresh.
    '/auth/mobile/google',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/auth/accept-invite',
    '/auth/login-with-key',
    '/auth/google',
  };

  bool _isPublicAuthRoute(String rawPath) {
    // Comparaison sur le chemin seul, sans query string (`Uri.parse` gère
    // aussi bien un chemin relatif tel que produit par nos appels).
    final path = Uri.parse(rawPath).path;
    if (_publicAuthPaths.contains(path)) return true;
    // Segment dynamique (`:token`) : préfixe plutôt qu'égalité stricte.
    return path.startsWith('/auth/validate-reset-token/');
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isMobileAuthRoute(options.path)) {
      final accessToken = _tokenStorage.accessToken;
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;

    if (_isPublicAuthRoute(requestOptions.path)) {
      handler.next(err);
      return;
    }

    final alreadyRetried = requestOptions.extra['hg_retried'] == true;
    if (err.response?.statusCode != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    // Amélioration : un refresh déclenché par une AUTRE requête a pu se
    // terminer entre l'envoi de celle-ci et son 401 — le cache contient déjà
    // un token différent de celui envoyé. Le rejouer directement dessus
    // évite un refresh redondant.
    final currentAccessToken = _tokenStorage.accessToken;
    final sentAuthHeader = requestOptions.headers['Authorization'] as String?;
    if (currentAccessToken != null &&
        sentAuthHeader != 'Bearer $currentAccessToken') {
      await _retryWithToken(requestOptions, currentAccessToken, handler);
      return;
    }

    final outcome = await _refreshAccessToken();
    final failureKind = outcome.failureKind;

    if (failureKind == null) {
      await _retryWithToken(requestOptions, outcome.accessToken!, handler);
      return;
    }

    if (failureKind == _RefreshFailureKind.transient) {
      handler.next(_transientRefreshError(requestOptions, outcome.failureError));
      return;
    }

    // deauth (401/400 d'origine est la bonne erreur à remonter, tokens déjà
    // effacés et événement déjà émis dans _performRefresh) et aborted
    // (déconnexion volontaire entre-temps, idem sans événement) :
    handler.next(err);
  }

  Future<void> _retryWithToken(
    RequestOptions requestOptions,
    String accessToken,
    ErrorInterceptorHandler handler,
  ) async {
    requestOptions.headers['Authorization'] = 'Bearer $accessToken';
    requestOptions.extra = {...requestOptions.extra, 'hg_retried': true};

    // Un FormData ne peut être envoyé qu'une fois (flux déjà consommé) :
    // sans ce clone, le rejeu d'un upload échouerait silencieusement.
    final data = requestOptions.data;
    if (data is FormData) {
      requestOptions.data = data.clone();
    }

    try {
      final response = await dio.fetch(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Construit, à partir de l'échec du refresh, une erreur qui porte les
  /// options de la requête D'ORIGINE (pour rester cohérente pour
  /// l'appelant) mais le type/la réponse du refresh (pour que
  /// [ApiException.fromDioException] la classe correctement — network,
  /// timeout, rateLimited, server... et surtout PAS unauthorized).
  DioException _transientRefreshError(
    RequestOptions requestOptions,
    Object? refreshError,
  ) {
    if (refreshError is DioException) {
      return DioException(
        requestOptions: requestOptions,
        type: refreshError.type,
        error: refreshError.error,
        response: refreshError.response,
        message: refreshError.message,
      );
    }
    return DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.unknown,
      error: refreshError,
      message: 'Réponse de rafraîchissement de session invalide.',
    );
  }

  /// Un seul refresh réseau à la fois : les 401 concurrents attendent tous
  /// le même [_refreshFuture] plutôt que d'en déclencher un chacun.
  Future<_RefreshOutcome> _refreshAccessToken() {
    return _refreshFuture ??= _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<_RefreshOutcome> _performRefresh() async {
    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken == null) {
      await _tokenStorage.clear();
      return const _RefreshOutcome.failure(_RefreshFailureKind.deauth, null);
    }

    // Capturée AVANT l'appel réseau : si une déconnexion survient pendant
    // le refresh, savePairIfCurrent le détectera et n'écrira rien.
    final expectedGeneration = _tokenStorage.generation;

    final Response<dynamic> response;
    try {
      response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/mobile/refresh',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 400) {
        // Le serveur refuse explicitement ce refresh token : la session est
        // bien terminée (pas une coupure réseau) — seul cas qui déconnecte.
        await _tokenStorage.clear();
        _sessionExpiredController.add(null);
        return _RefreshOutcome.failure(_RefreshFailureKind.deauth, e);
      }
      // Réseau intermittent, timeout, 429, 5xx... : on garde la session, on
      // ne sait pas si le refresh token est encore valide.
      return _RefreshOutcome.failure(_RefreshFailureKind.transient, e);
    }

    final TokenPair tokens;
    try {
      final data = response.data!;
      final newAccessToken = data['token'] as String;
      final newRefreshToken = data['refreshToken'] as String;
      tokens = TokenPair(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
    } catch (e) {
      // 200 mais champs absents/mal typés : ni un succès, ni une preuve que
      // le refresh token est invalide — on garde la session.
      return _RefreshOutcome.failure(_RefreshFailureKind.transient, e);
    }

    final wrote = await _tokenStorage.savePairIfCurrent(
      tokens,
      expectedGeneration,
    );
    if (!wrote) {
      return const _RefreshOutcome.failure(_RefreshFailureKind.aborted, null);
    }
    return _RefreshOutcome.success(tokens.accessToken);
  }
}
