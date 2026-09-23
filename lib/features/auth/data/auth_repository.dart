import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import 'app_user.dart';
import 'auth_results.dart';
import 'auth_state.dart';

/// Rôles autorisés côté mobile en v1 — décision produit : "la v1 est
/// réservée aux gestionnaires". `manager` est l'équivalent backend de
/// `gestionnaire` (aucun compte `manager` en production à ce jour, mais le
/// backend le traite de façon interchangeable ailleurs — voir T-013).
/// `admin`, `proprietaire`, `locataire`, `pending` et tout rôle inconnu
/// sont refusés.
const _allowedRoles = {'gestionnaire', 'manager'};

bool _isRoleAllowed(String? role) => role != null && _allowedRoles.contains(role);

/// Source de vérité unique de l'état d'authentification de l'app.
///
/// `ChangeNotifier` + accès global via [instance], comme
/// `ThemeController`/`LocaleController` (`lib/core/theme`,
/// `lib/core/i18n`) — mais avec un constructeur public prenant ses
/// dépendances ([ApiClient], [TokenStorage]) en paramètres, plutôt qu'un
/// constructeur privé sans arguments : les tests construisent leur propre
/// instance directement (avec un `ApiClient`/`TokenStorage` de test) et ne
/// touchent jamais à [instance]/[initialize], qui ne servent qu'à
/// `main.dart`.
class AuthRepository extends ChangeNotifier {
  // Paramètres publics `apiClient`/`tokenStorage` (API de construction
  // lisible) alors que les champs sont privés — même situation que
  // `ApiClient`, voir son commentaire équivalent.
  AuthRepository({required ApiClient apiClient, required TokenStorage tokenStorage})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient,
      // ignore: prefer_initializing_formals
      _tokenStorage = tokenStorage {
    // Émis uniquement quand un refresh est explicitement refusé par le
    // serveur (voir ApiClient) : jamais pour un `logout()` volontaire (qui
    // ne passe pas par ce flux) ni pour une coupure réseau transitoire.
    _sessionExpiredSubscription = _apiClient.sessionExpired.listen((_) {
      _setState(
        const AuthUnauthenticated(message: 'Session expirée, reconnectez-vous.'),
      );
    });
  }

  static AuthRepository? _instance;

  /// Accès global à l'instance unique construite par `main.dart` via
  /// [initialize]. N'est jamais utilisé par les tests (voir la doc de
  /// classe) : y accéder avant [initialize] est une erreur de programmation.
  static AuthRepository get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'AuthRepository.instance accédée avant AuthRepository.initialize().',
      );
    }
    return current;
  }

  /// À appeler une seule fois, dans `main()`, avant `runApp`.
  static void initialize(AuthRepository repository) {
    _instance = repository;
  }

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Accès au client HTTP authentifié unique de l'app (voir `main.dart`),
  /// pour les repositories d'autres features (ex. `DashboardRepository`)
  /// qui doivent réutiliser le même `ApiClient` — même token en cache,
  /// même logique de refresh — plutôt que d'en construire un second en
  /// parallèle, ce qui dupliquerait cette logique de façon incohérente.
  ApiClient get apiClient => _apiClient;
  late final StreamSubscription<void> _sessionExpiredSubscription;

  AuthState _state = const AuthInitializing();

  AuthState get state => _state;

  void _setState(AuthState next) {
    _state = next;
    notifyListeners();
  }

  /// Vérifie la session au démarrage. Pas de tokens en cache →
  /// `unauthenticated` sans appel réseau. Tokens présents → `GET
  /// /auth/profile` (le refresh, s'il est nécessaire, est géré par
  /// `ApiClient`, de façon transparente ici) :
  /// - rôle autorisé → `authenticated` ;
  /// - rôle refusé → tokens effacés, `unsupportedRole` ;
  /// - échec réseau/timeout/serveur → `offline`, tokens CONSERVÉS (on ne
  ///   sait pas si la session est encore valide, pas de raison de
  ///   déconnecter pour un problème de réseau) ;
  /// - 401 → `unauthenticated` (les tokens ont déjà été traités par
  ///   `ApiClient` : soit le refresh a réussi et cette branche n'est pas
  ///   atteinte, soit il a été explicitement refusé et les tokens sont déjà
  ///   effacés côté `ApiClient`/`TokenStorage`).
  Future<void> restoreSession() async {
    _setState(const AuthInitializing());

    if (_tokenStorage.accessToken == null || _tokenStorage.refreshToken == null) {
      _setState(const AuthUnauthenticated());
      return;
    }

    await _loadProfileAndSetState();
  }

  /// Relance [restoreSession] depuis l'état `offline`.
  Future<void> retry() => restoreSession();

  /// `GET /auth/profile`, puis classification du rôle → `authenticated`,
  /// `unsupportedRole`, `offline` (réseau/serveur/profil illisible, tokens
  /// conservés) ou `unauthenticated` (401). Partagée par [restoreSession] et
  /// [login] : contrairement à [restoreSession], ne pose PAS
  /// `AuthInitializing` avant l'appel — [login] l'appelle alors que l'état
  /// courant est déjà `unauthenticated`, et faire clignoter un écran de
  /// chargement plein écran juste pour récupérer le profil serait un
  /// scintillement inutile une fois l'écran de connexion affiché.
  Future<void> _loadProfileAndSetState() async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/auth/profile',
      );
      final rawUser = response.data?['user'];
      if (rawUser is! Map<String, dynamic>) {
        throw const FormatException(
          'Réponse de /auth/profile sans champ "user" exploitable.',
        );
      }
      final user = AppUser.fromJson(rawUser);

      if (!_isRoleAllowed(user.role)) {
        await _tokenStorage.clear();
        _setState(const AuthUnsupportedRole());
        return;
      }

      _setState(AuthAuthenticated(user));
    } on ApiException catch (e) {
      switch (e.type) {
        case ApiExceptionType.network:
        case ApiExceptionType.timeout:
        case ApiExceptionType.server:
          _setState(const AuthOffline());
        case ApiExceptionType.unauthorized:
        default:
          _setState(const AuthUnauthenticated());
      }
    } on FormatException {
      // Profil illisible (200 reçu, mais forme inattendue) : ce n'est ni un
      // problème réseau ni serveur au sens d'ApiException, mais on ne sait
      // pas non plus si la session est valide. Traité comme `offline` :
      // tokens conservés, l'utilisateur peut relancer via retry() — plutôt
      // que de le déconnecter pour un bug client de parsing.
      _setState(const AuthOffline());
    }
  }

  /// `POST /auth/mobile/login`, puis contrôle du rôle **avant** tout
  /// enregistrement de token. Si le rôle est autorisé, les tokens sont
  /// enregistrés puis le profil est récupéré (réutilise [restoreSession]
  /// pour ne pas dupliquer sa logique de classification).
  Future<LoginResult> login(String email, String password) async {
    final Map<String, dynamic> data;
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/auth/mobile/login',
        method: 'POST',
        data: {'email': email, 'password': password},
      );
      data = response.data!;
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.unauthorized) {
        return LoginInvalidCredentials(e.message);
      }
      if (e.type == ApiExceptionType.forbidden && e.data?['isVerified'] == false) {
        return LoginEmailNotVerified(email);
      }
      return LoginFailure(e.message, e.type);
    }

    final role = data['role'] as String?;
    if (!_isRoleAllowed(role)) {
      // Jamais enregistré : révocation au mieux (attendue pour rester
      // déterministe côté appelant — `_revokeRefreshToken` avale déjà
      // toute erreur, donc l'attendre ne peut pas faire échouer `login`).
      final refreshToken = data['refreshToken'] as String?;
      if (refreshToken != null) {
        await _revokeRefreshToken(refreshToken);
      }
      _setState(const AuthUnsupportedRole());
      return const LoginUnsupportedRole();
    }

    await _tokenStorage.savePair(
      TokenPair(
        accessToken: data['token'] as String,
        refreshToken: data['refreshToken'] as String,
      ),
    );

    await _loadProfileAndSetState();
    return switch (_state) {
      AuthAuthenticated(user: final user) => LoginSuccess(user),
      // Rôle déjà validé ci-dessus ; seul un échec réseau juste après (entre
      // le login et /auth/profile) peut amener ici, tokens déjà enregistrés.
      _ => const LoginFailure(
        'Connexion réussie, mais votre profil est momentanément indisponible. '
        'Réessayez.',
        ApiExceptionType.unknown,
      ),
    };
  }

  /// `POST /auth/verify-email`, en ignorant le token renvoyé (canal web —
  /// voir `HopeGestionV2/docs/API_DOCUMENTATION_MOBILE.md` § 2.4), puis
  /// `POST /auth/mobile/login` avec les mêmes identifiants pour obtenir une
  /// paire de tokens du canal mobile. [password] n'est conservé qu'en
  /// mémoire le temps de cet appel (paramètre local, jamais stocké dans un
  /// champ de cette classe) : jamais écrit sur le disque, jamais loggé.
  Future<VerifyEmailResult> verifyEmail(
    String email,
    String otp,
    String password,
  ) async {
    try {
      await _apiClient.request<Map<String, dynamic>>(
        '/auth/verify-email',
        method: 'POST',
        data: {'email': email, 'otp': otp},
      );
    } on ApiException catch (e) {
      return VerifyEmailFailure(e.message, e.type);
    }

    final loginResult = await login(email, password);
    return switch (loginResult) {
      LoginSuccess(user: final user) => VerifyEmailSuccess(user),
      _ => VerifyEmailLoginFailed(loginResult),
    };
  }

  /// `POST /auth/register`. Le rôle n'est jamais envoyé par le client : le
  /// backend applique `gestionnaire` par défaut quand `userType` est omis
  /// (vérifié en phase 3.1 dans `AuthService.register`), ce qui correspond
  /// déjà à la politique "v1 réservée aux gestionnaires". Ne change pas
  /// [state] : le compte créé est `is_verified: false` tant que l'OTP n'a
  /// pas été validé — c'est [verifyEmail], ensuite, qui mène à
  /// `authenticated`.
  Future<RegisterResult> register({
    required String nom,
    required String prenoms,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      await _apiClient.request<Map<String, dynamic>>(
        '/auth/register',
        method: 'POST',
        data: {
          'nom': nom,
          'prenoms': prenoms,
          'email': email,
          'telephone': telephone,
          'password': password,
        },
      );
      return const RegisterSuccess();
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return RegisterEmailTaken(e.message);
      }
      if (e.type == ApiExceptionType.validation) {
        return RegisterValidationFailed(e.message, e.fieldErrors);
      }
      return RegisterFailure(e.message, e.type);
    }
  }

  /// `PUT /auth/profile`. Doit être appelée depuis l'état `authenticated`
  /// (seul écran qui l'appelle, `ProfilScreen`, n'est jamais atteint
  /// autrement) — une erreur de programmation sinon, signalée par un
  /// `StateError` plutôt qu'un échec silencieux.
  ///
  /// Le backend ne renvoie que `{message}`, jamais l'utilisateur mis à jour
  /// (vérifié en 4.1) : après un succès, `state` est donc mis à jour
  /// LOCALEMENT (`copyWith`) plutôt qu'en refaisant un `GET /auth/profile`.
  /// `preferences`/`photo_url` sont renvoyés INCHANGÉS depuis l'utilisateur
  /// courant (voir la doc de `AppUser.preferences`) : cette phase ne les
  /// édite pas, et les omettre casserait silencieusement la mise à jour
  /// côté backend.
  Future<UpdateProfileResult> updateProfile({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
  }) async {
    final current = _state;
    if (current is! AuthAuthenticated) {
      throw StateError(
        'AuthRepository.updateProfile() appelée hors de l\'état authenticated.',
      );
    }

    try {
      await _apiClient.request<Map<String, dynamic>>(
        '/auth/profile',
        method: 'PUT',
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'telephone': telephone,
          'preferences': current.user.preferences,
          'photo_url': current.user.avatarUrl,
        },
      );
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.validation) {
        return UpdateProfileValidationFailed(e.message, e.fieldErrors);
      }
      return UpdateProfileFailure(e.message, e.type);
    }

    final updatedUser = current.user.copyWith(
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
    );
    _setState(AuthAuthenticated(updatedUser));
    return UpdateProfileSuccess(updatedUser);
  }

  /// `POST /auth/change-password`. Ne change jamais [state]. Distingue le
  /// seul cas métier demandé (mot de passe actuel incorrect, 401) des
  /// erreurs de validation et de transport.
  ///
  /// Piège connu, non corrigé ici (hors périmètre — comportement générique
  /// d'`ApiClient`, déjà commité) : un 401 sur cette route N'EST PAS une
  /// session expirée, mais `ApiClient` ne peut pas le distinguer d'un vrai
  /// 401 d'authentification — il tente donc un refresh (qui réussit,
  /// puisque la session est valide) puis rejoue la requête, qui échoue à
  /// nouveau avec le même 401 "métier". Le résultat final renvoyé ici reste
  /// correct ([ChangePasswordWrongCurrent] avec le bon message), au prix
  /// d'un aller-retour réseau superflu à chaque mot de passe actuel erroné.
  Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.request<Map<String, dynamic>>(
        '/auth/change-password',
        method: 'POST',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return const ChangePasswordSuccess();
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.unauthorized) {
        return ChangePasswordWrongCurrent(e.message);
      }
      if (e.type == ApiExceptionType.validation) {
        return ChangePasswordValidationFailed(e.message, e.fieldErrors);
      }
      return ChangePasswordFailure(e.message, e.type);
    }
  }

  /// `POST /auth/resend-otp`. Anti-énumération UNIQUEMENT quand l'email est
  /// inconnu (200 silencieux dans ce cas). Si l'email existe mais est déjà
  /// vérifié, le backend renvoie un 400 explicite ("Cet email est déjà
  /// vérifié. Connectez-vous.") — **pas** un 200 systématique (vérifié dans
  /// `AuthService.resendOtp` ; à l'usage, ce 400 remonte via
  /// [ResendOtpFailure] et son message, déjà correct pour l'utilisateur,
  /// peut être affiché tel quel).
  Future<ResendOtpResult> resendOtp(String email) async {
    try {
      await _apiClient.request<void>(
        '/auth/resend-otp',
        method: 'POST',
        data: {'email': email},
      );
      return const ResendOtpSuccess();
    } on ApiException catch (e) {
      return ResendOtpFailure(e.message, e.type);
    }
  }

  /// Capture le refresh token, efface la session LOCALEMENT tout de suite
  /// (l'utilisateur est déconnecté même hors ligne), puis tente de révoquer
  /// le refresh token côté serveur au mieux — une erreur réseau ici est
  /// ignorée, `logout()` ne doit jamais rester bloquée ni échouer à cause
  /// d'elle.
  Future<void> logout() async {
    final refreshToken = _tokenStorage.refreshToken;
    await _tokenStorage.clear();
    _setState(const AuthUnauthenticated());

    if (refreshToken != null) {
      await _revokeRefreshToken(refreshToken);
    }
  }

  Future<void> _revokeRefreshToken(String refreshToken) async {
    try {
      await _apiClient.request<void>(
        '/auth/mobile/logout',
        method: 'POST',
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {
      // Au mieux : la révocation serveur échoue silencieusement, sans
      // impact sur l'état local (déjà effacé/jamais enregistré).
    }
  }

  @override
  void dispose() {
    unawaited(_sessionExpiredSubscription.cancel());
    super.dispose();
  }
}
