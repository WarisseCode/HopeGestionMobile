import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_repository.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_results.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_state.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> _profileJson({
  String role = 'gestionnaire',
  String? telephone = '+2290197000000',
}) => {
  'message': 'Profil récupéré',
  'user': {
    'id': 42,
    'nom': 'Otchade',
    'prenom': 'Warisse',
    'email': 'warisse@example.com',
    'telephone': telephone,
    'role': role,
    'userType': role,
    'isGuest': false,
    'photo_url': null,
    'preferences': <String, dynamic>{},
    'permissions': <String, dynamic>{},
  },
};

/// Construit un `AuthRepository` déjà en état `authenticated` (tokens
/// enregistrés + `restoreSession()`), pour les tests de `updateProfile`/
/// `changePassword` qui n'ont pas besoin de retester le chemin de
/// connexion lui-même (déjà couvert ci-dessus). [refreshResponder] répond
/// par défaut par un refresh réussi : nécessaire même quand le test ne
/// s'intéresse pas au refresh, car un 401 "métier" (ex. mot de passe actuel
/// incorrect) passe par le même mécanisme générique de refresh d'ApiClient
/// avant de remonter (voir la mise en garde dans `AuthRepository
/// .changePassword`).
Future<AuthRepository> _authenticatedRepo({
  required Future<ResponseBody> Function(RequestOptions options) responder,
  Future<ResponseBody> Function(RequestOptions options)? refreshResponder,
}) async {
  final tokenStorage = TokenStorage();
  await tokenStorage.savePair(
    const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
  );
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(responder);
  final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(
      refreshResponder ??
          (options) async =>
              jsonResponse({'token': 'access-2', 'refreshToken': 'refresh-2'}, 200),
    );
  final apiClient = ApiClient(
    tokenStorage: tokenStorage,
    dio: dio,
    refreshDio: refreshDio,
  );
  final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
  await repo.restoreSession();
  expect(repo.state, isA<AuthAuthenticated>());
  return repo;
}

void main() {
  // TokenStorage a besoin d'un double du plugin flutter_secure_storage (voir
  // test/core/network/token_storage_test.dart).
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  test('login gestionnaire : authenticated, tokens enregistrés', () async {
    final tokenStorage = TokenStorage();
    var profileCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        if (options.path == '/auth/mobile/login') {
          expect((options.data as Map)['email'], 'warisse@example.com');
          return jsonResponse({
            'message': 'Connexion réussie.',
            'token': 'access-1',
            'refreshToken': 'refresh-1',
            'role': 'gestionnaire',
            'userId': 42,
          }, 200);
        }
        if (options.path == '/auth/profile') {
          profileCalls++;
          expect(options.headers['Authorization'], 'Bearer access-1');
          return jsonResponse(_profileJson(), 200);
        }
        throw UnimplementedError(options.path);
      });

    final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
    final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

    final result = await repo.login('warisse@example.com', 'Password1');

    expect(result, isA<LoginSuccess>());
    expect((result as LoginSuccess).user.email, 'warisse@example.com');
    expect(repo.state, isA<AuthAuthenticated>());
    expect(tokenStorage.accessToken, 'access-1');
    expect(tokenStorage.refreshToken, 'refresh-1');
    expect(profileCalls, 1);
  });

  test(
    'login proprietaire : unsupportedRole, aucun token enregistré, '
    '/auth/mobile/logout appelé avec le refresh token reçu',
    () async {
      final tokenStorage = TokenStorage();
      String? revokedRefreshToken;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          if (options.path == '/auth/mobile/login') {
            return jsonResponse({
              'token': 'access-1',
              'refreshToken': 'refresh-1',
              'role': 'proprietaire',
              'userId': 7,
            }, 200);
          }
          if (options.path == '/auth/mobile/logout') {
            revokedRefreshToken = (options.data as Map)['refreshToken'] as String?;
            return jsonResponse({'message': 'Déconnexion réussie.'}, 200);
          }
          throw UnimplementedError(options.path);
        });

      final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
      final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

      final result = await repo.login('owner@example.com', 'Password1');

      expect(result, isA<LoginUnsupportedRole>());
      expect(repo.state, isA<AuthUnsupportedRole>());
      expect(tokenStorage.accessToken, isNull);
      expect(tokenStorage.refreshToken, isNull);
      expect(revokedRefreshToken, 'refresh-1');
    },
  );

  test('login en 401 : LoginInvalidCredentials, aucun token', () async {
    final tokenStorage = TokenStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        return jsonResponse({
          'message': 'Email ou mot de passe incorrect.',
        }, 401);
      });

    final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
    final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

    final result = await repo.login('warisse@example.com', 'wrong-password');

    expect(result, isA<LoginInvalidCredentials>());
    expect(
      (result as LoginInvalidCredentials).message,
      'Email ou mot de passe incorrect.',
    );
    expect(tokenStorage.accessToken, isNull);
    expect(tokenStorage.refreshToken, isNull);
  });

  test('login en 403 isVerified:false : LoginEmailNotVerified porte l\'email', () async {
    final tokenStorage = TokenStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        return jsonResponse({
          'message':
              'Veuillez vérifier votre adresse email avec le code que nous vous avons envoyé.',
          'isVerified': false,
        }, 403);
      });

    final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
    final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

    final result = await repo.login('unverified@example.com', 'Password1');

    expect(result, isA<LoginEmailNotVerified>());
    expect((result as LoginEmailNotVerified).email, 'unverified@example.com');
    expect(tokenStorage.accessToken, isNull);
  });

  test(
    'verifyEmail : /auth/verify-email puis /auth/mobile/login, '
    'tokens du canal mobile enregistrés (pas ceux du canal web)',
    () async {
      final tokenStorage = TokenStorage();
      final calledPaths = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          calledPaths.add(options.path);
          if (options.path == '/auth/verify-email') {
            expect((options.data as Map)['otp'], '123456');
            // Token du canal web (voir doc § 2.4) : doit être ignoré.
            return jsonResponse({
              'message': 'Email vérifié avec succès.',
              'token': 'web-token-ignored',
              'role': 'gestionnaire',
              'userId': 42,
            }, 200);
          }
          if (options.path == '/auth/mobile/login') {
            return jsonResponse({
              'token': 'mobile-access',
              'refreshToken': 'mobile-refresh',
              'role': 'gestionnaire',
              'userId': 42,
            }, 200);
          }
          if (options.path == '/auth/profile') {
            return jsonResponse(_profileJson(), 200);
          }
          throw UnimplementedError(options.path);
        });

      final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
      final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

      final result = await repo.verifyEmail(
        'warisse@example.com',
        '123456',
        'Password1',
      );

      expect(result, isA<VerifyEmailSuccess>());
      expect(calledPaths, [
        '/auth/verify-email',
        '/auth/mobile/login',
        '/auth/profile',
      ]);
      expect(tokenStorage.accessToken, 'mobile-access');
      expect(tokenStorage.refreshToken, 'mobile-refresh');
    },
  );

  test('restoreSession sans tokens : unauthenticated, aucun appel réseau', () async {
    final tokenStorage = TokenStorage();
    var calls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        calls++;
        throw UnimplementedError('aucun appel réseau attendu ici');
      });

    final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
    final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

    await repo.restoreSession();

    expect(repo.state, isA<AuthUnauthenticated>());
    expect(calls, 0);
  });

  test('restoreSession avec tokens et profil 200 : authenticated', () async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savePair(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        expect(options.path, '/auth/profile');
        return jsonResponse(_profileJson(), 200);
      });

    final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
    final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

    await repo.restoreSession();

    expect(repo.state, isA<AuthAuthenticated>());
    expect(
      (repo.state as AuthAuthenticated).user.email,
      'warisse@example.com',
    );
  });

  test('restoreSession en erreur réseau : offline, tokens conservés', () async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savePair(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

    final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
    final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

    await repo.restoreSession();

    expect(repo.state, isA<AuthOffline>());
    expect(tokenStorage.accessToken, 'access-1');
    expect(tokenStorage.refreshToken, 'refresh-1');
  });

  test(
    'restoreSession avec un rôle devenu non autorisé : tokens effacés, unsupportedRole',
    () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          return jsonResponse(_profileJson(role: 'proprietaire'), 200);
        });

      final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
      final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

      await repo.restoreSession();

      expect(repo.state, isA<AuthUnsupportedRole>());
      expect(tokenStorage.accessToken, isNull);
      expect(tokenStorage.refreshToken, isNull);
    },
  );

  test('événement sessionExpired : unauthenticated avec message', () async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savePair(
      const TokenPair(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );

    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async => jsonResponse({}, 401));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter(
        (options) async => jsonResponse({
          'message': 'Refresh token invalide ou expiré.',
        }, 401),
      );

    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      dio: dio,
      refreshDio: refreshDio,
    );
    final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

    // Une requête protégée quelconque déclenche un refresh explicitement
    // refusé par ApiClient, qui émet sessionExpired — c'est cet événement
    // que AuthRepository écoute depuis son constructeur.
    await expectLater(apiClient.dio.get('/resource'), throwsA(isA<DioException>()));
    await Future<void>.delayed(Duration.zero); // laisse le listener réagir

    expect(repo.state, isA<AuthUnauthenticated>());
    expect(
      (repo.state as AuthUnauthenticated).message,
      'Session expirée, reconnectez-vous.',
    );
  });

  test(
    'logout avec un serveur injoignable : tokens effacés quand même, unauthenticated',
    () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        });

      final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
      final repo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

      await repo.logout();

      expect(tokenStorage.accessToken, isNull);
      expect(tokenStorage.refreshToken, isNull);
      expect(repo.state, isA<AuthUnauthenticated>());
    },
  );

  test(
    'updateProfile succès : état mis à jour localement (pas de re-GET), '
    'preferences/photo_url renvoyés inchangés',
    () async {
      var profileGetCalls = 0;
      Map<String, dynamic>? sentPutBody;
      final repo = await _authenticatedRepo(
        responder: (options) async {
          if (options.path == '/auth/profile' && options.method == 'GET') {
            profileGetCalls++;
            return jsonResponse(_profileJson(), 200);
          }
          if (options.path == '/auth/profile' && options.method == 'PUT') {
            sentPutBody = Map<String, dynamic>.from(options.data as Map);
            return jsonResponse({'message': 'Profil mis à jour avec succès.'}, 200);
          }
          throw UnimplementedError('${options.method} ${options.path}');
        },
      );

      final result = await repo.updateProfile(
        nom: 'Nouveaunom',
        prenom: 'Nouveauprenom',
        email: 'new@example.com',
        telephone: '+22999999999',
      );

      expect(result, isA<UpdateProfileSuccess>());
      final updatedUser = (result as UpdateProfileSuccess).user;
      expect(updatedUser.nom, 'Nouveaunom');
      expect(updatedUser.prenom, 'Nouveauprenom');
      expect(updatedUser.email, 'new@example.com');
      expect(updatedUser.telephone, '+22999999999');

      expect(repo.state, isA<AuthAuthenticated>());
      expect((repo.state as AuthAuthenticated).user.email, 'new@example.com');
      // Une seule fois : celle de restoreSession() dans _authenticatedRepo,
      // pas de second GET après la mise à jour.
      expect(profileGetCalls, 1);
      expect(sentPutBody, isNotNull);
      expect(sentPutBody!['preferences'], <String, dynamic>{});
      expect(sentPutBody!['photo_url'], isNull);
    },
  );

  test(
    'updateProfile erreur de validation (400, email manquant) : état inchangé',
    () async {
      final repo = await _authenticatedRepo(
        responder: (options) async {
          if (options.path == '/auth/profile' && options.method == 'GET') {
            return jsonResponse(_profileJson(), 200);
          }
          if (options.path == '/auth/profile' && options.method == 'PUT') {
            return jsonResponse({'message': 'Email requis.'}, 400);
          }
          throw UnimplementedError('${options.method} ${options.path}');
        },
      );

      final result = await repo.updateProfile(
        nom: 'X',
        prenom: 'Y',
        email: 'warisse@example.com',
        telephone: '',
      );

      expect(result, isA<UpdateProfileValidationFailed>());
      expect((result as UpdateProfileValidationFailed).message, 'Email requis.');
      expect((repo.state as AuthAuthenticated).user.nom, 'Otchade');
    },
  );

  test('updateProfile erreur réseau : UpdateProfileFailure, état inchangé', () async {
    final repo = await _authenticatedRepo(
      responder: (options) async {
        if (options.path == '/auth/profile' && options.method == 'GET') {
          return jsonResponse(_profileJson(), 200);
        }
        if (options.path == '/auth/profile' && options.method == 'PUT') {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        throw UnimplementedError('${options.method} ${options.path}');
      },
    );

    final result = await repo.updateProfile(
      nom: 'X',
      prenom: 'Y',
      email: 'warisse@example.com',
      telephone: '+2290000000',
    );

    expect(result, isA<UpdateProfileFailure>());
    expect((result as UpdateProfileFailure).type, ApiExceptionType.network);
    expect((repo.state as AuthAuthenticated).user.nom, 'Otchade');
  });

  test('changePassword succès', () async {
    Map<String, dynamic>? sentBody;
    final repo = await _authenticatedRepo(
      responder: (options) async {
        if (options.path == '/auth/profile') return jsonResponse(_profileJson(), 200);
        if (options.path == '/auth/change-password') {
          sentBody = Map<String, dynamic>.from(options.data as Map);
          return jsonResponse({'message': 'Mot de passe modifié avec succès.'}, 200);
        }
        throw UnimplementedError(options.path);
      },
    );

    final result = await repo.changePassword(
      currentPassword: 'Old1234',
      newPassword: 'New12345',
    );

    expect(result, isA<ChangePasswordSuccess>());
    expect(sentBody!['currentPassword'], 'Old1234');
    expect(sentBody!['newPassword'], 'New12345');
    // changePassword() ne modifie jamais AuthState.
    expect(repo.state, isA<AuthAuthenticated>());
  });

  test(
    'changePassword mot de passe actuel incorrect (401) : '
    'ChangePasswordWrongCurrent avec le message backend',
    () async {
      final repo = await _authenticatedRepo(
        responder: (options) async {
          if (options.path == '/auth/profile') return jsonResponse(_profileJson(), 200);
          if (options.path == '/auth/change-password') {
            return jsonResponse({'message': 'Mot de passe actuel incorrect.'}, 401);
          }
          throw UnimplementedError(options.path);
        },
      );

      final result = await repo.changePassword(
        currentPassword: 'wrong-password',
        newPassword: 'New12345',
      );

      expect(result, isA<ChangePasswordWrongCurrent>());
      expect(
        (result as ChangePasswordWrongCurrent).message,
        'Mot de passe actuel incorrect.',
      );
    },
  );

  test(
    'changePassword erreur de validation (400, nouveau mot de passe trop court)',
    () async {
      final repo = await _authenticatedRepo(
        responder: (options) async {
          if (options.path == '/auth/profile') return jsonResponse(_profileJson(), 200);
          if (options.path == '/auth/change-password') {
            return jsonResponse({
              'errors': [
                {'path': 'newPassword', 'msg': 'Le nouveau mot de passe doit contenir au moins 6 caractères'},
              ],
            }, 400);
          }
          throw UnimplementedError(options.path);
        },
      );

      final result = await repo.changePassword(
        currentPassword: 'Old1234',
        newPassword: '123',
      );

      expect(result, isA<ChangePasswordValidationFailed>());
      expect(
        (result as ChangePasswordValidationFailed).fieldErrors['newPassword'],
        'Le nouveau mot de passe doit contenir au moins 6 caractères',
      );
    },
  );

  test('changePassword erreur réseau : ChangePasswordFailure', () async {
    final repo = await _authenticatedRepo(
      responder: (options) async {
        if (options.path == '/auth/profile') return jsonResponse(_profileJson(), 200);
        if (options.path == '/auth/change-password') {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        throw UnimplementedError(options.path);
      },
    );

    final result = await repo.changePassword(
      currentPassword: 'Old1234',
      newPassword: 'New12345',
    );

    expect(result, isA<ChangePasswordFailure>());
    expect((result as ChangePasswordFailure).type, ApiExceptionType.network);
  });
}
