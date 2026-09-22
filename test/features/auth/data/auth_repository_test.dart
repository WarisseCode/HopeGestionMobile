import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
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
}
