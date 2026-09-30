import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/core/theme/app_theme.dart';
import 'package:hope_gestion_mobile/core/theme/theme_controller.dart';
import 'package:hope_gestion_mobile/features/documents/data/documents_repository.dart';
import 'package:hope_gestion_mobile/features/documents/screens/document_detail_screen.dart';
import 'package:hope_gestion_mobile/features/documents/screens/documents_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

ResponseBody _listResponse(List<dynamic> body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// Lignes réelles de `GET /documents` (`SELECT *`, `taille` en chaîne).
final _documents = [
  {
    'id': 7,
    'nom': 'Contrat_de_bail_Yacine_Marie-Christine_DIOP-NDIAYE_Residence_des_Palmiers.pdf',
    'type': 'application/pdf',
    'url': '/uploads/2026/09/Bail_42_3f9a.pdf',
    'taille': '245760',
    'categorie': 'baux',
    'entity_type': 'lease',
    'entity_id': 42,
    'created_at': '2026-09-12T10:00:00.000Z',
  },
  {
    'id': 8,
    'nom': 'Facture plombier.pdf',
    'type': 'application/pdf',
    'url': '/uploads/2026/09/facture.pdf',
    'taille': '51200',
    'categorie': 'facture',
    'created_at': '2026-09-05T10:00:00.000Z',
  },
  {
    'id': 9,
    'nom': 'CNI Kouassi.jpg',
    'type': 'image/jpeg',
    'url': '/uploads/2026/08/cni.jpg',
    'taille': '1258291',
    'categorie': 'identite',
    'created_at': '2026-08-20T10:00:00.000Z',
  },
];

/// Lignes réelles de `GET /quittances` (`manual_quittances`).
final _quittances = [
  {
    'id': 4,
    'numero': 'QUI-MAN-2026-0004',
    'locataire_name': 'Yacine Diop',
    'bien': 'Résidence Palmiers',
    'periode': 'Septembre 2026',
    'montant': '185000.00',
    'date_emission': '2026-09-10T12:00:00.000Z',
  },
];

class _Serveur {
  _Serveur({
    this.vide = false,
    this.echecsDocuments = 0,
    this.documentsStatut = 200,
    this.quittancesStatut = 200,
  });

  final bool vide;

  /// Nombre de réponses 500 sur `/documents` avant de répondre normalement.
  int echecsDocuments;
  final int documentsStatut;
  final int quittancesStatut;
  final requetes = <RequestOptions>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options);
    switch (options.path) {
      case '/documents':
        if (echecsDocuments > 0) {
          echecsDocuments--;
          return jsonResponse({'message': 'Erreur serveur'}, 500);
        }
        if (documentsStatut != 200) {
          return jsonResponse({'message': 'Accès refusé'}, documentsStatut);
        }
        return _listResponse(vide ? <dynamic>[] : _documents);
      case '/quittances':
        if (quittancesStatut != 200) {
          return jsonResponse({'message': 'Accès refusé'}, quittancesStatut);
        }
        return _listResponse(vide ? <dynamic>[] : _quittances);
    }
    throw UnimplementedError(options.path);
  }

  List<RequestOptions> sur(String path) =>
      requetes.where((r) => r.path == path).toList();
}

Future<_Serveur> _pump(
  WidgetTester tester, {
  bool dark = false,
  _Serveur? serveur,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  ThemeController.instance.setDark(dark);

  final s = serveur ?? _Serveur();
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(s.repondre);
  DocumentsRepository.initialize(
    DocumentsRepository(
      apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: const DocumentsScreen(),
    ),
  );
  await _settle(tester);
  return s;
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

const _titreBail =
    'Contrat_de_bail_Yacine_Marie-Christine_DIOP-NDIAYE_Residence_des_Palmiers.pdf';

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });
  tearDown(() => ThemeController.instance.setDark(false));

  for (final dark in [false, true]) {
    testWidgets(
      'liste réelle, compteurs calculés depuis la liste, sans débordement '
      '(sombre: $dark)',
      (tester) async {
        await _pump(tester, dark: dark);

        expect(tester.takeException(), isNull);
        // 3 fichiers + 1 quittance manuelle.
        expect(find.text('4 DOCUMENTS'), findsOneWidget);
        expect(find.text('Tous (4)'), findsOneWidget);
        expect(find.text('Baux (1)'), findsOneWidget);
        expect(find.text('Quittances (1)'), findsOneWidget);
        expect(find.text('Factures (1)'), findsOneWidget);
        expect(find.text('Identité (1)'), findsOneWidget);
        // Catégories absentes de la liste : pas de puce.
        expect(find.textContaining('Générés'), findsNothing);
        expect(find.textContaining('Propriétaires'), findsNothing);
        expect(find.text('TOUS LES DOCUMENTS · 4'), findsOneWidget);

        // Ordre : date décroissante, sources fusionnées.
        final titres = [
          _titreBail, // 12/09
          'Quittance QUI-MAN-2026-0004', // 10/09
          'Facture plombier.pdf', // 05/09
          'CNI Kouassi.jpg', // 20/08
        ];
        final ys = titres
            .map((t) => tester.getTopLeft(find.text(t)).dy)
            .toList();
        expect(ys, orderedEquals([...ys]..sort()));
        expect(find.text('Bail · 12/09/2026 · 240 Ko'), findsOneWidget);
        expect(
          find.text('Yacine Diop · Septembre 2026 · 185 000 F'),
          findsOneWidget,
        );

        // Plus aucune donnée ni statut factices de l'ancienne maquette.
        expect(find.text('42 DOCUMENTS'), findsNothing);
        expect(find.text('Générée'), findsNothing);
        expect(find.text('À relancer'), findsNothing);
      },
    );
  }

  testWidgets('filtre par catégorie, puis retour à « Tous »', (tester) async {
    await _pump(tester);

    // Puces en défilement horizontal : amener la puce à l'écran d'abord.
    await tester.ensureVisible(find.text('Factures (1)'));
    await tester.pump();
    await tester.tap(find.text('Factures (1)'));
    await tester.pump();

    expect(find.text('FACTURES · 1'), findsOneWidget);
    expect(find.text('Facture plombier.pdf'), findsOneWidget);
    expect(find.text(_titreBail), findsNothing);
    expect(find.text('Quittance QUI-MAN-2026-0004'), findsNothing);

    // Un second appui sur la puce active la désélectionne.
    await tester.ensureVisible(find.text('Factures (1)'));
    await tester.pump();
    await tester.tap(find.text('Factures (1)'));
    await tester.pump();
    expect(find.text('TOUS LES DOCUMENTS · 4'), findsOneWidget);

    await tester.ensureVisible(find.text('Quittances (1)'));
    await tester.pump();
    await tester.tap(find.text('Quittances (1)'));
    await tester.pump();
    expect(find.text('Quittance QUI-MAN-2026-0004'), findsOneWidget);
    expect(find.text('Facture plombier.pdf'), findsNothing);

    await tester.ensureVisible(find.text('Tous (4)'));
    await tester.pump();
    await tester.tap(find.text('Tous (4)'));
    await tester.pump();
    expect(find.text('Facture plombier.pdf'), findsOneWidget);
  });

  testWidgets('recherche par nom : liste et compteurs mis à jour', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'plombier');
    await tester.pump();

    expect(find.text('Facture plombier.pdf'), findsOneWidget);
    expect(find.text(_titreBail), findsNothing);
    expect(find.text('Tous (1)'), findsOneWidget);
    expect(find.text('Factures (1)'), findsOneWidget);
    expect(find.text('Baux (0)'), findsOneWidget);

    // La recherche porte aussi sur le sous-titre (locataire d'une quittance).
    await tester.enterText(find.byType(TextField), 'DIOP');
    await tester.pump();
    expect(find.text('Quittance QUI-MAN-2026-0004'), findsOneWidget);
    expect(find.text('Tous (2)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'introuvable');
    await tester.pump();
    expect(
      find.text('Aucun document ne correspond à votre recherche.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Effacer la recherche'));
    await tester.pump();
    expect(find.text('Tous (4)'), findsOneWidget);
  });

  testWidgets('liste vide : message dédié, pas de puces', (tester) async {
    await _pump(tester, serveur: _Serveur(vide: true));

    expect(tester.takeException(), isNull);
    expect(find.text('0 DOCUMENTS'), findsOneWidget);
    expect(find.text('Aucun document pour le moment.'), findsOneWidget);
    expect(find.textContaining('Tous ('), findsNothing);
  });

  testWidgets('erreur serveur, puis « Réessayer » recharge', (tester) async {
    final serveur = await _pump(tester, serveur: _Serveur(echecsDocuments: 1));

    expect(find.text('Erreur serveur'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text(_titreBail), findsNothing);

    await tester.tap(find.text('Réessayer'));
    await _settle(tester);

    expect(serveur.sur('/documents'), hasLength(2));
    expect(find.text('Réessayer'), findsNothing);
    expect(find.text('4 DOCUMENTS'), findsOneWidget);
    expect(find.text(_titreBail), findsOneWidget);
  });

  testWidgets(
    'quittances refusées (403, finance:read) : fichiers affichés, mention',
    (tester) async {
      await _pump(tester, serveur: _Serveur(quittancesStatut: 403));

      expect(find.text('3 DOCUMENTS'), findsOneWidget);
      expect(find.text(_titreBail), findsOneWidget);
      expect(find.text('Quittance QUI-MAN-2026-0004'), findsNothing);
      expect(
        find.text(
          'Les quittances manuelles ne sont pas accessibles avec votre rôle.',
        ),
        findsOneWidget,
      );
      expect(find.text('Réessayer'), findsNothing);
    },
  );

  testWidgets('les deux sources refusées (403) : message d’accès', (
    tester,
  ) async {
    await _pump(
      tester,
      serveur: _Serveur(documentsStatut: 403, quittancesStatut: 403),
    );

    expect(find.text("Vous n'avez pas accès aux documents."), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('quittances en erreur serveur (500) : pas de liste incomplète', (
    tester,
  ) async {
    await _pump(tester, serveur: _Serveur(quittancesStatut: 500));

    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text(_titreBail), findsNothing);
  });

  testWidgets('tirage vers le bas : recharge les deux sources', (
    tester,
  ) async {
    final serveur = await _pump(tester);

    await tester.fling(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 400),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);

    expect(serveur.sur('/documents'), hasLength(2));
    expect(serveur.sur('/quittances'), hasLength(2));
  });

  testWidgets('appui sur une ligne : ouvre la fiche du document', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Facture plombier.pdf'));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.text('Ouvrir'), findsOneWidget);
  });
}
