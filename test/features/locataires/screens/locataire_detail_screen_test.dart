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
import 'package:hope_gestion_mobile/features/locataires/data/locataires_repository.dart';
import 'package:hope_gestion_mobile/features/locataires/screens/locataire_detail_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
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

  testWidgets(
    'onglet Contrat & Bail : un tap ouvre la fiche du bail (bon id)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final requetes = <String>[];
      Future<ResponseBody> repondre(RequestOptions options) async {
        requetes.add(options.path);
        switch (options.path) {
          case '/locataires/1':
            return jsonResponse({
              'locataire': {
                'id': 1,
                'nom': 'Diop',
                'prenoms': 'Yacine',
                'telephone_principal': '+22990000001',
                'type': 'Locataire',
                'statut': 'Actif',
              },
              'baux': [
                {
                  'id': 10,
                  'statut': 'actif',
                  'building_name': 'Résidence Palmiers',
                  'ref_lot': 'A1',
                  'loyer_actuel': '185000',
                },
                {
                  'id': 11,
                  'statut': 'resilie',
                  'building_name': 'Villa Almadies',
                  'ref_lot': 'B2',
                },
              ],
              'paiements': <dynamic>[],
            }, 200);
          case '/locations/11':
            return jsonResponse({
              'location': {
                'id': 11,
                'reference_bail': 'BAIL-2025-00011',
                'statut': 'resilie',
              },
              'echeancier': <dynamic>[],
            }, 200);
        }
        throw UnimplementedError(options.path);
      }

      final apiClient = ApiClient(
        tokenStorage: TokenStorage(),
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = FakeAdapter(repondre),
      );
      LocatairesRepository.initialize(
        LocatairesRepository(apiClient: apiClient),
      );
      BauxRepository.initialize(BauxRepository(apiClient: apiClient));

      await tester.pumpWidget(
        const MaterialApp(home: LocataireDetailScreen(locataireId: 1)),
      );
      await _settle(tester);

      expect(find.text('A1 — Résidence Palmiers'), findsOneWidget);
      await tester.tap(find.text('B2 — Villa Almadies'));
      await _settle(tester);
      await tester.pumpAndSettle();

      final fiche = tester.widget<BailDetailScreen>(
        find.byType(BailDetailScreen),
      );
      expect(fiche.bailId, 11);
      expect(requetes, contains('/locations/11'));
      expect(find.text('BAIL-2025-00011'), findsOneWidget);
      expect(find.text('Résilié'), findsOneWidget);
    },
  );
}
