import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/notifications/data/notifications_repository.dart';
import 'package:hope_gestion_mobile/features/notifications/screens/notifications_screen.dart';

import '../../../support/fake_http_adapter.dart';

/// Faux serveur : `GET /alertes` (liste, erreur [erreurStatus] ou réseau),
/// `POST /alertes/:id/dismiss` (succès, ou erreur [dismissStatus]).
class _Serveur {
  List<Map<String, dynamic>> alertes = [
    {
      'id': 'late_12',
      'titre': 'Loyer en retard',
      'description': 'Loyer de Diop Yacine (A1 - Horizon) non payé.',
      'type': 'Paiement',
      'priorite': 'Haute',
      'dateCreation': '2026-10-05T08:00:00.000Z',
    },
    {
      'id': 'exp_4',
      'titre': 'Bail bientôt expiré',
      'description': 'Le bail de Camara Awa expire dans 20 jours.',
      'type': 'Contrat',
      'priorite': 'Moyenne',
    },
    {
      'id': 'vac_3',
      'titre': 'Lot vacant',
      'description': 'Le lot B2 est vacant.',
      'type': 'Commercial',
      'priorite': 'Basse',
    },
  ];
  int dismissedCount = 0;
  int? erreurStatus;
  bool reseauEnErreur = false;
  int? dismissStatus;

  /// Si non nul, `GET /alertes` attend ce completer (état de chargement).
  Completer<void>? bloquerListe;
  final requetes = <String>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add('${options.method} ${options.path}');
    if (options.method == 'GET' && options.path == '/alertes') {
      await bloquerListe?.future;
      if (reseauEnErreur) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      final status = erreurStatus;
      if (status != null) {
        return jsonResponse({'message': 'Erreur $status'}, status);
      }
      return jsonResponse({
        'alerts': alertes,
        'dismissedCount': dismissedCount,
      }, 200);
    }
    if (options.method == 'POST' && options.path.endsWith('/dismiss')) {
      final status = dismissStatus;
      if (status != null) {
        return jsonResponse({'message': 'Refus du serveur'}, status);
      }
      return jsonResponse({'success': true}, 200);
    }
    throw UnimplementedError('${options.method} ${options.path}');
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<_Serveur> _pump(
  WidgetTester tester, {
  void Function(_Serveur)? configurer,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final serveur = _Serveur();
  configurer?.call(serveur);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(serveur.repondre);
  NotificationsRepository.initialize(
    NotificationsRepository(
      apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
    ),
  );

  await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
  if (settle) await _settle(tester);
  return serveur;
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  testWidgets('affiche les alertes réelles, sans date ni « Relancer »', (
    tester,
  ) async {
    final serveur = await _pump(
      tester,
      configurer: (s) => s.dismissedCount = 2,
    );

    expect(serveur.requetes, ['GET /alertes']);
    expect(find.text('Loyer en retard'), findsOneWidget);
    expect(find.text('Bail bientôt expiré'), findsOneWidget);
    expect(find.text('Lot vacant'), findsOneWidget);
    expect(find.text('Haute'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2 alertes ignorées'), findsOneWidget);
    expect(find.text('Ignorer'), findsNWidgets(3));
    expect(find.text('Relancer'), findsNothing);
    expect(find.textContaining('Il y a'), findsNothing);
    expect(find.textContaining('2026'), findsNothing);
    expect(find.text('Tout lire'), findsNothing);
  });

  testWidgets('filtres : pas de « Paiements », Impayés et Contrats filtrent', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.text('Paiements'), findsNothing);

    await tester.tap(find.text('Impayés'));
    await tester.pump();
    expect(find.text('Loyer en retard'), findsOneWidget);
    expect(find.text('Bail bientôt expiré'), findsNothing);
    expect(find.text('Lot vacant'), findsNothing);

    await tester.tap(find.text('Baux & Contrats'));
    await tester.pump();
    expect(find.text('Loyer en retard'), findsNothing);
    expect(find.text('Bail bientôt expiré'), findsOneWidget);

    await tester.tap(find.text('Toutes'));
    await tester.pump();
    expect(find.text('Lot vacant'), findsOneWidget);
  });

  testWidgets('chargement : indicateur pendant GET /alertes', (tester) async {
    final bloquer = Completer<void>();
    await _pump(
      tester,
      configurer: (s) => s.bloquerListe = bloquer,
      settle: false,
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loyer en retard'), findsNothing);

    bloquer.complete();
    await _settle(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Loyer en retard'), findsOneWidget);
  });

  testWidgets('vide : message dédié', (tester) async {
    await _pump(tester, configurer: (s) => s.alertes = []);
    expect(find.text('Aucune alerte pour le moment'), findsOneWidget);
    expect(find.text('Ignorer'), findsNothing);
  });

  testWidgets('filtre sans résultat : message de catégorie', (tester) async {
    await _pump(tester, configurer: (s) => s.alertes = [s.alertes.last]);
    await tester.tap(find.text('Impayés'));
    await tester.pump();
    expect(find.text('Aucune alerte dans cette catégorie'), findsOneWidget);
  });

  testWidgets('erreur réseau puis « Réessayer » recharge', (tester) async {
    final serveur = await _pump(
      tester,
      configurer: (s) => s.reseauEnErreur = true,
    );

    expect(find.text('Impossible de charger les alertes'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    serveur.reseauEnErreur = false;
    await tester.tap(find.text('Réessayer'));
    await _settle(tester);

    expect(find.text('Impossible de charger les alertes'), findsNothing);
    expect(find.text('Loyer en retard'), findsOneWidget);
  });

  testWidgets('403 : erreur sans « Réessayer »', (tester) async {
    await _pump(tester, configurer: (s) => s.erreurStatus = 403);
    expect(find.text('Impossible de charger les alertes'), findsOneWidget);
    expect(find.text('Erreur 403'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('401 : erreur avec message serveur', (tester) async {
    await _pump(tester, configurer: (s) => s.erreurStatus = 401);
    expect(find.text('Impossible de charger les alertes'), findsOneWidget);
    expect(find.text('Erreur 401'), findsOneWidget);
  });

  testWidgets('« Ignorer » : POST dismiss, alerte retirée, compteurs à jour', (
    tester,
  ) async {
    final serveur = await _pump(tester);

    await tester.tap(find.text('Ignorer').first);
    await _settle(tester);

    expect(serveur.requetes, contains('POST /alertes/late_12/dismiss'));
    expect(find.text('Loyer en retard'), findsNothing);
    expect(find.text('Bail bientôt expiré'), findsOneWidget);
    expect(find.text('Alerte ignorée'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1 alerte ignorée'), findsOneWidget);
  });

  testWidgets('« Ignorer » en échec : alerte conservée, message affiché', (
    tester,
  ) async {
    await _pump(tester, configurer: (s) => s.dismissStatus = 403);

    await tester.tap(find.text('Ignorer').first);
    await _settle(tester);

    expect(find.text('Loyer en retard'), findsOneWidget);
    expect(find.text('Refus du serveur'), findsOneWidget);
    expect(find.text('Ignorer'), findsNWidgets(3));
  });
}
