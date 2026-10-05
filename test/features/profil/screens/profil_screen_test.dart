import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_repository.dart';
import 'package:hope_gestion_mobile/features/biens/data/biens_repository.dart';
import 'package:hope_gestion_mobile/features/locataires/data/locataires_repository.dart';
import 'package:hope_gestion_mobile/features/profil/screens/profil_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

Map<String, dynamic> _locataire(int id) => {
  'id': id,
  'nom': 'Nom$id',
  'prenoms': 'Prenom$id',
  'telephone_principal': '+2299000000$id',
  'type': 'Locataire',
  'statut': 'Actif',
};

class _Serveur {
  final requetes = <String>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options.path);
    switch (options.path) {
      case '/auth/profile':
        return jsonResponse({
          'user': {
            'id': 1,
            'nom': 'Warisse',
            'prenom': 'OTCHADE',
            'email': 'warisse@example.com',
            'role': 'gestionnaire',
            'userType': 'gestionnaire',
            'isGuest': false,
            'preferences': <String, dynamic>{},
          },
        }, 200);
      case '/locataires':
        return jsonResponse({
          'locataires': [_locataire(1), _locataire(2), _locataire(3)],
        }, 200);
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

Future<_Serveur> _pump(WidgetTester tester, {bool precharger = false}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final serveur = _Serveur();
  await tester.runAsync(() async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savePair(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter(serveur.repondre);
    final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
    AuthRepository.initialize(
      AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
    );
    BiensRepository.initialize(BiensRepository(apiClient: apiClient));
    final locataires = LocatairesRepository(apiClient: apiClient);
    LocatairesRepository.initialize(locataires);
    await AuthRepository.instance.restoreSession();
    if (precharger) await locataires.refresh();
  });
  serveur.requetes.clear();

  await tester.pumpWidget(const MaterialApp(home: ProfilScreen()));
  await _settle(tester);
  return serveur;
}

/// Valeur affichée dans la carte de stat dont le libellé est [label].
Finder _statValue(String label, String value) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.text(value),
);

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  testWidgets(
    'stat LOCATAIRES : liste vide → refresh déclenché, valeur réelle',
    (tester) async {
      final serveur = await _pump(tester);

      expect(serveur.appelsSur('/locataires'), 1);
      expect(_statValue('LOCATAIRES', '3'), findsOneWidget);
    },
  );

  testWidgets('stat LOCATAIRES : liste déjà chargée → pas de nouvel appel', (
    tester,
  ) async {
    final serveur = await _pump(tester, precharger: true);

    expect(serveur.appelsSur('/locataires'), 0);
    expect(_statValue('LOCATAIRES', '3'), findsOneWidget);
  });
}
