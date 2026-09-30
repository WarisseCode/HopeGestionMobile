import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/design_system.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/auth/data/auth_repository.dart';
import 'package:hope_gestion_mobile/features/dashboard/widgets/quick_action_sheet.dart';
import 'package:hope_gestion_mobile/features/biens/data/biens_repository.dart';
import 'package:hope_gestion_mobile/features/biens/screens/biens_screen.dart';
import 'package:hope_gestion_mobile/features/biens/screens/nouveau_bien_screen.dart';
import 'package:hope_gestion_mobile/features/documents/data/documents_repository.dart';
import 'package:hope_gestion_mobile/features/finances/data/finances_repository.dart';
import 'package:hope_gestion_mobile/features/locataires/data/locataires_repository.dart';
import 'package:hope_gestion_mobile/features/locataires/screens/locataires_screen.dart';
import 'package:hope_gestion_mobile/features/locataires/screens/nouveau_locataire_screen.dart';
import 'package:hope_gestion_mobile/core/screens/shell_screen.dart';
import 'package:hope_gestion_mobile/main.dart';

import 'support/fake_http_adapter.dart';
import 'support/mock_http_overrides.dart';

/// Réponses factices pour les routes que `ShellScreen` atteint dès son
/// premier frame : `/auth/profile` (restauration de session, lue par
/// `DashboardHeader` via `AuthRepository.instance`) et les 4 routes
/// `/dashboard/*` (voir `DashboardRepository`) — nécessaire depuis que
/// `DashboardScreen` (premier onglet du shell) charge de vraies données
/// plutôt que `DashboardData.mock()`.
Future<ResponseBody> _shellResponder(RequestOptions options) async {
  switch (options.path) {
    case '/auth/profile':
      return jsonResponse({
        'message': 'Profil récupéré',
        'user': {
          'id': 1,
          'nom': 'Warisse',
          'prenom': 'OTCHADE',
          'email': 'warisse@example.com',
          'telephone': '+2290197000000',
          'role': 'gestionnaire',
          'userType': 'gestionnaire',
          'isGuest': false,
          'photo_url': null,
          'preferences': <String, dynamic>{},
        },
      }, 200);
    case '/dashboard/kpi':
      return jsonResponse({
        'kpis': <dynamic>[],
        'summary': {
          'totalBiens': 5,
          'totalLots': 20,
          'lotsOccupes': 15,
          'lotsLibres': 5,
          'tauxOccupation': 75,
          'loyersEncaisses': 2450000,
          'loyersImpayes': 320000,
          'contratsActifs': 15,
          'plaintesOuvertes': 2,
          'reservationsEnAttente': 1,
          'montantARecouvrer': 320000,
          'echelonementsEnRetard': 0,
        },
      }, 200);
    case '/dashboard/chart-data':
      if (options.queryParameters['period'] == '7d') {
        return jsonResponse({
          'chartData': [
            {'name': '12 Avr', 'revenus': 600000, 'depenses': 300000},
            {'name': '18 Avr', 'revenus': 900000, 'depenses': 250000},
          ],
          'period': '7d',
        }, 200);
      }
      return jsonResponse({
        'chartData': [
          {'name': 'Mars', 'revenus': 2200000, 'depenses': 800000},
          {'name': 'Avr', 'revenus': 2450000, 'depenses': 890000},
        ],
        'period': '6m',
      }, 200);
    case '/dashboard/activity':
      return jsonResponse({
        'activities': [
          {
            'id': 1,
            'type': 'payment',
            'title': 'Paiement reçu',
            'description': 'Yacine Diop - loyer',
            'created_at': '2026-04-14T10:00:00.000Z',
            // NUMERIC renvoyé en chaîne par node-postgres, pas en nombre JSON.
            'montant': '185000.00',
          },
        ],
      }, 200);
    case '/locataires':
      // ShellScreen embarque LocatairesScreen (onglet Contacts), qui charge
      // de vraies données via /locataires dès son premier frame (phase
      // 4.3) — "Yacine Diop" / "Apt. 12" reproduisent volontairement les
      // valeurs attendues par les tests existants (LocatairesScreen smoke
      // test) pour ne pas les réécrire.
      return jsonResponse({
        'locataires': [
          {
            'id': 1,
            'nom': 'Diop',
            'prenoms': 'Yacine',
            'telephone_principal': '+22990000000',
            'type': 'Locataire',
            'statut': 'Actif',
            'lot_nom': 'Apt. 12',
          },
        ],
      }, 200);
    case '/owners':
      return jsonResponse({'success': true, 'owners': <dynamic>[]}, 200);
    case '/biens/immeubles':
      // ShellScreen embarque aussi BiensScreen (onglet Biens), qui charge
      // de vraies données via /biens/immeubles dès son premier frame
      // (phase 4.4).
      return jsonResponse({
        'immeubles': [
          {
            'id': 1,
            'nom': 'Résidence Palmiers',
            'type': 'Immeuble',
            'ville': 'Cotonou',
            'statut': 'actif',
            'nbLots': 3,
            'lotsOccupes': 3,
            'occupation': 100,
            'etatOccupation': 'Complet',
            'proprietaire': 'Mamadou Camara',
          },
          {
            'id': 2,
            'nom': 'Villa Almadies',
            'type': 'Villa',
            'ville': 'Cotonou',
            'statut': 'actif',
            'nbLots': 1,
            'lotsOccupes': 0,
            'occupation': 0,
            'etatOccupation': 'Disponible',
            'proprietaire': 'Aïcha Sarr',
          },
        ],
      }, 200);
    case '/biens/lots':
      return jsonResponse({'lots': <dynamic>[]}, 200);
    case '/finances':
      // ShellScreen embarque aussi FinancesScreen (onglet Finances), qui
      // charge le mois courant dès son premier frame (phase 4.5).
      return jsonResponse({
        'payments': [
          {
            'id': 1,
            'lease_id': 8,
            'amount': '185000.00',
            'payment_date': _moisCourantIso(15),
            'payment_method': 'especes',
            'reference': null,
            'type': 'loyer',
            'statut': 'valide',
            'created_at': null,
            'reference_bail': 'BAIL-008',
            'locataire_nom': 'Diop',
            'locataire_prenoms': 'Yacine',
          },
        ],
      }, 200);
    case '/expenses':
      return ResponseBody.fromString(
        jsonEncode([
          {
            'id': 4,
            'category': 'Travaux / Entretien',
            'amount': '45000.00',
            'date_expense': _moisCourantIso(10),
            'description': 'Réparation plomberie',
            'building_name': 'Résidence Palmiers',
          },
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    case '/finances/stats':
      return jsonResponse({
        'encashed_month': 185000,
        'expenses_month': 45000,
        'net_balance': 140000,
        'pending_total': 320000,
      }, 200);
    // ShellScreen embarque aussi DocumentsScreen (onglet Docs, phase 4.6) :
    // tableaux nus, comme `/expenses`.
    case '/documents':
      return ResponseBody.fromString(
        jsonEncode([
          {
            'id': 7,
            'nom': 'Bail_42.pdf',
            'type': 'application/pdf',
            'url': '/uploads/2026/09/Bail_42_abc.pdf',
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
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    case '/quittances':
      return ResponseBody.fromString(
        jsonEncode([
          {
            'id': 4,
            'numero': 'QUI-MAN-2026-0004',
            'locataire_name': 'Yacine Diop',
            'bien': 'Résidence Palmiers',
            'periode': 'Septembre 2026',
            'montant': '185000.00',
            'date_emission': '2026-09-10T12:00:00.000Z',
          },
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
  }
  throw UnimplementedError(options.path);
}

/// Jour [jour] du mois courant, à midi UTC (même jour quel que soit le
/// fuseau de la machine de test) : `FinancesScreen` affiche le mois courant.
String _moisCourantIso(int jour) {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, jour, 12).toIso8601String();
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  // `TokenStorage` (utilisé pour authentifier `ShellScreen` dans `buildApp`
  // ci-dessous) a besoin d'un double du plugin flutter_secure_storage — voir
  // `test/core/network/token_storage_test.dart`.
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  /// Construit l app avec une taille mobile standard. Initialise
  /// `AuthRepository.instance` avec un `ApiClient` factice (voir
  /// `_shellResponder`) : `ShellScreen` embarque désormais `DashboardScreen`,
  /// qui lit `AuthRepository.instance` et appelle `/dashboard/*` dès son
  /// premier frame (données réelles, plus de `DashboardData.mock()`).
  Future<void> buildApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // `restoreSession()` fait un vrai aller-retour Dio (via `FakeAdapter`) :
    // l'attendre directement dans le corps du test, avant le premier
    // `pumpWidget`, bloque jusqu'au timeout de 10 min de
    // `TestWidgetsFlutterBinding` (piège déjà rencontré et documenté en
    // phase 3.2, voir `auth_gate_test.dart`) — `tester.runAsync()` est le
    // mécanisme officiel pour exécuter du vrai code async dans ce contexte.
    await tester.runAsync(() async {
      final tokenStorage = TokenStorage();
      await tokenStorage.savePair(
        const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter(_shellResponder);
      final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
      AuthRepository.initialize(
        AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
      );
      // ShellScreen embarque aussi LocatairesScreen (onglet Contacts, voir
      // IndexedStack) : accédée dès le premier frame, comme AuthRepository.
      LocatairesRepository.initialize(
        LocatairesRepository(apiClient: apiClient),
      );
      // ShellScreen embarque aussi BiensScreen (onglet Biens, voir
      // IndexedStack) : accédée dès le premier frame, comme les autres.
      BiensRepository.initialize(BiensRepository(apiClient: apiClient));
      // Idem pour FinancesScreen (onglet Finances).
      FinancesRepository.initialize(FinancesRepository(apiClient: apiClient));
      // Idem pour DocumentsScreen (onglet Docs).
      DocumentsRepository.initialize(DocumentsRepository(apiClient: apiClient));
      await AuthRepository.instance.restoreSession();
    });

    await tester.pumpWidget(const HopeGestionApp(home: ShellScreen()));
    await tester.pumpAndSettle();
  }

  /// Tape sur un onglet de la AppBottomBar par index.
  Future<void> tapTab(WidgetTester tester, int index) async {
    final bar = find.byType(AppBottomBar);
    expect(bar, findsOneWidget);
    await tester.tap(
      find.descendant(
        of: bar,
        matching: find.text(AppBottomBar.defaultItems[index].label),
      ),
    );
    await tester.pumpAndSettle();
  }

  // ─────────────────────────────────────────────────────────────
  // Test 1 : Dashboard
  // ─────────────────────────────────────────────────────────────

  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    await buildApp(tester);

    // Éléments du header (nom réel de l'utilisateur authentifié, voir
    // `_shellResponder` — la date du jour n'est plus assertée : elle vient
    // de `DateTime.now()`, non déterministe dans un test).
    expect(find.text('Bonjour, Warisse OTCHADE'), findsOneWidget);

    // KPIs — labels affichés via label.toUpperCase() dans AppKpiCard,
    // valeurs réelles depuis les fixtures /dashboard/kpi et /chart-data.
    expect(find.text('ENCAISS.'), findsOneWidget);
    expect(find.text('2 450 000 F'), findsOneWidget);
    expect(find.text('DÉPENSES'), findsOneWidget);
    expect(find.text('890 000 F'), findsOneWidget);
    expect(find.text('IMPAYÉS'), findsOneWidget);
    expect(find.text('320 000 F'), findsOneWidget);

    // Flux chart — somme réelle des 2 points de /chart-data?period=7d
    // (600k+900k) - (300k+250k) = 950k.
    expect(find.text('FLUX · 7 JOURS'), findsOneWidget);
    expect(find.text('+950 000 F'), findsOneWidget);

    // Quick Actions
    expect(find.text('CRÉER'), findsOneWidget);
    expect(find.text('Bien'), findsOneWidget);
    expect(find.text('Locataire'), findsOneWidget);

    // Loyers récents — depuis /dashboard/activity, filtré type=='payment'.
    expect(find.text('LOYERS RÉCENTS'), findsOneWidget);
    expect(find.text('Yacine Diop - loyer'), findsOneWidget);
    expect(find.text('185 000 F'), findsOneWidget);
    expect(find.text('Payé'), findsWidgets);
  });

  // ─────────────────────────────────────────────────────────────
  // Test 2 : QuickActionSheet depuis Dashboard
  // ─────────────────────────────────────────────────────────────

  testWidgets('QuickActionSheet opens from Dashboard FAB', (
    WidgetTester tester,
  ) async {
    await buildApp(tester);

    // S assurer que le FAB est visible avant de tapper
    final fabFinder = find.byType(AppFab).first;
    await tester.ensureVisible(fabFinder);
    await tester.pumpAndSettle();
    await tester.tap(fabFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(QuickActionSheet), findsOneWidget);
    expect(find.text('Que créer ?'), findsOneWidget);
    expect(find.text('Un bien'), findsOneWidget);
    expect(find.text('Un état des lieux'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────
  // Test 3 : Écran Biens
  // ─────────────────────────────────────────────────────────────

  testWidgets('BiensScreen smoke test', (WidgetTester tester) async {
    await buildApp(tester);
    await tapTab(tester, 1); // onglet Biens

    expect(find.byType(BiensScreen), findsOneWidget);
    expect(find.text('Mes biens'), findsOneWidget);

    // En-tête : 3/3 + 0/1 lots (voir _shellResponder, /biens/immeubles).
    expect(find.text('2 IMMEUBLES · 3/4 LOTS OCCUPÉS'), findsOneWidget);

    // Immeubles de la liste (voir _shellResponder, /biens/immeubles).
    expect(find.text('Résidence Palmiers'), findsOneWidget);
    // Fixtures sans `lotsCrees` (backend antérieur à T-005) : repli sur
    // `nbLots`, sans capacité déclarée.
    expect(find.text('3 lots créés'), findsOneWidget);
    expect(find.text('Villa Almadies'), findsOneWidget);
    expect(find.text('1 lot créé'), findsOneWidget);

    // Propriétaire (`proprietaire` résolu côté serveur).
    expect(find.text('Mamadou Camara'), findsOneWidget);

    // Badges d'état d'occupation (calculés côté serveur).
    expect(find.text('COMPLET'), findsOneWidget);
    expect(find.text('DISPONIBLE'), findsOneWidget);

    // Puces de filtre, avec compteurs.
    expect(find.text('Tous (2)'), findsOneWidget);
    expect(find.text('Disponibles (1)'), findsOneWidget);
    expect(find.text('Complets (1)'), findsOneWidget);
    expect(find.text('Vides (0)'), findsOneWidget);
  });

  testWidgets('BiensScreen — puce de filtre Complets', (
    WidgetTester tester,
  ) async {
    await buildApp(tester);
    await tapTab(tester, 1);

    // Rangée de puces défilante : la police de test (Ahem) les élargit
    // au-delà des 390 px de l'écran, d'où le défilement préalable.
    await tester.ensureVisible(find.text('Complets (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complets (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Résidence Palmiers'), findsOneWidget);
    expect(find.text('Villa Almadies'), findsNothing);
  });

  testWidgets('BiensScreen — le FAB ouvre directement NouveauBienScreen', (
    WidgetTester tester,
  ) async {
    await buildApp(tester);
    await tapTab(tester, 1);

    await tester.tap(
      find.descendant(
        of: find.byType(BiensScreen),
        matching: find.byType(AppFab),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NouveauBienScreen), findsOneWidget);
    expect(find.byType(QuickActionSheet), findsNothing);
  });

  // ─────────────────────────────────────────────────────────────
  // Test 4 : Recherche dans Biens
  // ─────────────────────────────────────────────────────────────

  testWidgets('BiensScreen — filtrage par recherche', (
    WidgetTester tester,
  ) async {
    await buildApp(tester);
    await tapTab(tester, 1);

    // Saisir dans la barre de recherche
    await tester.enterText(find.byType(TextField), 'Villa');
    await tester.pumpAndSettle();

    expect(find.text('Villa Almadies'), findsOneWidget);
    expect(find.text('Résidence Palmiers'), findsNothing);

    // Le bouton d'effacement vide la recherche.
    await tester.tap(find.byTooltip('Effacer la recherche'));
    await tester.pumpAndSettle();

    expect(find.text('Résidence Palmiers'), findsOneWidget);
    expect(find.byTooltip('Effacer la recherche'), findsNothing);
  });

  // ─────────────────────────────────────────────────────────────
  // Test 5 : Écran Locataires
  // ─────────────────────────────────────────────────────────────

  testWidgets('LocatairesScreen smoke test', (WidgetTester tester) async {
    await buildApp(tester);
    await tapTab(tester, 2); // onglet Contacts

    expect(find.byType(LocatairesScreen), findsOneWidget);
    // 'Contacts' apparaît aussi dans la barre de nav → on cherche dans l écran
    expect(
      find.descendant(
        of: find.byType(LocatairesScreen),
        matching: find.text('Contacts'),
      ),
      findsOneWidget,
    );

    // KPI chips
    expect(find.text('LOCATAIRES'), findsOneWidget);
    expect(find.text('PROPRIÉTAIRES'), findsOneWidget);

    // Premier contact
    expect(find.text('Yacine Diop'), findsOneWidget);
    expect(find.text('Locataire · Apt. 12'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────
  // Test 6 : Filtrage par type dans Locataires
  // ─────────────────────────────────────────────────────────────

  testWidgets('LocatairesScreen — filtre par propriétaires', (
    WidgetTester tester,
  ) async {
    await buildApp(tester);
    await tapTab(tester, 2);

    // Taper sur le chip PROPRIÉTAIRES
    await tester.tap(find.text('PROPRIÉTAIRES'));
    await tester.pumpAndSettle();

    // Seuls les propriétaires sont visibles
    expect(find.text('Mamadou Camara'), findsOneWidget);
    expect(find.text('Aïcha Sarr'), findsOneWidget);
    expect(find.text('Yacine Diop'), findsNothing);
  });

  // ─────────────────────────────────────────────────────────────
  // Test 7 : Formulaire Nouveau Bien (smoke & validation)
  // ─────────────────────────────────────────────────────────────

  testWidgets('NouveauBienScreen smoke & stepper test', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: NouveauBienScreen()));
    await tester.pumpAndSettle();

    // Vérifier l'étape 1 (3 étapes depuis la phase 4.4, plus de "Médias" —
    // aucun flux d'upload de photos n'existe encore côté mobile).
    expect(find.text('Nouvel immeuble'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Identité de l\'immeuble'), findsOneWidget);

    // Tenter d'avancer sans remplir -> affiche SnackBar d'erreur
    await tester.tap(find.text('Suivant'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────
  // Test 8 : Formulaire Nouveau Locataire (smoke & stepper)
  // ─────────────────────────────────────────────────────────────

  testWidgets('NouveauLocataireScreen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: NouveauLocataireScreen()));
    await tester.pumpAndSettle();

    // Vérifier l'étape 1
    expect(find.text('Nouveau locataire'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Identité du profil'), findsOneWidget);

    // Tenter d'avancer sans remplir -> SnackBar
    await tester.tap(find.text('Suivant'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────
  // Test 9 : FinancesScreen (smoke test via ShellScreen)
  // ─────────────────────────────────────────────────────────────

  testWidgets('FinancesScreen smoke test via navigation', (
    WidgetTester tester,
  ) async {
    await buildApp(tester);
    await tapTab(tester, 3); // Onglet Finances

    // Vérifier les éléments clés (données de `_shellResponder`)
    expect(find.text('Finances'), findsWidgets);
    expect(find.text('SOLDE DU MOIS'), findsOneWidget);
    expect(find.text('+140 000 F'), findsOneWidget);
    expect(find.text('Encaisser'), findsOneWidget);
    expect(find.text('Dépense'), findsOneWidget);
    expect(find.text('MOUVEMENTS DU MOIS · 2'), findsOneWidget);
    expect(find.text('Yacine Diop'), findsWidgets);
    expect(find.text('+185 000 F'), findsOneWidget);
    expect(find.text('Réparation plomberie'), findsOneWidget);
    expect(find.text('-45 000 F'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────
  // Test 10 : DocumentsScreen (smoke test & filtrage)
  // ─────────────────────────────────────────────────────────────

  testWidgets('DocumentsScreen smoke test & filtrage via navigation', (
    WidgetTester tester,
  ) async {
    await buildApp(tester);
    await tapTab(tester, 4); // Onglet Docs

    // Données réelles de `_shellResponder` (/documents + /quittances) :
    // compteurs calculés depuis la liste, plus aucun chiffre figé.
    expect(find.text('3 DOCUMENTS'), findsOneWidget);
    expect(find.text('Documents'), findsWidgets);
    expect(find.text('Tous (3)'), findsOneWidget);
    expect(find.text('Baux (1)'), findsOneWidget);
    expect(find.text('Quittances (1)'), findsOneWidget);
    expect(find.text('Factures (1)'), findsOneWidget);
    expect(find.text('Bail_42.pdf'), findsOneWidget);
    expect(find.text('Quittance QUI-MAN-2026-0004'), findsOneWidget);
    expect(find.text('Facture plombier.pdf'), findsOneWidget);

    // Filtrer par Quittances (puces en défilement horizontal : amenées à
    // l'écran avant l'appui).
    await tester.ensureVisible(find.text('Quittances (1)'));
    await tester.pump();
    await tester.tap(find.text('Quittances (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Quittance QUI-MAN-2026-0004'), findsOneWidget);
    expect(find.text('Bail_42.pdf'), findsNothing);
    expect(find.text('Facture plombier.pdf'), findsNothing);

    // Retour à « Tous »
    await tester.ensureVisible(find.text('Tous (3)'));
    await tester.pump();
    await tester.tap(find.text('Tous (3)'));
    await tester.pumpAndSettle();
    expect(find.text('Bail_42.pdf'), findsOneWidget);
  });
}
