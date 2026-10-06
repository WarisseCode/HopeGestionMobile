import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/documents/data/baux_repository.dart';
import 'package:hope_gestion_mobile/features/documents/screens/bail_detail_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

class _Serveur {
  /// Statut de `GET /locations/42`, ou `null` = erreur réseau.
  int? status = 200;
  List<Map<String, dynamic>> echeancier = [];
  final requetes = <String>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options.path);
    if (options.path != '/locations/42') {
      throw UnimplementedError(options.path);
    }
    final s = status;
    if (s == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (s == 404) {
      return jsonResponse({
        'message': 'Contrat non trouvé ou accès refusé',
      }, 404);
    }
    if (s != 200) return jsonResponse({'message': 'Accès refusé'}, s);
    return jsonResponse({
      'location': {
        'id': 42,
        'reference_bail': 'BAIL-2026-0042',
        'statut': 'actif',
        'loyer_mensuel': '185000.00',
        'caution': '370000.00',
        'avance': 2,
        'charges_mensuelles': '10000.00',
        'jour_echeance': 5,
        'date_debut': '2026-10-05',
        'date_fin': '2027-10-05',
        'locataire_nom': 'Diop',
        'locataire_prenoms': 'Yacine',
        'locataire_telephone': '+22990000001',
        'locataire_email': 'yacine@example.com',
        'ref_lot': 'A1',
        'lot_type': 'appartement',
        'immeuble_nom': 'Résidence Palmiers',
        'immeuble_adresse': 'Rue 12, Cotonou',
        'proprietaire_nom': 'Mamadou Camara',
      },
      'echeancier': echeancier,
    }, 200);
  }

  int get appels => requetes.length;
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
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final serveur = _Serveur();
  configurer?.call(serveur);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(serveur.repondre);
  BauxRepository.initialize(
    BauxRepository(
      apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BailDetailScreen(
        bailId: 42,
        maintenant: () => DateTime(2026, 12, 20),
      ),
    ),
  );
  await _settle(tester);
  return serveur;
}

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  testWidgets('succès : en-tête et toutes les sections', (tester) async {
    await _pump(tester);

    expect(find.text('BAIL-2026-0042'), findsOneWidget);
    expect(find.text('Actif'), findsOneWidget);

    expect(find.text('LOCATAIRE'), findsOneWidget);
    expect(find.text('Diop Yacine'), findsOneWidget);
    expect(find.text('+22990000001'), findsOneWidget);
    expect(find.text('yacine@example.com'), findsOneWidget);

    expect(find.text('LOGEMENT'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('Appartement'), findsOneWidget);
    expect(find.text('Résidence Palmiers'), findsOneWidget);
    expect(find.text('Rue 12, Cotonou'), findsOneWidget);

    expect(find.text('PROPRIÉTAIRE'), findsOneWidget);
    expect(find.text('Mamadou Camara'), findsOneWidget);

    expect(find.text('CONDITIONS FINANCIÈRES'), findsOneWidget);
    expect(find.text('185 000 F'), findsOneWidget);
    expect(find.text('10 000 F'), findsOneWidget);
    expect(find.text('370 000 F'), findsOneWidget);
    // Avance en mois, jamais convertie en FCFA.
    expect(find.text('2 mois'), findsOneWidget);
    expect(find.textContaining('FCFA'), findsNothing);
    expect(find.text('Le 5 du mois'), findsOneWidget);
    expect(find.text('05/10/2026'), findsOneWidget);
    expect(find.text('05/10/2027'), findsOneWidget);

    // Lecture seule.
    expect(find.text('Résilier'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('échéancier vide : message informatif, pas une erreur', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('ÉCHÉANCIER (0)'), findsOneWidget);
    expect(
      find.text(
        'Aucune échéance pour le moment : c\'est normal pour un bail '
        'récent, les échéances sont générées au fil des mois.',
      ),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('échéancier : badges d\'état cohérents avec Finances', (
    tester,
  ) async {
    await _pump(
      tester,
      configurer: (s) => s.echeancier = [
        {
          'id': 1,
          'total_amount': '185000.00',
          'amount_paid': '185000.00',
          'due_date': '2026-11-05',
          'status': 'paid',
        },
        {
          'id': 2,
          'total_amount': '185000.00',
          'amount_paid': '0.00',
          'due_date': '2026-12-05',
        },
        {
          'id': 3,
          'total_amount': '185000.00',
          'amount_paid': '50000.00',
          'due_date': '2027-01-05',
          'status': 'partial',
        },
        {
          'id': 4,
          'total_amount': '185000.00',
          'amount_paid': '0.00',
          'due_date': '2027-02-05',
        },
      ],
    );

    expect(find.text('ÉCHÉANCIER (4)'), findsOneWidget);
    expect(find.text('Payée'), findsOneWidget);
    expect(find.text('En retard'), findsOneWidget);
    expect(find.text('Acompte'), findsOneWidget);
    expect(find.text('À payer'), findsOneWidget);
    expect(find.text('Versé 50 000 F · Reste 135 000 F'), findsOneWidget);
    expect(find.textContaining('Aucune échéance'), findsNothing);
  });

  testWidgets('404 : message clair, pas de Réessayer', (tester) async {
    await _pump(tester, configurer: (s) => s.status = 404);

    expect(find.text('Bail introuvable'), findsOneWidget);
    expect(find.textContaining('n\'existe pas'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('403 : accès refusé, pas de Réessayer', (tester) async {
    await _pump(tester, configurer: (s) => s.status = 403);

    expect(find.text('Accès refusé'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('réseau : Réessayer qui recharge', (tester) async {
    final serveur = await _pump(tester, configurer: (s) => s.status = null);

    expect(find.text('Connexion impossible'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    serveur.status = 200;
    await tester.tap(find.text('Réessayer'));
    await _settle(tester);

    expect(find.text('BAIL-2026-0042'), findsOneWidget);
    expect(serveur.appels, 2);
  });

  testWidgets('tirer pour actualiser : nouvel appel', (tester) async {
    final serveur = await _pump(tester);

    // Même approche que `locataires_screen_test` : le geste lui-même relève
    // du framework, seul le câblage `onRefresh` est testé.
    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await tester.runAsync(indicator.onRefresh);
    await _settle(tester);

    expect(serveur.appels, 2);
    expect(find.text('BAIL-2026-0042'), findsOneWidget);
  });

  testWidgets('actualisation en échec réseau : fiche conservée + SnackBar', (
    tester,
  ) async {
    final serveur = await _pump(tester);

    serveur.status = null;
    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await tester.runAsync(indicator.onRefresh);
    await _settle(tester);

    expect(find.text('BAIL-2026-0042'), findsOneWidget);
    expect(find.textContaining('Actualisation impossible'), findsOneWidget);
    expect(find.text('Connexion impossible'), findsNothing);
  });
}
