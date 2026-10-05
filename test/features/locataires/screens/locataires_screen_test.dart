import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/core/widgets/app_fab.dart';
import 'package:hope_gestion_mobile/features/biens/data/biens_repository.dart';
import 'package:hope_gestion_mobile/features/locataires/data/locataires_repository.dart';
import 'package:hope_gestion_mobile/features/locataires/data/owners_repository.dart';
import 'package:hope_gestion_mobile/features/locataires/screens/locataires_screen.dart';
import 'package:hope_gestion_mobile/features/locataires/screens/owner_detail_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

/// Faux serveur : `/locataires`, `/owners` (liste, ou erreur réseau si
/// [ownersEnErreur]), `/owners/:id`, `/biens/immeubles`.
class _Serveur {
  List<Map<String, dynamic>> locataires = [
    {
      'id': 1,
      'nom': 'Diop',
      'prenoms': 'Yacine',
      'telephone_principal': '+22990000000',
      'type': 'Locataire',
      'statut': 'Actif',
      'lot_nom': 'Apt. 12',
    },
  ];
  List<Map<String, dynamic>> owners = [
    {
      'id': 5,
      'name': 'Camara',
      'first_name': 'Mamadou',
      'phone': '+22990000005',
      'total_properties': '2',
      'total_lots': '7',
    },
    {'id': 6, 'name': 'SCI Almadies', 'type': 'company'},
  ];
  bool ownersEnErreur = false;
  final requetes = <String>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options.path);
    switch (options.path) {
      case '/locataires':
        return jsonResponse({'locataires': locataires}, 200);
      case '/owners':
        if (ownersEnErreur) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return jsonResponse({'success': true, 'owners': owners}, 200);
      case '/owners/5':
        return jsonResponse({'success': true, 'owner': owners.first}, 200);
      case '/biens/immeubles':
        return jsonResponse({'immeubles': <dynamic>[]}, 200);
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
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final serveur = _Serveur();
  configurer?.call(serveur);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(serveur.repondre);
  final apiClient = ApiClient(tokenStorage: TokenStorage(), dio: dio);
  LocatairesRepository.initialize(LocatairesRepository(apiClient: apiClient));
  OwnersRepository.initialize(OwnersRepository(apiClient: apiClient));
  BiensRepository.initialize(BiensRepository(apiClient: apiClient));

  await tester.pumpWidget(const MaterialApp(home: LocatairesScreen()));
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

  testWidgets('« Tous » : affiche locataires ET propriétaires, cohérent avec '
      'le compteur', (tester) async {
    await _pump(tester);

    expect(find.text('3 CONTACTS ACTIFS'), findsOneWidget);
    expect(find.text('Yacine Diop'), findsOneWidget);
    expect(find.text('Camara Mamadou'), findsOneWidget);
    expect(find.text('SCI Almadies'), findsOneWidget);
    expect(find.text('Locataires'), findsOneWidget);
    expect(find.text('Propriétaires'), findsOneWidget);
  });

  testWidgets('onglet Propriétaires : liste réelle, compteur de la puce', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('PROPRIÉTAIRES'));
    await tester.pumpAndSettle();

    expect(find.text('Camara Mamadou'), findsOneWidget);
    expect(find.text('+22990000005 · 2 biens'), findsOneWidget);
    expect(find.text('SCI Almadies'), findsOneWidget);
    expect(find.text('Yacine Diop'), findsNothing);
    expect(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('PROPRIÉTAIRES'),
              matching: find.byType(Column),
            )
            .first,
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    // Plus de bannière « données d'exemple ».
    expect(find.textContaining('données'), findsNothing);
  });

  testWidgets('onglet Locataires : masque les propriétaires', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('LOCATAIRES'));
    await tester.pumpAndSettle();

    expect(find.text('Yacine Diop'), findsOneWidget);
    expect(find.text('Camara Mamadou'), findsNothing);
  });

  testWidgets('propriétaires : état vide', (tester) async {
    await _pump(tester, configurer: (s) => s.owners = []);

    await tester.tap(find.text('PROPRIÉTAIRES'));
    await tester.pumpAndSettle();

    expect(find.text('Aucun propriétaire pour le moment.'), findsOneWidget);
    expect(find.text('1 CONTACTS ACTIFS'), findsOneWidget);
  });

  testWidgets('propriétaires : erreur réseau, locataires toujours visibles, '
      'Réessayer recharge', (tester) async {
    final serveur = await _pump(
      tester,
      configurer: (s) => s.ownersEnErreur = true,
    );

    expect(
      find.text('Impossible de charger les propriétaires'),
      findsOneWidget,
    );
    expect(find.text('Yacine Diop'), findsOneWidget);
    expect(find.text('1 CONTACTS ACTIFS'), findsOneWidget);

    serveur.ownersEnErreur = false;
    await tester.tap(find.text('Réessayer'));
    await _settle(tester);

    expect(find.text('Impossible de charger les propriétaires'), findsNothing);
    expect(find.text('Camara Mamadou'), findsOneWidget);
    expect(find.text('3 CONTACTS ACTIFS'), findsOneWidget);
    expect(serveur.appelsSur('/owners'), 2);
  });

  testWidgets('pull-to-refresh recharge les deux listes', (tester) async {
    final serveur = await _pump(tester);
    expect(serveur.appelsSur('/locataires'), 1);
    expect(serveur.appelsSur('/owners'), 1);

    // Appel direct du callback : le geste lui-même relève du framework
    // (RefreshIndicator), seul le câblage `_refresh` est testé ici.
    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await tester.runAsync(indicator.onRefresh);
    await _settle(tester);

    expect(serveur.appelsSur('/locataires'), 2);
    expect(serveur.appelsSur('/owners'), 2);
  });

  testWidgets('tap sur un propriétaire ouvre OwnerDetailScreen', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Camara Mamadou'));
    await tester.pump();
    await _settle(tester);
    await tester.pumpAndSettle();

    expect(find.byType(OwnerDetailScreen), findsOneWidget);
  });

  testWidgets('FAB et bouton « + » masqués sur l\'onglet Propriétaires, '
      'visibles sur Tous et Locataires', (tester) async {
    await _pump(tester);

    // Onglet « Tous » (0).
    expect(find.byType(AppFab), findsOneWidget);
    expect(find.byIcon(LucideIcons.user_plus), findsOneWidget);

    // Onglet Propriétaires (2).
    await tester.tap(find.text('PROPRIÉTAIRES'));
    await tester.pumpAndSettle();
    expect(find.byType(AppFab), findsNothing);
    expect(find.byIcon(LucideIcons.user_plus), findsNothing);

    // Onglet Locataires (1).
    await tester.tap(find.text('LOCATAIRES'));
    await tester.pumpAndSettle();
    expect(find.byType(AppFab), findsOneWidget);
    expect(find.byIcon(LucideIcons.user_plus), findsOneWidget);
  });
}
