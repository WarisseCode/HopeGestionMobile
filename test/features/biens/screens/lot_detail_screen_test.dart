import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/biens/models/lot.dart';
import 'package:hope_gestion_mobile/features/biens/screens/lot_detail_screen.dart';
import 'package:hope_gestion_mobile/features/documents/data/baux_repository.dart';
import 'package:hope_gestion_mobile/features/documents/screens/bail_detail_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

class _Serveur {
  /// Statut de `GET /locations`, ou `null` = erreur réseau.
  int? status = 200;
  List<Map<String, dynamic>> locations = [];
  final requetes = <String>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options.path);
    if (options.path == '/locations/42') {
      return jsonResponse({
        'location': {
          'id': 42,
          'reference_bail': 'BAIL-2026-0042',
          'statut': 'actif',
        },
        'echeancier': <dynamic>[],
      }, 200);
    }
    if (options.path != '/locations') {
      throw UnimplementedError(options.path);
    }
    final s = status;
    if (s == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (s != 200) return jsonResponse({'message': 'Accès refusé'}, s);
    return jsonResponse({'locations': locations}, 200);
  }

  int get appelsListe => requetes.where((p) => p == '/locations').length;
}

Map<String, dynamic> _bail({
  required int id,
  int lotId = 12,
  String statut = 'actif',
}) => {
  'id': id,
  'reference_bail': 'BAIL-2026-00$id',
  'lot_id': lotId,
  'tenant_id': 3,
  'date_debut': '2026-10-05',
  'date_fin': '2027-10-05',
  'loyer_mensuel': '185000.00',
  'statut': statut,
  'locataire_nom': 'Diop',
  'locataire_prenoms': 'Yacine',
  'locataire_telephone': '+22990000001',
};

const _lot = Lot(
  id: 12,
  reference: 'A1',
  immeubleNom: 'Résidence Palmiers',
  type: 'appartement',
  statut: 'occupe',
  photos: ['/uploads/lot-a1.jpg'],
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<_Serveur> _pump(
  WidgetTester tester, {
  Lot lot = _lot,
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

  await tester.pumpWidget(MaterialApp(home: LotDetailScreen(lot: lot)));
  await _settle(tester);
  return serveur;
}

/// Le reste de la fiche (photo, caractéristiques) est toujours affiché.
void _expectFicheVisible() {
  expect(find.byType(Image), findsWidgets);
  expect(find.text('Résidence Palmiers'), findsOneWidget);
  expect(find.text('Superficie'), findsOneWidget);
  expect(find.text('occupe'), findsOneWidget);
}

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  testWidgets('bail trouvé : carte occupant avec le plus récent actif', (
    tester,
  ) async {
    final serveur = await _pump(
      tester,
      configurer: (s) => s.locations = [
        _bail(id: 50, statut: 'resilie'),
        _bail(id: 42),
        _bail(id: 30),
      ],
    );

    expect(find.text('OCCUPANT ACTUEL'), findsOneWidget);
    expect(find.text('Diop Yacine'), findsOneWidget);
    expect(find.text('+22990000001'), findsOneWidget);
    expect(
      find.text('BAIL-2026-0042 · 185 000 F/mois · depuis le 05/10/2026'),
      findsOneWidget,
    );
    expect(serveur.appelsListe, 1);
    _expectFicheVisible();
    expect(tester.takeException(), isNull);
  });

  testWidgets('lot vacant : ligne discrète, pas de carte', (tester) async {
    await _pump(
      tester,
      lot: const Lot(id: 12, reference: 'A1', statut: 'disponible'),
      configurer: (s) => s.locations = [_bail(id: 42, lotId: 99)],
    );

    expect(find.text('Aucun bail en cours'), findsOneWidget);
    expect(find.byKey(const Key('lot_occupant_card')), findsNothing);
    expect(find.text('disponible'), findsOneWidget);
  });

  testWidgets('lot occupé sans bail en cours : « bail introuvable », statut '
      'du lot inchangé', (tester) async {
    await _pump(tester, configurer: (s) => s.locations = []);

    expect(find.textContaining('Bail introuvable'), findsOneWidget);
    expect(find.text('Aucun bail en cours'), findsNothing);
    _expectFicheVisible();
  });

  testWidgets('tap : ouvre la fiche du bail, rechargement au retour', (
    tester,
  ) async {
    final serveur = await _pump(
      tester,
      configurer: (s) => s.locations = [_bail(id: 42)],
    );

    await tester.tap(find.text('Diop Yacine'));
    await _settle(tester);

    final fiche = tester.widget<BailDetailScreen>(
      find.byType(BailDetailScreen),
    );
    expect(fiche.bailId, 42);
    expect(serveur.requetes, contains('/locations/42'));

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await _settle(tester);
    // Fin de la transition de retour.
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(BailDetailScreen), findsNothing);
    expect(serveur.appelsListe, 2);
    expect(find.text('Diop Yacine'), findsOneWidget);
  });

  testWidgets('403 : message discret, fiche affichée, pas de Réessayer', (
    tester,
  ) async {
    await _pump(tester, configurer: (s) => s.status = 403);

    expect(find.textContaining('accès aux baux refusé'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
    _expectFicheVisible();
  });

  testWidgets('réseau : fiche affichée, Réessayer recharge l\'occupant', (
    tester,
  ) async {
    final serveur = await _pump(tester, configurer: (s) => s.status = null);

    expect(find.textContaining('Connexion impossible'), findsOneWidget);
    _expectFicheVisible();

    serveur
      ..status = 200
      ..locations = [_bail(id: 42)];
    await tester.tap(find.text('Réessayer'));
    await _settle(tester);

    expect(find.text('Diop Yacine'), findsOneWidget);
    expect(find.textContaining('Connexion impossible'), findsNothing);
    expect(serveur.appelsListe, 2);
  });
}
