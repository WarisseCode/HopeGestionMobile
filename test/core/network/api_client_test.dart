import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  // TokenStorage a besoin d'un double du plugin flutter_secure_storage (voir
  // token_storage_test.dart) même si ces tests portent sur ApiClient.
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  test('onRequest attache le token d\'accès en cache, la requête réussit directement', () async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savePair(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );

    String? seenAuthHeader;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        seenAuthHeader = options.headers['Authorization'] as String?;
        return jsonResponse({'ok': true}, 200);
      });

    final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
    final response = await apiClient.dio.get('/resource');

    expect(seenAuthHeader, 'Bearer access-1');
    expect(response.statusCode, 200);
  });

  test('401 puis refresh réussi : la requête d\'origine est rejouée avec le nouveau token', () async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savePair(
      const TokenPair(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );

    var resourceCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        resourceCalls++;
        final authHeader = options.headers['Authorization'];
        if (authHeader == 'Bearer old-access') {
          return jsonResponse({'message': 'unauthorized'}, 401);
        }
        expect(authHeader, 'Bearer new-access');
        return jsonResponse({'ok': true}, 200);
      });

    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        expect(options.path, '/auth/mobile/refresh');
        expect((options.data as Map)['refreshToken'], 'old-refresh');
        return jsonResponse({
          'token': 'new-access',
          'refreshToken': 'new-refresh',
        }, 200);
      });

    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      dio: dio,
      refreshDio: refreshDio,
    );
    final response = await apiClient.dio.get('/resource');

    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
    expect(resourceCalls, 2); // 401 puis rejeu réussi
    expect(tokenStorage.accessToken, 'new-access');
    expect(tokenStorage.refreshToken, 'new-refresh');
  });

  test('3 requêtes 401 concurrentes ne déclenchent qu\'un seul refresh, toutes les 3 sont rejouées', () async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savePair(
      const TokenPair(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );

    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        // Laisse les trois requêtes atteindre le 401 avant que le refresh
        // (plus bas) ne se termine.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        final authHeader = options.headers['Authorization'];
        if (authHeader == 'Bearer old-access') {
          return jsonResponse({}, 401);
        }
        return jsonResponse({'path': options.path}, 200);
      });

    var refreshCalls = 0;
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return jsonResponse({
          'token': 'new-access',
          'refreshToken': 'new-refresh',
        }, 200);
      });

    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      dio: dio,
      refreshDio: refreshDio,
    );

    final results = await Future.wait([
      apiClient.dio.get('/a'),
      apiClient.dio.get('/b'),
      apiClient.dio.get('/c'),
    ]);

    expect(refreshCalls, 1);
    for (final response in results) {
      expect(response.statusCode, 200);
    }
    expect(tokenStorage.accessToken, 'new-access');
  });

  test('refresh échoué (401) : tokens effacés, 401 d\'origine propagé, aucune nouvelle tentative', () async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savePair(
      const TokenPair(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );

    var resourceCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        resourceCalls++;
        return jsonResponse({'message': 'unauthorized'}, 401);
      });

    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        return jsonResponse({
          'message': 'Refresh token invalide ou expiré.',
        }, 401);
      });

    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      dio: dio,
      refreshDio: refreshDio,
    );

    await expectLater(
      apiClient.dio.get('/resource'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(resourceCalls, 1); // pas de nouvelle tentative
    expect(tokenStorage.accessToken, isNull);
    expect(tokenStorage.refreshToken, isNull);
  });

  test(
    'déconnexion pendant un refresh en cours : les tokens restent effacés, '
    'la requête d\'origine échoue proprement sans nouvelle tentative',
    () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ),
      );

      var resourceCalls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          resourceCalls++;
          return jsonResponse({}, 401);
        });

      final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          // Déconnexion déclenchée par l'utilisateur PENDANT l'appel réseau
          // de refresh. Le refresh réussit quand même côté serveur — c'est
          // le client qui doit ignorer son résultat.
          await tokenStorage.clear();
          return jsonResponse({
            'token': 'new-access',
            'refreshToken': 'new-refresh',
          }, 200);
        });

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        dio: dio,
        refreshDio: refreshDio,
      );

      await expectLater(
        apiClient.dio.get('/resource'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      expect(resourceCalls, 1);
      expect(tokenStorage.accessToken, isNull);
      expect(tokenStorage.refreshToken, isNull);
    },
  );

  test('requête rejouée qui reçoit encore un 401 : pas de nouveau refresh, pas de boucle', () async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savePair(
      const TokenPair(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );

    var resourceCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        resourceCalls++;
        return jsonResponse({}, 401); // toujours 401, même après le rejeu
      });

    var refreshCalls = 0;
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        refreshCalls++;
        return jsonResponse({
          'token': 'new-access',
          'refreshToken': 'new-refresh',
        }, 200);
      });

    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      dio: dio,
      refreshDio: refreshDio,
    );

    await expectLater(
      apiClient.request<dynamic>('/resource'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.type,
          'type',
          ApiExceptionType.unauthorized,
        ),
      ),
    );

    expect(resourceCalls, 2); // 401 initial + 1 rejeu, jamais plus
    expect(refreshCalls, 1); // un seul refresh
  });

  test(
    'requête partie avec un ancien token, mais un refresh concurrent s\'est '
    'terminé entre-temps : rejouée directement avec le token courant, sans '
    'nouveau refresh',
    () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ),
      );

      var refreshCalls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          final authHeader = options.headers['Authorization'];
          if (authHeader == 'Bearer old-access') {
            // Simule un refresh déclenché par une AUTRE requête, qui se
            // termine pendant que celle-ci est encore en vol côté serveur.
            await tokenStorage.savePairIfCurrent(
              const TokenPair(
                accessToken: 'new-access',
                refreshToken: 'new-refresh',
              ),
              tokenStorage.generation,
            );
            return jsonResponse({}, 401);
          }
          expect(authHeader, 'Bearer new-access');
          return jsonResponse({'ok': true}, 200);
        });

      final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          refreshCalls++;
          return jsonResponse({
            'token': 'should-not-be-used',
            'refreshToken': 'should-not-be-used',
          }, 200);
        });

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        dio: dio,
        refreshDio: refreshDio,
      );

      final response = await apiClient.dio.get('/resource');

      expect(response.statusCode, 200);
      expect(refreshCalls, 0);
      expect(tokenStorage.accessToken, 'new-access');
    },
  );

  group('classification des échecs de refresh (réseau intermittent)', () {
    test('429 : tokens conservés, pas d\'événement, ApiException(rateLimited)', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ),
      );

      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          return jsonResponse({}, 401);
        });
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          return jsonResponse({
            'message': 'Trop de requêtes.',
          }, 429);
        });

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        dio: dio,
        refreshDio: refreshDio,
      );
      final events = <void>[];
      final subscription = apiClient.sessionExpired.listen(events.add);
      addTearDown(subscription.cancel);

      await expectLater(
        apiClient.request<dynamic>('/resource'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiExceptionType.rateLimited,
          ),
        ),
      );

      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      expect(tokenStorage.accessToken, 'old-access');
      expect(tokenStorage.refreshToken, 'old-refresh');
    });

    test('erreur réseau : tokens conservés, ApiException(network)', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ),
      );

      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          return jsonResponse({}, 401);
        });
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: 'Failed host lookup',
          );
        });

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        dio: dio,
        refreshDio: refreshDio,
      );

      await expectLater(
        apiClient.request<dynamic>('/resource'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiExceptionType.network,
          ),
        ),
      );

      expect(tokenStorage.accessToken, 'old-access');
      expect(tokenStorage.refreshToken, 'old-refresh');
    });

    test('timeout : tokens conservés, ApiException(timeout)', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ),
      );

      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          return jsonResponse({}, 401);
        });
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          );
        });

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        dio: dio,
        refreshDio: refreshDio,
      );

      await expectLater(
        apiClient.request<dynamic>('/resource'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiExceptionType.timeout,
          ),
        ),
      );

      expect(tokenStorage.accessToken, 'old-access');
      expect(tokenStorage.refreshToken, 'old-refresh');
    });

    test(
      '401 : tokens effacés, événement de session expirée émis une seule '
      'fois même avec plusieurs 401 concurrents',
      () async {
        final tokenStorage = TokenStorage();
        await tokenStorage.savePair(
          const TokenPair(
            accessToken: 'old-access',
            refreshToken: 'old-refresh',
          ),
        );

        final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = FakeAdapter((options) async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return jsonResponse({}, 401);
          });
        final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = FakeAdapter((options) async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return jsonResponse({
              'message': 'Refresh token invalide ou expiré.',
            }, 401);
          });

        final apiClient = ApiClient(
          tokenStorage: tokenStorage,
          dio: dio,
          refreshDio: refreshDio,
        );
        final events = <void>[];
        final subscription = apiClient.sessionExpired.listen(events.add);
        addTearDown(subscription.cancel);

        final results = await Future.wait<Object?>([
          captureError(() => apiClient.request<dynamic>('/a')),
          captureError(() => apiClient.request<dynamic>('/b')),
          captureError(() => apiClient.request<dynamic>('/c')),
        ]);

        for (final result in results) {
          expect(result, isA<ApiException>());
          expect((result as ApiException).type, ApiExceptionType.unauthorized);
        }
        await Future<void>.delayed(Duration.zero);
        expect(events.length, 1);
        expect(tokenStorage.accessToken, isNull);
        expect(tokenStorage.refreshToken, isNull);
      },
    );
  });

  group('routes /auth/*', () {
    test('401 sur /auth/mobile/login : pas de refresh, tokens intacts, erreur remontée', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ),
      );

      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          return jsonResponse({
            'message': 'Email ou mot de passe incorrect.',
          }, 401);
        });
      var refreshCalls = 0;
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          refreshCalls++;
          return jsonResponse({'token': 'x', 'refreshToken': 'y'}, 200);
        });

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        dio: dio,
        refreshDio: refreshDio,
      );

      await expectLater(
        apiClient.request<dynamic>(
          '/auth/mobile/login',
          method: 'POST',
          data: {'email': 'a@b.c', 'password': 'wrong'},
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Email ou mot de passe incorrect.',
          ),
        ),
      );

      expect(refreshCalls, 0);
      expect(tokenStorage.accessToken, 'old-access');
      expect(tokenStorage.refreshToken, 'old-refresh');
    });

    test('aucun Authorization envoyé sur /auth/mobile/*', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ),
      );

      var authorizationHeaderPresent = true;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          authorizationHeaderPresent = options.headers.containsKey(
            'Authorization',
          );
          return jsonResponse({
            'token': 'a',
            'refreshToken': 'b',
            'role': 'gestionnaire',
            'userId': 1,
          }, 200);
        });

      final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
      await apiClient.request<dynamic>(
        '/auth/mobile/login',
        method: 'POST',
        data: {'email': 'a@b.c', 'password': 'x'},
      );

      expect(authorizationHeaderPresent, isFalse);
    });

    test('GET /auth/profile en 401 : route protégée, refresh puis rejeu réussi', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ),
      );

      var refreshCalls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          final authHeader = options.headers['Authorization'];
          if (authHeader == 'Bearer old-access') {
            return jsonResponse({}, 401);
          }
          expect(authHeader, 'Bearer new-access');
          return jsonResponse({'email': 'user@example.com'}, 200);
        });
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          refreshCalls++;
          return jsonResponse({
            'token': 'new-access',
            'refreshToken': 'new-refresh',
          }, 200);
        });

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        dio: dio,
        refreshDio: refreshDio,
      );

      final response = await apiClient.request<dynamic>('/auth/profile');

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
    });

    test('PATCH /auth/complete-profile en 401 : route protégée, refresh puis rejeu', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ),
      );

      var refreshCalls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          final authHeader = options.headers['Authorization'];
          if (authHeader == 'Bearer old-access') {
            return jsonResponse({}, 401);
          }
          expect(authHeader, 'Bearer new-access');
          return jsonResponse({'message': 'Profil complété avec succès.'}, 200);
        });
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          refreshCalls++;
          return jsonResponse({
            'token': 'new-access',
            'refreshToken': 'new-refresh',
          }, 200);
        });

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        dio: dio,
        refreshDio: refreshDio,
      );

      final response = await apiClient.request<dynamic>(
        '/auth/complete-profile',
        method: 'PATCH',
        data: {'userType': 'gestionnaire', 'telephone': '01 97 00 00 00'},
      );

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
    });

    test('POST /auth/forgot-password en 401 : route publique, pas de refresh', () async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
        ),
      );

      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          return jsonResponse({'message': 'unauthorized'}, 401);
        });
      var refreshCalls = 0;
      final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          refreshCalls++;
          return jsonResponse({
            'token': 'new-access',
            'refreshToken': 'new-refresh',
          }, 200);
        });

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        dio: dio,
        refreshDio: refreshDio,
      );

      await expectLater(
        apiClient.request<dynamic>(
          '/auth/forgot-password',
          method: 'POST',
          data: {'email': 'a@b.c'},
        ),
        throwsA(isA<ApiException>()),
      );

      expect(refreshCalls, 0);
      expect(tokenStorage.accessToken, 'old-access');
      expect(tokenStorage.refreshToken, 'old-refresh');
    });
  });

  test('rejeu d\'une requête FormData après refresh : réussit (FormData.clone)', () async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savePair(
      const TokenPair(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );

    var uploadCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        uploadCalls++;
        final authHeader = options.headers['Authorization'];
        if (authHeader == 'Bearer old-access') {
          return jsonResponse({}, 401);
        }
        expect(options.data, isA<FormData>());
        return jsonResponse({'ok': true}, 200);
      });

    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        return jsonResponse({
          'token': 'new-access',
          'refreshToken': 'new-refresh',
        }, 200);
      });

    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      dio: dio,
      refreshDio: refreshDio,
    );

    final formData = FormData.fromMap({'field': 'value'});
    final response = await apiClient.request<dynamic>(
      '/upload',
      method: 'POST',
      data: formData,
    );

    expect(response.statusCode, 200);
    expect(uploadCalls, 2);
  });

  group('ApiException.fromDioException — extraction du message et des erreurs de champ', () {
    DioException badResponse(Map<String, dynamic> body, int statusCode) {
      final options = RequestOptions(path: '/x');
      return DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: statusCode,
          data: body,
        ),
      );
    }

    test('extrait "message" en priorité', () {
      final exception = ApiException.fromDioException(
        badResponse({'message': 'Erreur précise.'}, 400),
      );
      expect(exception.type, ApiExceptionType.validation);
      expect(exception.message, 'Erreur précise.');
    });

    test('à défaut de "message", extrait "error" (ex. réponses 429)', () {
      final exception = ApiException.fromDioException(
        badResponse({'error': 'Trop de requêtes, réessayez plus tard.'}, 429),
      );
      expect(exception.type, ApiExceptionType.rateLimited);
      expect(exception.message, 'Trop de requêtes, réessayez plus tard.');
    });

    test('à défaut, extrait errors[0].msg (format express-validator)', () {
      final exception = ApiException.fromDioException(
        badResponse({
          'errors': [
            {'path': 'telephone', 'msg': 'Numéro de téléphone invalide.'},
          ],
        }, 400),
      );
      expect(exception.type, ApiExceptionType.validation);
      expect(exception.message, 'Numéro de téléphone invalide.');
    });

    test('sans aucun de ces champs : message par défaut pour le type', () {
      final exception = ApiException.fromDioException(badResponse({}, 404));
      expect(exception.type, ApiExceptionType.notFound);
      expect(exception.message, 'Ressource introuvable.');
    });

    test('fieldErrors construite depuis errors[].path -> msg', () {
      final exception = ApiException.fromDioException(
        badResponse({
          'message': 'Validation échouée.',
          'errors': [
            {'path': 'telephone', 'msg': 'Numéro de téléphone invalide.'},
            {'path': 'userType', 'msg': 'Type de compte invalide.'},
          ],
        }, 400),
      );
      expect(exception.fieldErrors, {
        'telephone': 'Numéro de téléphone invalide.',
        'userType': 'Type de compte invalide.',
      });
    });
  });
}
