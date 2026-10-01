import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:hope_gestion_mobile/core/config/app_config.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_repository.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_results.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_state.dart';

import '../../../support/fake_http_adapter.dart';

/// Double de la plateforme `google_sign_in` 7.x : étend directement
/// [GoogleSignInPlatform] (le jeton de `PlatformInterface` est alors
/// valide sans `MockPlatformInterfaceMixin`). `authenticate` renvoie un
/// compte portant [idToken], ou lève [authenticateError] s'il est fourni.
class FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  FakeGoogleSignInPlatform({this.idToken = 'google-id-token', this.authenticateError});

  final String? idToken;
  final GoogleSignInException? authenticateError;

  final List<InitParameters> initCalls = [];
  int authenticateCalls = 0;
  int signOutCalls = 0;

  @override
  Future<void> init(InitParameters params) async => initCalls.add(params);

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) async {
    authenticateCalls++;
    final error = authenticateError;
    if (error != null) throw error;
    return AuthenticationResults(
      user: const GoogleSignInUserData(email: 'warisse@example.com', id: 'g-1'),
      authenticationTokens: AuthenticationTokenData(idToken: idToken),
    );
  }

  @override
  Future<void> signOut(SignOutParams params) async => signOutCalls++;

  @override
  Future<void> disconnect(DisconnectParams params) async {}

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) => null;

  @override
  bool supportsAuthenticate() => true;

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async => null;
}

Map<String, dynamic> _profileJson() => {
  'message': 'Profil récupéré',
  'user': {
    'id': 42,
    'nom': 'Otchade',
    'prenom': 'Warisse',
    'email': 'warisse@example.com',
    'telephone': '+2290197000000',
    'role': 'gestionnaire',
    'userType': 'gestionnaire',
    'isGuest': false,
    'photo_url': null,
    'preferences': <String, dynamic>{},
    'permissions': <String, dynamic>{},
  },
};

void main() {
  late FakeGoogleSignInPlatform platform;
  late TokenStorage tokenStorage;
  late List<String> requestedPaths;

  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    tokenStorage = TokenStorage();
    requestedPaths = [];
  });

  AuthRepository buildRepo(
    Future<ResponseBody> Function(RequestOptions options) responder, {
    FakeGoogleSignInPlatform? googlePlatform,
  }) {
    platform = googlePlatform ?? FakeGoogleSignInPlatform();
    GoogleSignInPlatform.instance = platform;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) {
        requestedPaths.add(options.path);
        return responder(options);
      });
    // Un refresh ne doit jamais être tenté : le refreshDio échoue le test.
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter(
        (options) => throw StateError('Refresh inattendu : ${options.path}'),
      );
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      dio: dio,
      refreshDio: refreshDio,
    );
    return AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
  }

  Future<ResponseBody> errorOnGoogle(RequestOptions options, int status) async {
    if (options.path == '/auth/mobile/google') {
      return jsonResponse({'message': 'Erreur $status du serveur.'}, status);
    }
    throw UnimplementedError(options.path);
  }

  test('annulation : GoogleLoginCancelled, aucun appel backend', () async {
    final repo = buildRepo(
      (options) => throw UnimplementedError(options.path),
      googlePlatform: FakeGoogleSignInPlatform(
        authenticateError: const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      ),
    );

    final result = await repo.loginWithGoogle();

    expect(result, isA<GoogleLoginCancelled>());
    expect(requestedPaths, isEmpty);
    expect(repo.state, isA<AuthInitializing>());
    expect(tokenStorage.accessToken, isNull);
  });

  test('autre erreur du SDK Google : GoogleLoginFailure, aucun appel backend', () async {
    final repo = buildRepo(
      (options) => throw UnimplementedError(options.path),
      googlePlatform: FakeGoogleSignInPlatform(
        authenticateError: const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      ),
    );

    expect(await repo.loginWithGoogle(), isA<GoogleLoginFailure>());
    expect(requestedPaths, isEmpty);
  });

  test(
    'succès : idToken envoyé, serverClientId transmis, tokens stockés, '
    'authenticated',
    () async {
      Object? sentBody;
      String? sentAuthorization;
      final repo = buildRepo((options) async {
        if (options.path == '/auth/mobile/google') {
          sentBody = options.data;
          sentAuthorization = options.headers['Authorization'] as String?;
          return jsonResponse({
            'message': 'Connexion réussie.',
            'token': 'access-1',
            'refreshToken': 'refresh-1',
            'role': 'gestionnaire',
            'userId': 42,
          }, 200);
        }
        if (options.path == '/auth/profile') {
          expect(options.headers['Authorization'], 'Bearer access-1');
          return jsonResponse(_profileJson(), 200);
        }
        throw UnimplementedError(options.path);
      });

      final result = await repo.loginWithGoogle();

      expect(sentBody, {'idToken': 'google-id-token'});
      expect(sentAuthorization, isNull);
      expect(platform.initCalls.single.serverClientId, AppConfig.googleWebClientId);
      expect(result, isA<GoogleLoginSuccess>());
      expect((result as GoogleLoginSuccess).user.email, 'warisse@example.com');
      expect(repo.state, isA<AuthAuthenticated>());
      expect(tokenStorage.accessToken, 'access-1');
      expect(tokenStorage.refreshToken, 'refresh-1');
      expect(requestedPaths, ['/auth/mobile/google', '/auth/profile']);
    },
  );

  test('initialize() n\'est appelé qu\'une fois sur deux tentatives', () async {
    final repo = buildRepo((options) => errorOnGoogle(options, 404));

    await repo.loginWithGoogle();
    await repo.loginWithGoogle();

    expect(platform.initCalls, hasLength(1));
    expect(platform.authenticateCalls, 2);
  });

  test('404 : GoogleLoginUnknownEmail, aucun token', () async {
    final repo = buildRepo((options) => errorOnGoogle(options, 404));

    final result = await repo.loginWithGoogle();

    expect(result, isA<GoogleLoginUnknownEmail>());
    expect((result as GoogleLoginUnknownEmail).message, 'Erreur 404 du serveur.');
    expect(tokenStorage.accessToken, isNull);
  });

  test('403 : GoogleLoginRoleNotAllowed, aucun token, état inchangé', () async {
    final repo = buildRepo((options) => errorOnGoogle(options, 403));

    final result = await repo.loginWithGoogle();

    expect(result, isA<GoogleLoginRoleNotAllowed>());
    expect(tokenStorage.accessToken, isNull);
    expect(tokenStorage.refreshToken, isNull);
    expect(repo.state, isA<AuthInitializing>());
    expect(requestedPaths, ['/auth/mobile/google']);
  });

  test('401 : GoogleLoginUnauthorized, aucun refresh tenté', () async {
    final repo = buildRepo((options) => errorOnGoogle(options, 401));

    final result = await repo.loginWithGoogle();

    expect(result, isA<GoogleLoginUnauthorized>());
    expect((result as GoogleLoginUnauthorized).message, 'Erreur 401 du serveur.');
    expect(tokenStorage.accessToken, isNull);
    expect(requestedPaths, ['/auth/mobile/google']);
  });

  test('erreur réseau : GoogleLoginNetworkError', () async {
    final repo = buildRepo((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });

    expect(await repo.loginWithGoogle(), isA<GoogleLoginNetworkError>());
    expect(tokenStorage.accessToken, isNull);
  });

  test('autre statut (500) : GoogleLoginFailure', () async {
    final repo = buildRepo((options) => errorOnGoogle(options, 500));

    expect(await repo.loginWithGoogle(), isA<GoogleLoginFailure>());
  });
}
