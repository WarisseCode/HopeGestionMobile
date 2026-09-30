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
import 'package:hope_gestion_mobile/features/documents/screens/nouvelle_quittance_screen.dart';
import 'package:hope_gestion_mobile/features/locataires/data/locataires_repository.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

Map<String, dynamic> _locataireJson({
  int id = 1,
  String nom = 'Diop',
  String prenoms = 'Yacine',
  String tel = '+22990000000',
}) => {'id': id, 'nom': nom, 'prenoms': prenoms, 'telephone_principal': tel};

Map<String, dynamic> _bailJson({
  int id = 8,
  String statut = 'actif',
  String? refLot = 'A1',
  String? buildingName = 'Résidence Palmiers',
}) => {
  'id': id,
  'statut': statut,
  'ref_lot': refLot,
  'building_name': buildingName,
  'loyer_actuel': '185000.00',
};

/// Faux serveur couvrant les routes utilisées par `NouvelleQuittanceScreen` :
/// `/locataires`, `/locataires/:id`, `GET /quittances`, `POST /quittances`.
class _Serveur {
  List<Map<String, dynamic>> locataires = [_locataireJson()];
  Map<int, List<Map<String, dynamic>>> baux = {
    1: [_bailJson()],
  };

  /// Quittances manuelles déjà enregistrées (pour la détection de doublon).
  List<Map<String, dynamic>> quittancesExistantes = [];

  /// Réponse et code HTTP du prochain `POST /quittances` ; [creerExceptionType],
  /// si posé, est levé à la place (simule une coupure réseau).
  Map<String, dynamic> creerResponse = {
    'id': 9,
    'lease_id': 8,
    'numero': 'QUI-MAN-2026-0009',
    'locataire_name': 'Yacine Diop',
    'bien': 'Résidence Palmiers · A1',
    'periode': 'Septembre 2026',
    'montant': '185000.00',
    'date_emission': '2026-09-15',
  };
  int creerStatusCode = 201;
  DioExceptionType? creerExceptionType;

  /// 403 sur `GET /quittances` seul (`finance:read` refusée) : n'empêche pas
  /// la création, seulement la vérification de doublon.
  int quittancesListStatusCode = 200;

  final requetes = <RequestOptions>[];
  final creerAppels = <Map<String, dynamic>>[];

  static final _detailRe = RegExp(r'^/locataires/(\d+)$');

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options);

    if (options.path == '/locataires') {
      return jsonResponse({'locataires': locataires}, 200);
    }
    final detail = _detailRe.firstMatch(options.path);
    if (detail != null) {
      final id = int.parse(detail.group(1)!);
      final locataire = locataires.firstWhere(
        (l) => l['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (locataire.isEmpty) return jsonResponse({'message': 'Introuvable'}, 404);
      return jsonResponse({'locataire': locataire, 'baux': baux[id] ?? [], 'paiements': <dynamic>[]}, 200);
    }
    if (options.path == '/quittances' && options.method == 'GET') {
      if (quittancesListStatusCode != 200) {
        return jsonResponse({'message': 'Accès refusé'}, quittancesListStatusCode);
      }
      return _jsonListResponse(quittancesExistantes, 200);
    }
    if (options.path == '/quittances' && options.method == 'POST') {
      creerAppels.add(Map<String, dynamic>.from(options.data as Map? ?? {}));
      final type = creerExceptionType;
      if (type != null) throw DioException(requestOptions: options, type: type);
      return jsonResponse(creerResponse, creerStatusCode);
    }
    throw UnimplementedError('${options.method} ${options.path}');
  }

  int appelsSur(String path, String method) =>
      requetes.where((r) => r.path == path && r.method == method).length;
}

/// `jsonResponse` (support `fake_http_adapter.dart`) encode un objet ;
/// `GET /quittances` renvoie un tableau nu côté serveur réel — encodage
/// direct ici (même principe que `_listResponse` dans
/// `documents_repository_test.dart`).
ResponseBody _jsonListResponse(List<dynamic> body, int statusCode) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Future<_Serveur> _pump(
  WidgetTester tester, {
  int? locataireId,
  bool dark = false,
  DateTime Function()? maintenant,
  void Function(_Serveur)? configurer,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  ThemeController.instance.setDark(dark);

  final serveur = _Serveur();
  configurer?.call(serveur);

  final dioLocataires = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(serveur.repondre);
  LocatairesRepository.initialize(
    LocatairesRepository(apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dioLocataires)),
  );
  final dioDocuments = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(serveur.repondre);
  DocumentsRepository.initialize(
    DocumentsRepository(apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dioDocuments)),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: NouvelleQuittanceScreen(locataireId: locataireId, maintenant: maintenant),
    ),
  );
  await _settle(tester);
  return serveur;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
}

/// Avance jusqu'à l'étape Formulaire : locataire connu (`locataireId: 1`),
/// un seul bail actif (étape Bail sautée).
Future<_Serveur> _versLeFormulaire(
  WidgetTester tester, {
  DateTime Function()? maintenant,
  void Function(_Serveur)? configurer,
}) async {
  final serveur = await _pump(tester, locataireId: 1, maintenant: maintenant, configurer: configurer);
  expect(find.text('Quittance manuelle'), findsOneWidget);
  return serveur;
}

DateTime _le15Septembre2026() => DateTime(2026, 9, 15);

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
  });
  tearDown(() => ThemeController.instance.setDark(false));

  group('entrée depuis la fiche locataire (locataireId fourni)', () {
    testWidgets('un seul bail actif : étapes Locataire et Bail sautées, formulaire pré-rempli', (
      tester,
    ) async {
      await _pump(tester, locataireId: 1, maintenant: _le15Septembre2026);

      expect(find.text('Quittance manuelle'), findsOneWidget);
      expect(find.text('Rechercher un locataire...'), findsNothing);
      expect(find.text('Yacine Diop'), findsOneWidget);
      expect(find.text('185000'), findsOneWidget);
      expect(find.text('Septembre 2026'), findsOneWidget);
      expect(find.textContaining('A1'), findsOneWidget);
    });

    testWidgets('avertissement permanent visible', (tester) async {
      await _pump(tester, locataireId: 1, maintenant: _le15Septembre2026);

      expect(
        find.textContaining("n'enregistre aucun paiement"),
        findsOneWidget,
      );
    });
  });

  group('validerMontantQuittance (fonction pure)', () {
    test('nul, négatif ou zéro refusé', () {
      expect(validerMontantQuittance(0), contains('supérieur à 0'));
      expect(validerMontantQuittance(-10), contains('supérieur à 0'));
      expect(validerMontantQuittance(null), contains('supérieur à 0'));
    });

    test('positif accepté', () {
      expect(validerMontantQuittance(185000), isNull);
    });
  });

  group('validerPeriodeQuittance (fonction pure)', () {
    final maintenant = DateTime(2026, 9, 15);

    test('mois futur refusé', () {
      expect(
        validerPeriodeQuittance(DateTime(2026, 10, 1), maintenant),
        contains('futur'),
      );
    });

    test('mois courant accepté', () {
      expect(validerPeriodeQuittance(DateTime(2026, 9, 1), maintenant), isNull);
    });

    test('mois passé accepté', () {
      expect(validerPeriodeQuittance(DateTime(2026, 8, 1), maintenant), isNull);
    });
  });

  group('validerDateEmissionQuittance (fonction pure)', () {
    final aujourdhui = DateTime(2026, 9, 15);

    test('date future refusée', () {
      expect(
        validerDateEmissionQuittance(DateTime(2026, 9, 16), aujourdhui),
        contains('futur'),
      );
    });

    test("aujourd'hui accepté", () {
      expect(validerDateEmissionQuittance(aujourdhui, aujourdhui), isNull);
    });
  });

  group('doublon', () {
    testWidgets('quittance déjà enregistrée pour ce bail et cette période : avertissement', (
      tester,
    ) async {
      await _versLeFormulaire(
        tester,
        maintenant: _le15Septembre2026,
        configurer: (s) => s.quittancesExistantes = [
          {
            'id': 1,
            'lease_id': 8,
            'numero': 'QUI-MAN-2026-0001',
            'periode': 'Septembre 2026',
            'montant': '185000.00',
          },
        ],
      );

      expect(
        find.textContaining('existe déjà pour ce bail et cette période'),
        findsOneWidget,
      );
    });

    testWidgets('bail ou période différente : aucun avertissement', (tester) async {
      await _versLeFormulaire(
        tester,
        maintenant: _le15Septembre2026,
        configurer: (s) => s.quittancesExistantes = [
          {
            'id': 1,
            'lease_id': 8,
            'numero': 'QUI-MAN-2026-0001',
            'periode': 'Août 2026',
            'montant': '185000.00',
          },
        ],
      );

      expect(
        find.textContaining('existe déjà pour ce bail et cette période'),
        findsNothing,
      );
    });

    testWidgets('GET /quittances refusée (403) : mention non bloquante', (tester) async {
      await _versLeFormulaire(
        tester,
        maintenant: _le15Septembre2026,
        configurer: (s) => s.quittancesListStatusCode = 403,
      );

      expect(
        find.textContaining("n'ont pas pu être vérifiées"),
        findsOneWidget,
      );
      // Le formulaire reste utilisable malgré l'échec de la vérification.
      expect(find.text('Continuer'), findsOneWidget);
    });
  });

  group('validation avant récapitulatif', () {
    testWidgets('montant nul refusé, aucun envoi', (tester) async {
      final serveur = await _versLeFormulaire(tester, maintenant: _le15Septembre2026);

      await tester.enterText(find.widgetWithText(TextField, '185000'), '0');
      await tester.tap(find.text('Continuer'));
      await tester.pump();

      expect(find.textContaining('supérieur à 0'), findsOneWidget);
      expect(serveur.appelsSur('/quittances', 'POST'), 0);
    });
  });

  group('envoi', () {
    testWidgets('double appui = une seule requête', (tester) async {
      final serveur = await _versLeFormulaire(tester, maintenant: _le15Septembre2026);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmer'), findsOneWidget);

      await tester.tap(find.text('Confirmer'));
      await tester.tap(find.text('Confirmer'));
      await _settle(tester);

      expect(serveur.appelsSur('/quittances', 'POST'), 1);
    });

    testWidgets('succès : numéro attribué affiché', (tester) async {
      await _versLeFormulaire(tester, maintenant: _le15Septembre2026);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await _settle(tester);

      expect(find.textContaining('QUI-MAN-2026-0009'), findsOneWidget);
    });

    testWidgets('400 : message du serveur, formulaire conservé', (tester) async {
      await _versLeFormulaire(
        tester,
        maintenant: _le15Septembre2026,
        configurer: (s) {
          s.creerStatusCode = 400;
          s.creerResponse = {'message': 'Montant invalide (> 0)'};
        },
      );
      await tester.enterText(find.widgetWithText(TextField, '185000'), '150000');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await _settle(tester);

      expect(find.text('Quittance manuelle'), findsOneWidget);
      expect(find.textContaining('Montant invalide'), findsOneWidget);
      expect(find.text('150000'), findsOneWidget);
    });

    testWidgets('404 (bail refusé) : message, formulaire conservé', (tester) async {
      await _versLeFormulaire(
        tester,
        maintenant: _le15Septembre2026,
        configurer: (s) {
          s.creerStatusCode = 404;
          s.creerResponse = {'message': 'Bail introuvable ou accès refusé'};
        },
      );
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await _settle(tester);

      expect(find.textContaining('Bail introuvable'), findsOneWidget);
    });

    testWidgets(
      'erreur réseau : pas de nouvel envoi automatique, message et rechargement',
      (tester) async {
        final serveur = await _versLeFormulaire(
          tester,
          maintenant: _le15Septembre2026,
          configurer: (s) => s.creerExceptionType = DioExceptionType.connectionError,
        );
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmer'));
        await _settle(tester);

        expect(find.text('Quittance manuelle'), findsOneWidget);
        expect(
          find.textContaining('peut-être tout de même été créée'),
          findsOneWidget,
        );
        expect(serveur.appelsSur('/quittances', 'POST'), 1);
        // Rechargement de la liste des quittances après l'échec réseau (en
        // plus du chargement initial pour la vérification de doublon).
        expect(serveur.appelsSur('/quittances', 'GET'), 2);
      },
    );
  });

  group('entrée depuis la fiche locataire (recherche)', () {
    testWidgets('recherche puis sélection avance vers le formulaire', (tester) async {
      await _pump(
        tester,
        maintenant: _le15Septembre2026,
        configurer: (s) => s.locataires = [
          _locataireJson(id: 1, nom: 'Diop', prenoms: 'Yacine'),
          _locataireJson(id: 2, nom: 'Ndiaye', prenoms: 'Fatou', tel: '+22991111111'),
        ],
      );

      expect(find.text('Choisir un locataire'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'yacine');
      await tester.pump();
      await tester.tap(find.text('Yacine Diop'));
      await _settle(tester);

      expect(find.text('Quittance manuelle'), findsOneWidget);
    });
  });

  for (final dark in [false, true]) {
    testWidgets('rendu clair/sombre sans débordement (sombre: $dark)', (tester) async {
      await _pump(tester, locataireId: 1, dark: dark, maintenant: _le15Septembre2026);
      expect(tester.takeException(), isNull);
      expect(find.text('Quittance manuelle'), findsOneWidget);

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Confirmer la quittance'), findsOneWidget);
    });
  }
}
