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
import 'package:hope_gestion_mobile/features/biens/data/biens_repository.dart';
import 'package:hope_gestion_mobile/features/documents/data/baux_repository.dart';
import 'package:hope_gestion_mobile/features/documents/screens/nouveau_contrat_screen.dart';
import 'package:hope_gestion_mobile/features/locataires/data/locataires_repository.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

Map<String, dynamic> _lotJson({
  required int id,
  required String reference,
  int? ownerId = 7,
  String statut = 'disponible',
  String ownerName = 'Mamadou Camara',
}) => {
  'id': id,
  'reference': reference,
  'immeuble': 'Résidence Palmiers',
  'owner_id': ownerId,
  'owner_name': ownerName,
  'statut': statut,
  'loyer': 185000,
  'caution': 370000,
  'charges': 10000,
  'avance': 2,
};

Map<String, dynamic> _locataireJson({
  required int id,
  required String nom,
  required String prenoms,
  int? ownerId = 7,
  String statut = 'Actif',
}) => {
  'id': id,
  'nom': nom,
  'prenoms': prenoms,
  'telephone_principal': '+2299000000$id',
  'owner_id': ownerId,
  'statut': statut,
};

class _Serveur {
  List<Map<String, dynamic>> lots = [
    _lotJson(id: 1, reference: 'A1'),
    _lotJson(id: 2, reference: 'B2', statut: 'occupe'),
    _lotJson(id: 3, reference: 'C3', ownerId: 9, ownerName: 'Aïcha Sarr'),
    _lotJson(id: 4, reference: 'D4', ownerId: null),
  ];
  List<Map<String, dynamic>> locataires = [
    _locataireJson(id: 1, nom: 'Diop', prenoms: 'Yacine'),
    _locataireJson(id: 2, nom: 'Ndiaye', prenoms: 'Fatou', ownerId: 9),
    _locataireJson(id: 3, nom: 'Traoré', prenoms: 'Amadou', statut: 'Archivé'),
    // Locataire ayant déjà un bail actif : reste proposé.
    {
      ..._locataireJson(id: 4, nom: 'Akue', prenoms: 'Jean-Luc'),
      'active_leases': 1,
    },
  ];

  Map<String, dynamic> creerResponse = {
    'id': 42,
    'reference_bail': 'BAIL-2026-0042',
    'loyer_actuel': '185000.00',
    'statut': 'actif',
  };
  int creerStatusCode = 201;
  DioExceptionType? creerExceptionType;

  final requetes = <RequestOptions>[];
  final creerAppels = <Map<String, dynamic>>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options);
    if (options.path == '/biens/lots') return jsonResponse({'lots': lots}, 200);
    if (options.path == '/locataires') {
      return jsonResponse({'locataires': locataires}, 200);
    }
    if (options.path == '/locations' && options.method == 'POST') {
      creerAppels.add(Map<String, dynamic>.from(options.data as Map));
      final type = creerExceptionType;
      if (type != null) throw DioException(requestOptions: options, type: type);
      return jsonResponse(creerResponse, creerStatusCode);
    }
    throw UnimplementedError('${options.method} ${options.path}');
  }

  int appelsSur(String path, String method) =>
      requetes.where((r) => r.path == path && r.method == method).length;
}

ApiClient _client(_Serveur s) => ApiClient(
  tokenStorage: TokenStorage(),
  dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(s.repondre),
);

Future<_Serveur> _pump(
  WidgetTester tester, {
  bool dark = false,
  void Function(_Serveur)? configurer,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  ThemeController.instance.setDark(dark);

  final serveur = _Serveur();
  configurer?.call(serveur);
  BiensRepository.initialize(BiensRepository(apiClient: _client(serveur)));
  LocatairesRepository.initialize(
    LocatairesRepository(apiClient: _client(serveur)),
  );
  BauxRepository.initialize(BauxRepository(apiClient: _client(serveur)));

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: NouveauContratScreen(maintenant: () => DateTime(2026, 10, 5)),
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

/// Lot A1 (propriétaire 7) puis Yacine Diop → formulaire.
Future<_Serveur> _versLeFormulaire(
  WidgetTester tester, {
  void Function(_Serveur)? configurer,
}) async {
  final serveur = await _pump(tester, configurer: configurer);
  await tester.tap(find.text('A1 · Résidence Palmiers'));
  await tester.pump();
  await tester.tap(find.text('Yacine Diop'));
  await tester.pump();
  expect(find.text('Nouveau contrat de bail'), findsOneWidget);
  return serveur;
}

Future<void> _ouvrirRecap(WidgetTester tester) async {
  await tester.tap(find.text('Continuer'));
  await tester.pumpAndSettle();
  expect(find.text('Confirmer le bail'), findsOneWidget);
}

Future<void> _confirmer(WidgetTester tester) async {
  await tester.tap(find.text('Confirmer'));
  await _settle(tester);
}

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
  });
  tearDown(() => ThemeController.instance.setDark(false));

  group('sélection', () {
    testWidgets('lots : seuls les disponibles avec propriétaire sont proposés', (tester) async {
      await _pump(tester);

      expect(find.text('Choisir un lot'), findsOneWidget);
      expect(find.text('A1 · Résidence Palmiers'), findsOneWidget);
      expect(find.text('C3 · Résidence Palmiers'), findsOneWidget);
      expect(find.text('B2 · Résidence Palmiers'), findsNothing); // occupé
      expect(find.text('D4 · Résidence Palmiers'), findsNothing); // sans propriétaire
      expect(find.textContaining('sans propriétaire'), findsOneWidget);
    });

    testWidgets('locataires : même propriétaire que le lot, non archivés, multi-baux acceptés', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('A1 · Résidence Palmiers'));
      await tester.pump();

      expect(find.text('Choisir un locataire'), findsOneWidget);
      expect(find.text('Yacine Diop'), findsOneWidget);
      expect(find.text('Jean-Luc Akue'), findsOneWidget); // bail actif existant
      expect(find.text('Fatou Ndiaye'), findsNothing); // autre propriétaire
      expect(find.text('Amadou Traoré'), findsNothing); // archivé
    });

    testWidgets('autre lot → locataires de son propriétaire', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('C3 · Résidence Palmiers'));
      await tester.pump();

      expect(find.text('Fatou Ndiaye'), findsOneWidget);
      expect(find.text('Yacine Diop'), findsNothing);
    });
  });

  group('formulaire', () {
    testWidgets('pré-rempli depuis le lot, date_fin et conversion avance affichées', (
      tester,
    ) async {
      await _versLeFormulaire(tester);

      expect(find.text('05/10/2026'), findsOneWidget);
      expect(find.text('Fin prévue : 05/10/2027'), findsOneWidget);
      expect(find.text('Avance : 2 mois = 370 000 FCFA'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, '12'), '6');
      await tester.pump();
      expect(find.text('Fin prévue : 05/04/2027'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, '2'), '3');
      await tester.pump();
      expect(find.text('Avance : 3 mois = 555 000 FCFA'), findsOneWidget);
    });

    testWidgets('jour d’échéance hors bornes : refus, aucun envoi', (tester) async {
      final serveur = await _versLeFormulaire(tester);

      await tester.enterText(find.widgetWithText(TextField, '5'), '32');
      await tester.tap(find.text('Continuer'));
      await tester.pump();

      expect(find.text('Indiquez un jour entre 1 et 31.'), findsOneWidget);
      expect(find.text('Confirmer le bail'), findsNothing);
      expect(serveur.appelsSur('/locations', 'POST'), 0);
    });

    testWidgets('récapitulatif : valeurs et conversion avant confirmation', (tester) async {
      await _versLeFormulaire(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Ex. Usage commercial, meublé…'),
        'Usage commercial',
      );
      await _ouvrirRecap(tester);

      expect(find.text('2 mois = 370 000 FCFA'), findsOneWidget);
      expect(find.text('05/10/2027'), findsOneWidget);
      expect(find.text('Mamadou Camara'), findsWidgets);
      expect(find.text('le 5 du mois'), findsOneWidget);
      expect(find.text('Usage commercial'), findsWidgets);
    });
  });

  group('envoi', () {
    testWidgets('succès : payload, référence affichée', (tester) async {
      final serveur = await _versLeFormulaire(tester);
      await _ouvrirRecap(tester);
      await _confirmer(tester);

      expect(find.textContaining('BAIL-2026-0042'), findsOneWidget);
      final envoye = serveur.creerAppels.single;
      expect(envoye['owner_id'], 7);
      expect(envoye['tenant_id'], 1);
      expect(envoye['lot_id'], 1);
      // Mois brut (comme le web), pas l'équivalent FCFA affiché à l'écran.
      expect(envoye['avance'], 2);
      expect(envoye['avance'], isA<int>());
      expect(envoye['date_fin'], '2027-10-05');
      expect(envoye['jour_echeance'], 5);
      expect(envoye['type_contrat'], 'location');
      expect(envoye['type_paiement'], 'classique');
    });

    testWidgets('double appui = une seule requête', (tester) async {
      final serveur = await _versLeFormulaire(tester);
      await _ouvrirRecap(tester);

      await tester.tap(find.text('Confirmer'));
      await tester.tap(find.text('Confirmer'), warnIfMissed: false);
      await _settle(tester);

      expect(serveur.appelsSur('/locations', 'POST'), 1);
    });

    testWidgets('lot déjà affecté : retour au choix du lot, lot masqué, pas de nouvel essai', (
      tester,
    ) async {
      final serveur = await _versLeFormulaire(
        tester,
        configurer: (s) {
          s.creerStatusCode = 400;
          s.creerResponse = {'message': 'Ce lot a déjà une affectation active'};
        },
      );
      await _ouvrirRecap(tester);
      await _confirmer(tester);
      await tester.pumpAndSettle(); // fin de la fermeture du récapitulatif

      expect(find.text('Choisir un lot'), findsOneWidget);
      expect(find.textContaining('Ce lot a déjà une affectation active'), findsOneWidget);
      expect(find.text('A1 · Résidence Palmiers'), findsNothing);
      expect(serveur.appelsSur('/locations', 'POST'), 1);
    });

    testWidgets('400 générique : message distinct, formulaire conservé', (tester) async {
      await _versLeFormulaire(
        tester,
        configurer: (s) {
          s.creerStatusCode = 400;
          s.creerResponse = {'message': 'Le loyer est requis pour une location'};
        },
      );
      await _ouvrirRecap(tester);
      await _confirmer(tester);

      expect(find.text('Nouveau contrat de bail'), findsOneWidget);
      expect(
        find.text('Le serveur a refusé ces informations : Le loyer est requis pour une location'),
        findsOneWidget,
      );
    });

    testWidgets('403 : message de permission', (tester) async {
      await _versLeFormulaire(
        tester,
        configurer: (s) {
          s.creerStatusCode = 403;
          s.creerResponse = {'message': 'Accès refusé'};
        },
      );
      await _ouvrirRecap(tester);
      await _confirmer(tester);

      expect(find.textContaining("n'avez pas l'autorisation de créer un bail"), findsOneWidget);
    });

    testWidgets('erreur réseau : pas de relance, avertissement « peut-être créé »', (tester) async {
      final serveur = await _versLeFormulaire(
        tester,
        configurer: (s) => s.creerExceptionType = DioExceptionType.connectionError,
      );
      await _ouvrirRecap(tester);
      await _confirmer(tester);

      expect(find.text('Nouveau contrat de bail'), findsOneWidget);
      expect(find.textContaining('peut-être tout de même été créé'), findsOneWidget);
      expect(serveur.appelsSur('/locations', 'POST'), 1);
    });
  });

  for (final dark in [false, true]) {
    testWidgets('rendu clair/sombre sans débordement (sombre: $dark)', (tester) async {
      await _pump(tester, dark: dark);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('A1 · Résidence Palmiers'));
      await tester.pump();
      await tester.tap(find.text('Yacine Diop'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await _ouvrirRecap(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
