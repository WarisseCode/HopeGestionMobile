import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/core/theme/app_theme.dart';
import 'package:hope_gestion_mobile/core/theme/theme_controller.dart';
import 'package:hope_gestion_mobile/features/finances/data/finances_repository.dart';
import 'package:hope_gestion_mobile/features/finances/screens/finances_screen.dart';
import 'package:hope_gestion_mobile/features/finances/screens/transaction_detail_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

ResponseBody _listResponse(List<dynamic> body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// Lignes réelles de `GET /finances` (NUMERIC en chaîne, DATE en instant à
/// midi UTC : même jour quel que soit le fuseau).
final _paiements = [
  {
    'id': 1,
    'lease_id': 8,
    'amount': '185000.00',
    'payment_date': '2026-09-15T12:00:00.000Z',
    'payment_method': 'especes',
    'reference': 'RECU-0926',
    'type': 'loyer',
    'statut': 'valide',
    'created_at': '2026-09-15T10:12:00.000Z',
    'reference_bail': 'BAIL-2026-008-AVEC-UNE-REFERENCE-TRES-LONGUE',
    'locataire_nom': 'DIOP-NDIAYE',
    'locataire_prenoms': 'Yacine Marie-Christine',
  },
  {
    'id': 2,
    'lease_id': 9,
    'amount': '1250000.00',
    'payment_date': '2026-09-02T12:00:00.000Z',
    'payment_method': 'mobile_money',
    'type': 'loyer',
    'statut': 'annule',
    'reference_bail': 'BAIL-009',
    'locataire_nom': 'Mensah',
    'locataire_prenoms': 'Kouassi',
  },
];

final _depenses = [
  {
    'id': 4,
    'category': 'Travaux / Entretien',
    'amount': '45000.00',
    'date_expense': '2026-09-10T12:00:00.000Z',
    'description': 'Réparation plomberie de la colonne d\'eau principale',
    'building_name': 'Résidence des Palmiers',
    'ref_lot': 'A12',
  },
];

class _Serveur {
  _Serveur({this.vide = false, this.echecs = 0});

  final bool vide;

  /// Nombre de réponses 500 sur `/finances` avant de répondre normalement.
  int echecs;
  final requetes = <RequestOptions>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options);
    switch (options.path) {
      case '/finances':
        if (echecs > 0) {
          echecs--;
          return jsonResponse({'message': 'Erreur serveur'}, 500);
        }
        return jsonResponse({
          'payments': vide ? <dynamic>[] : _paiements,
        }, 200);
      case '/expenses':
        return _listResponse(vide ? <dynamic>[] : _depenses);
      case '/finances/stats':
        return jsonResponse({
          'encashed_month': vide ? 0 : 185000,
          'expenses_month': vide ? 0 : 45000,
          'net_balance': vide ? 0 : 140000,
          'pending_total': vide ? 0 : 2370000,
        }, 200);
    }
    throw UnimplementedError(options.path);
  }

  List<RequestOptions> sur(String path) =>
      requetes.where((r) => r.path == path).toList();
}

Future<_Serveur> _pump(
  WidgetTester tester, {
  bool dark = false,
  bool vide = false,
  int echecs = 0,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  ThemeController.instance.setDark(dark);

  final serveur = _Serveur(vide: vide, echecs: echecs);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(serveur.repondre);
  FinancesRepository.initialize(
    FinancesRepository(
      apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: FinancesScreen(maintenant: () => DateTime(2026, 9, 28, 14)),
    ),
  );
  await _settle(tester);
  return serveur;
}

/// Les requêtes passent par un vrai aller-retour Dio : on laisse l'I/O se
/// faire hors de l'horloge factice, puis on reconstruit.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });
  tearDown(() => ThemeController.instance.setDark(false));

  for (final dark in [false, true]) {
    testWidgets('liste vide, sans débordement (sombre: $dark)', (tester) async {
      await _pump(tester, dark: dark, vide: true);

      expect(tester.takeException(), isNull);
      expect(find.text('SEPTEMBRE 2026'), findsOneWidget);
      expect(find.text('SOLDE DU MOIS'), findsOneWidget);
      expect(find.text('MOUVEMENTS DU MOIS · 0'), findsOneWidget);
      expect(
        find.text('Aucun encaissement ni dépense ce mois-ci'),
        findsOneWidget,
      );
      expect(find.text('Encaisser'), findsOneWidget);
      expect(find.text('Dépense'), findsOneWidget);
    });

    testWidgets('paiements et dépenses, sans débordement (sombre: $dark)', (
      tester,
    ) async {
      await _pump(tester, dark: dark);

      expect(tester.takeException(), isNull);
      // Synthèse : libellés des définitions serveur.
      expect(find.text('+140 000 F'), findsOneWidget);
      expect(find.text('Encaissé moins dépenses du mois'), findsOneWidget);
      expect(find.text('185 000 F'), findsOneWidget);
      expect(find.text('45 000 F'), findsOneWidget);
      expect(find.text('2 370 000 F'), findsOneWidget);
      expect(find.text('Reste à encaisser'), findsOneWidget);

      // Mouvements fusionnés, date décroissante : 15/09, 10/09, 02/09.
      expect(find.text('MOUVEMENTS DU MOIS · 3'), findsOneWidget);
      final titres = [
        'Yacine Marie-Christine DIOP-NDIAYE',
        'Réparation plomberie de la colonne d\'eau principale',
        'Kouassi Mensah',
      ];
      final ys = titres
          .map((t) => tester.getTopLeft(find.text(t)).dy)
          .toList();
      expect(ys, orderedEquals([...ys]..sort()));
      expect(find.text('+185 000 F'), findsOneWidget);
      expect(find.text('-45 000 F'), findsOneWidget);
      expect(find.text('+1 250 000 F'), findsOneWidget);
      // Paiement annulé : listé, marqué.
      expect(find.textContaining('Annulé'), findsOneWidget);
    });
  }

  testWidgets('mois courant par défaut, bornes du mois envoyées', (
    tester,
  ) async {
    final serveur = await _pump(tester);

    final paiements = serveur.sur('/finances').single.queryParameters;
    expect(paiements['start_date'], '2026-09-01');
    expect(paiements['end_date'], '2026-09-30');
    final depenses = serveur.sur('/expenses').single.queryParameters;
    expect(depenses['start_date'], '2026-09-01');
    expect(depenses['end_date'], '2026-09-30');
    final stats = serveur.sur('/finances/stats').single.queryParameters;
    expect(stats['month'], 9);
    expect(stats['year'], 2026);
  });

  testWidgets('mois précédent / suivant, pas au-delà du mois courant', (
    tester,
  ) async {
    final serveur = await _pump(tester);
    final suivant = find.byTooltip('Mois suivant');
    final precedent = find.byTooltip('Mois précédent');

    // Mois courant : « suivant » désactivé, aucune requête.
    expect(
      tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(LucideIcons.chevron_right),
            matching: find.byType(IconButton)),
      ).onPressed,
      isNull,
    );
    await tester.tap(suivant);
    await _settle(tester);
    expect(serveur.sur('/finances'), hasLength(1));

    await tester.tap(precedent);
    await _settle(tester);
    expect(find.text('AOÛT 2026'), findsOneWidget);
    expect(serveur.sur('/finances').last.queryParameters, {
      'start_date': '2026-08-01',
      'end_date': '2026-08-31',
    });
    expect(serveur.sur('/finances/stats').last.queryParameters, {
      'month': 8,
      'year': 2026,
    });

    // Passage d'année.
    for (var i = 0; i < 8; i++) {
      await tester.tap(precedent);
      await _settle(tester);
    }
    expect(find.text('DÉCEMBRE 2025'), findsOneWidget);
    expect(serveur.sur('/expenses').last.queryParameters, {
      'start_date': '2025-12-01',
      'end_date': '2025-12-31',
    });

    // Retour vers le mois courant.
    for (var i = 0; i < 9; i++) {
      await tester.tap(suivant);
      await _settle(tester);
    }
    expect(find.text('SEPTEMBRE 2026'), findsOneWidget);
    expect(serveur.sur('/finances').last.queryParameters['start_date'],
        '2026-09-01');
  });

  testWidgets('erreur → « Réessayer » recharge', (tester) async {
    await _pump(tester, echecs: 1);

    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('SOLDE DU MOIS'), findsNothing);

    await tester.tap(find.text('Réessayer'));
    await _settle(tester);

    expect(find.text('Réessayer'), findsNothing);
    expect(find.text('MOUVEMENTS DU MOIS · 3'), findsOneWidget);
  });

  testWidgets('tap sur un mouvement → fiche détaillée', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Kouassi Mensah'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailScreen), findsOneWidget);
    expect(find.text('Détail du paiement'), findsOneWidget);
  });
}
