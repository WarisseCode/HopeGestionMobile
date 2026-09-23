import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/core/screens/shell_screen.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_repository.dart';
import 'package:hope_gestion_mobile/features/auth/screens/auth_gate.dart';
import 'package:hope_gestion_mobile/features/auth/screens/login_screen.dart';
import 'package:hope_gestion_mobile/features/auth/screens/offline_screen.dart';
import 'package:hope_gestion_mobile/features/auth/screens/unsupported_role_screen.dart';
import 'package:hope_gestion_mobile/features/onboarding/data/onboarding_store.dart';
import 'package:hope_gestion_mobile/features/onboarding/screens/onboarding_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

Map<String, dynamic> _profileJson({String role = 'gestionnaire'}) => {
  'message': 'Profil récupéré',
  'user': {
    'id': 42,
    'nom': 'Otchade',
    'prenom': 'Warisse',
    'email': 'warisse@example.com',
    'telephone': '+2290197000000',
    'role': role,
  },
};

/// Un test léger par état de `AuthState` : vérifie que `AuthGate` affiche le
/// bon écran racine. La logique de transition elle-même (classification des
/// erreurs, effacement des tokens...) est déjà couverte en détail par
/// `auth_repository_test.dart` — inutile de la retester ici.
void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<AuthRepository> buildRepo({
    bool withTokens = false,
    Future<ResponseBody> Function(RequestOptions options)? responder,
  }) async {
    final tokenStorage = TokenStorage();
    if (withTokens) {
      await tokenStorage.savePair(
        const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
    }
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter(
        responder ?? (options) async => jsonResponse({}, 200),
      );
    final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
    return AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
  }

  testWidgets('état initializing : indicateur de chargement', (
    tester,
  ) async {
    // Un AuthRepository frais démarre en `AuthInitializing` avant tout appel
    // à restoreSession() — pas besoin de simuler une requête en cours, donc
    // pas besoin de runAsync ici (voir les autres tests de ce fichier).
    final repo = await buildRepo();
    AuthRepository.initialize(repo);

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'état unauthenticated, onboarding jamais vu : onboarding puis connexion',
    (tester) async {
      // Pas de tokens : restoreSession() renvoie `unauthenticated` sans
      // passer par Dio, donc pas de runAsync nécessaire non plus.
      // `OnboardingStore` (singleton) doit être rechargé explicitement ici
      // contre le double fraîchement substitué par setUp() — voir la doc de
      // `OnboardingStore.load`.
      await OnboardingStore.instance.load();
      final repo = await buildRepo();
      await repo.restoreSession();
      AuthRepository.initialize(repo);

      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pump();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );

  testWidgets(
    'état unauthenticated, onboarding déjà vu : connexion directement '
    '(pas de réaffichage, y compris après une déconnexion/session expirée)',
    (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({'onboarding_seen': true});
      await OnboardingStore.instance.load();

      final repo = await buildRepo();
      await repo.restoreSession();
      AuthRepository.initialize(repo);

      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );

  testWidgets('état offline : écran hors-ligne', (tester) async {
    // `tester.runAsync` est indispensable dès qu'on attend une vraie requête
    // Dio (même via FakeAdapter) AVANT le premier pumpWidget : sous
    // `TestWidgetsFlutterBinding`, un Future attendu directement dans le
    // corps du test peut ne jamais se résoudre sans lui (le pipeline interne
    // de Dio dépend de timers réels) — testé empiriquement : sans runAsync,
    // ces trois tests restent bloqués jusqu'au timeout de 10 minutes.
    late AuthRepository repo;
    await tester.runAsync(() async {
      repo = await buildRepo(
        withTokens: true,
        responder: (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      await repo.restoreSession();
    });
    AuthRepository.initialize(repo);

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pump();

    expect(find.byType(OfflineScreen), findsOneWidget);
  });

  testWidgets('état unsupportedRole : écran rôle non supporté', (
    tester,
  ) async {
    late AuthRepository repo;
    await tester.runAsync(() async {
      repo = await buildRepo(
        withTokens: true,
        responder: (options) async =>
            jsonResponse(_profileJson(role: 'proprietaire'), 200),
      );
      await repo.restoreSession();
    });
    AuthRepository.initialize(repo);

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pump();

    expect(find.byType(UnsupportedRoleScreen), findsOneWidget);
  });

  testWidgets('état authenticated : shell', (tester) async {
    // `ShellScreen` embarque `DashboardScreen` (premier onglet), qui
    // charge de vraies données via `/dashboard/*` dès son premier frame
    // (voir `DashboardRepository`) — le faux répondeur doit donc aussi
    // couvrir ces routes, sans quoi `Future.wait` échoue avec une 404
    // (chemin non géré) et laisse un timer Dio en vol au moment où ce test
    // ne fait qu'un seul `pump()`.
    late AuthRepository repo;
    await tester.runAsync(() async {
      repo = await buildRepo(
        withTokens: true,
        responder: (options) async {
          if (options.path == '/dashboard/kpi') {
            return jsonResponse({
              'kpis': <dynamic>[],
              'summary': {
                'loyersEncaisses': 0,
                'loyersImpayes': 0,
              },
            }, 200);
          }
          if (options.path == '/dashboard/chart-data') {
            return jsonResponse({'chartData': <dynamic>[], 'period': '6m'}, 200);
          }
          if (options.path == '/dashboard/activity') {
            return jsonResponse({'activities': <dynamic>[]}, 200);
          }
          return jsonResponse(_profileJson(), 200);
        },
      );
      await repo.restoreSession();
    });
    AuthRepository.initialize(repo);

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pumpAndSettle();

    expect(find.byType(ShellScreen), findsOneWidget);
  });
}
