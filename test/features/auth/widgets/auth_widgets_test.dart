import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/auth/data/app_user.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_repository.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_results.dart';
import 'package:hope_gestion_mobile/features/auth/widgets/auth_widgets.dart';

import '../../../support/fake_http_adapter.dart';

/// Double minimal : seul `loginWithGoogle` est remplacé ; il renvoie le
/// futur d'un [Completer] que chaque test complète au moment voulu (pour
/// observer l'état de chargement pendant l'appel). Le [Completer] est créé
/// au premier appel, donc dans la zone `fakeAsync` du test : créé dans
/// `setUp`, sa complétion passerait par la boucle réelle et `pump()` ne la
/// verrait pas.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({required super.apiClient, required super.tokenStorage});

  Completer<GoogleLoginResult>? _pending;
  Completer<GoogleLoginResult> get pending => _pending!;
  int calls = 0;

  @override
  Future<GoogleLoginResult> loginWithGoogle() {
    calls++;
    return (_pending ??= Completer<GoogleLoginResult>()).future;
  }
}

void main() {
  late _FakeAuthRepository repo;

  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
    final tokenStorage = TokenStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter(
        (options) async => jsonResponse({}, 200),
      );
    repo = _FakeAuthRepository(
      apiClient: ApiClient(tokenStorage: tokenStorage, dio: dio),
      tokenStorage: tokenStorage,
    );
    AuthRepository.initialize(repo);
  });

  Future<void> pumpButton(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: AuthGoogleButton(label: 'Continuer avec Google')),
    ),
  );

  OutlinedButton button(WidgetTester tester) => tester.widget<OutlinedButton>(
    find.byWidgetPredicate((w) => w is OutlinedButton),
  );

  /// Tape le bouton, complète l'appel avec [result] puis laisse le SnackBar
  /// éventuel s'afficher.
  Future<void> tapAndComplete(
    WidgetTester tester,
    GoogleLoginResult result,
  ) async {
    await pumpButton(tester);
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pump();
    repo.pending.complete(result);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('chargement : bouton désactivé et indicateur pendant l\'appel', (
    tester,
  ) async {
    await pumpButton(tester);
    expect(button(tester).onPressed, isNotNull);

    await tester.tap(find.text('Continuer avec Google'));
    await tester.pump();

    expect(repo.calls, 1);
    expect(button(tester).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Un second appui pendant l'appel n'en relance pas un autre.
    await tester.tap(find.text('Continuer avec Google'), warnIfMissed: false);
    await tester.pump();
    expect(repo.calls, 1);

    repo.pending.complete(const GoogleLoginCancelled());
    await tester.pump();
    expect(button(tester).onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('succès : aucun SnackBar', (tester) async {
    final user = AppUser.fromJson({
      'id': 42,
      'nom': 'Otchade',
      'prenom': 'Warisse',
      'email': 'warisse@example.com',
      'role': 'gestionnaire',
    });
    await tapAndComplete(tester, GoogleLoginSuccess(user));

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('annulation : rien affiché, bouton réactivé', (tester) async {
    await tapAndComplete(tester, const GoogleLoginCancelled());

    expect(find.byType(SnackBar), findsNothing);
    expect(button(tester).onPressed, isNotNull);
  });

  testWidgets('email inconnu : message dédié', (tester) async {
    await tapAndComplete(tester, const GoogleLoginUnknownEmail('Not found'));

    expect(
      find.text(
        "Aucun compte n'est associé à cette adresse Gmail. "
        'Contactez votre administrateur.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rôle non autorisé : message dédié', (tester) async {
    await tapAndComplete(tester, const GoogleLoginRoleNotAllowed());

    expect(
      find.text("Ce compte n'est pas autorisé sur l'application mobile."),
      findsOneWidget,
    );
  });

  testWidgets('erreur réseau : message du résultat', (tester) async {
    await tapAndComplete(
      tester,
      const GoogleLoginNetworkError('Connexion impossible au serveur.'),
    );

    expect(find.text('Connexion impossible au serveur.'), findsOneWidget);
    expect(button(tester).onPressed, isNotNull);
  });

  testWidgets('démontage pendant l\'appel : aucune erreur', (tester) async {
    await pumpButton(tester);
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    repo.pending.complete(const GoogleLoginNetworkError('Hors ligne'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
