import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/core/theme/theme_controller.dart';
import 'package:hope_gestion_mobile/features/biens/data/biens_repository.dart';
import 'package:hope_gestion_mobile/features/biens/screens/immeuble_detail_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

Map<String, dynamic> _immeubleJson({required bool withPhotos}) => {
  'id': 1,
  'nom': 'Résidence des Palmiers au nom particulièrement long',
  'type': 'Immeuble',
  'adresse': 'Rue 12.345, lot 67',
  'quartier': 'Haie Vive',
  'ville': 'Cotonou',
  'pays': 'Bénin',
  'description': 'Immeuble R+3 proche du marché, parking en sous-sol.',
  'statut': 'actif',
  'nombre_etages': 3,
  'total_lots': 20,
  // Valeurs serveur calculées sur la capacité déclarée (voir
  // `bienRoutes.ts`) : la fiche doit les ignorer au profit des lots créés.
  'nbLots': 20,
  'lotsOccupes': 0,
  'occupation': 0,
  'etatOccupation': 'Disponible',
  'proprietaire': 'CAMARA Mamadou',
  'owner_name': 'CAMARA',
  'owner_first_name': 'Mamadou',
  'owner_type': 'individual',
  'gestionnaire_name': 'Warisse OTCHADE',
  if (withPhotos)
    'photos': ['/uploads/properties/a.jpg', '/uploads/properties/b.jpg'],
};

Map<String, dynamic> _lotJson(
  int id,
  String statut,
  String loyer, {
  String periodicite = 'mensuel',
}) => {
  'id': id,
  'reference': 'Appartement A$id',
  'building_id': 1,
  'etage': 'R+1',
  'type': 'Appartement',
  'loyer': loyer,
  'periodicite': periodicite,
  'statut': statut,
};

Future<void> _pump(
  WidgetTester tester, {
  required bool dark,
  required bool withPhotos,
  required List<Map<String, dynamic>> lots,
}) async {
  // Hauteur généreuse : la `ListView` ne construit que ce qui est visible.
  tester.view.physicalSize = const Size(390, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  ThemeController.instance.setDark(dark);

  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter((options) async {
      switch (options.path) {
        case '/biens/immeubles':
          return jsonResponse({
            'immeubles': [_immeubleJson(withPhotos: withPhotos)],
          }, 200);
        case '/biens/lots':
          return jsonResponse({'lots': lots}, 200);
      }
      throw UnimplementedError(options.path);
    });
  final repo = BiensRepository(
    apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
  );
  BiensRepository.initialize(repo);
  await tester.runAsync(repo.listImmeubles);

  await tester.pumpWidget(
    const MaterialApp(home: ImmeubleDetailScreen(immeubleId: 1)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });
  tearDown(() => ThemeController.instance.setDark(false));

  final avecLots = [
    _lotJson(1, 'occupe', '185000'),
    _lotJson(2, 'reserve', '600000', periodicite: 'trimestriel'),
    _lotJson(3, 'disponible', '150000'),
    _lotJson(4, 'hors_service', '0'),
  ];

  for (final dark in [false, true]) {
    for (final withPhotos in [false, true]) {
      testWidgets(
        'sans lot, sans débordement (sombre: $dark, photos: $withPhotos)',
        (tester) async {
          await _pump(tester, dark: dark, withPhotos: withPhotos, lots: []);

          expect(tester.takeException(), isNull);
          // Aucun lot créé → Vide, malgré `etatOccupation: 'Disponible'`.
          expect(find.text('VIDE'), findsOneWidget);
          expect(find.text('DISPONIBLE'), findsNothing);
          expect(find.text('0 / 0 occupé'), findsOneWidget);
          expect(find.text('0 lot créé · 20 prévus'), findsOneWidget);
          expect(find.text('Ajouter le premier lot'), findsOneWidget);
          expect(find.text('0 F'), findsOneWidget);
          expect(find.text('1 / 2'), withPhotos ? findsOneWidget : findsNothing);
        },
      );

      testWidgets(
        'avec lots, sans débordement (sombre: $dark, photos: $withPhotos)',
        (tester) async {
          await _pump(
            tester,
            dark: dark,
            withPhotos: withPhotos,
            lots: avecLots,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('EN LOCATION'), findsOneWidget);
          // occupe + reserve = 2 sur 4 lots créés.
          expect(find.text('2 / 4 occupés'), findsOneWidget);
          expect(find.text('50 %'), findsOneWidget);
          expect(find.text('4 lots créés · 20 prévus'), findsOneWidget);
          // 185 000 + 600 000 / 3 (trimestriel).
          expect(find.text('385 000 F'), findsOneWidget);
          expect(find.text('Occupé'), findsOneWidget);
          expect(find.text('Réservé'), findsOneWidget);
          expect(find.text('Disponible'), findsOneWidget);
          expect(find.text('Hors service'), findsOneWidget);
          expect(find.text('185 000 F'), findsOneWidget);
          expect(find.text('Ajouter le premier lot'), findsNothing);
        },
      );
    }
  }

  testWidgets('description, propriétaire en « Prénom Nom »', (tester) async {
    await _pump(tester, dark: false, withPhotos: false, lots: []);

    expect(
      find.text('Immeuble R+3 proche du marché, parking en sous-sol.'),
      findsOneWidget,
    );
    expect(find.text('Mamadou CAMARA'), findsOneWidget);
    expect(find.text('Warisse OTCHADE'), findsOneWidget);
  });

  testWidgets('menu ⋮ : Supprimer (avec confirmation), pas de Modifier', (
    tester,
  ) async {
    await _pump(tester, dark: false, withPhotos: false, lots: []);

    expect(find.byIcon(LucideIcons.trash), findsNothing);
    await tester.tap(find.byIcon(LucideIcons.ellipsis_vertical));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cet immeuble ?'), findsOneWidget);
  });
}
