import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/biens/data/biens_repository.dart';
import 'package:hope_gestion_mobile/features/locataires/data/owners_repository.dart';
import 'package:hope_gestion_mobile/features/locataires/screens/owner_detail_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

class _Serveur {
  /// Réponse de `GET /owners/5` : statut HTTP, ou `null` = erreur réseau.
  int? ownerStatus = 200;
  bool immeublesEnErreur = false;
  final requetes = <String>[];

  List<Map<String, dynamic>> immeubles = [
    {'id': 1, 'nom': 'Résidence Palmiers', 'owner_id': 5, 'nbLots': 3},
    {'id': 2, 'nom': 'Villa Almadies', 'owner_id': 6, 'nbLots': 1},
    // owner_id en chaîne : doit quand même être rattaché (parsing tolérant).
    {'id': 3, 'nom': 'Immeuble Akpakpa', 'owner_id': '5', 'nbLots': 2},
  ];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options.path);
    switch (options.path) {
      case '/owners/5':
        final status = ownerStatus;
        if (status == null) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        if (status != 200) {
          return jsonResponse({'success': false, 'message': 'Erreur'}, status);
        }
        return jsonResponse({
          'success': true,
          'owner': {
            'id': 5,
            'name': 'Camara',
            'first_name': 'Mamadou',
            'phone': '+22990000005',
            'email': 'mamadou@example.com',
            'address': 'Rue 12',
            'city': 'Cotonou',
            'type': 'individual',
          },
          'users': <dynamic>[],
        }, 200);
      case '/biens/immeubles':
        if (immeublesEnErreur) {
          return jsonResponse({'message': 'Erreur serveur'}, 500);
        }
        return jsonResponse({'immeubles': immeubles}, 200);
    }
    throw UnimplementedError(options.path);
  }

  int appelsSur(String path) => requetes.where((p) => p == path).length;
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
  bool prechargerBiens = false,
}) async {
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final serveur = _Serveur();
  configurer?.call(serveur);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(serveur.repondre);
  final apiClient = ApiClient(tokenStorage: TokenStorage(), dio: dio);
  OwnersRepository.initialize(OwnersRepository(apiClient: apiClient));
  final biens = BiensRepository(apiClient: apiClient);
  BiensRepository.initialize(biens);
  if (prechargerBiens) {
    await tester.runAsync(biens.listImmeubles);
    serveur.requetes.clear();
  }

  await tester.pumpWidget(
    const MaterialApp(home: OwnerDetailScreen(ownerId: 5)),
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

  testWidgets('succès : coordonnées et biens filtrés par owner_id', (
    tester,
  ) async {
    final serveur = await _pump(tester);

    expect(find.text('Camara Mamadou'), findsWidgets);
    expect(find.text('Particulier'), findsOneWidget);
    expect(find.text('+22990000005'), findsOneWidget);
    expect(find.text('mamadou@example.com'), findsOneWidget);
    expect(find.text('Rue 12, Cotonou'), findsOneWidget);

    // Liste vide au départ → chargement déclenché par l'écran.
    expect(serveur.appelsSur('/biens/immeubles'), 1);
    expect(find.text('BIENS (2)'), findsOneWidget);
    expect(find.text('Résidence Palmiers'), findsOneWidget);
    expect(find.text('Immeuble Akpakpa'), findsOneWidget);
    expect(find.text('Villa Almadies'), findsNothing);
    // Jamais l'endpoint backend faussé.
    expect(serveur.appelsSur('/owners/5/properties'), 0);
    // Lecture seule.
    expect(find.text('Supprimer'), findsNothing);
  });

  testWidgets('biens déjà chargés : pas de nouvel appel', (tester) async {
    final serveur = await _pump(tester, prechargerBiens: true);

    expect(serveur.appelsSur('/biens/immeubles'), 0);
    expect(find.text('BIENS (2)'), findsOneWidget);
  });

  testWidgets('aucun bien rattaché', (tester) async {
    await _pump(
      tester,
      configurer: (s) => s.immeubles = [
        {'id': 2, 'nom': 'Villa Almadies', 'owner_id': 6},
      ],
    );

    expect(find.text('BIENS (0)'), findsOneWidget);
    expect(find.text('Aucun bien rattaché à ce propriétaire.'), findsOneWidget);
  });

  testWidgets('échec du chargement des biens : erreur locale', (tester) async {
    await _pump(tester, configurer: (s) => s.immeublesEnErreur = true);

    expect(find.text('+22990000005'), findsOneWidget);
    expect(find.text('Impossible de charger les biens'), findsOneWidget);
  });

  testWidgets('403 : accès refusé, pas de Réessayer', (tester) async {
    await _pump(tester, configurer: (s) => s.ownerStatus = 403);

    expect(find.text('Accès refusé à ce propriétaire'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('404 : propriétaire désactivé', (tester) async {
    await _pump(tester, configurer: (s) => s.ownerStatus = 404);

    expect(find.text('Propriétaire introuvable'), findsOneWidget);
    expect(
      find.text('Ce propriétaire n\'existe pas ou a été désactivé.'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('réseau : message + Réessayer qui recharge', (tester) async {
    final serveur = await _pump(
      tester,
      configurer: (s) => s.ownerStatus = null,
    );

    expect(find.text('Connexion impossible'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    serveur.ownerStatus = 200;
    await tester.tap(find.text('Réessayer'));
    await _settle(tester);

    expect(find.text('mamadou@example.com'), findsOneWidget);
    expect(serveur.appelsSur('/owners/5'), 2);
  });
}
