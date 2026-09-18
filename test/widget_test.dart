import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/design_system.dart';
import 'package:hope_gestion_mobile/features/dashboard/widgets/quick_action_sheet.dart';
import 'package:hope_gestion_mobile/features/biens/screens/biens_screen.dart';
import 'package:hope_gestion_mobile/features/biens/screens/nouveau_bien_screen.dart';
import 'package:hope_gestion_mobile/features/locataires/screens/locataires_screen.dart';
import 'package:hope_gestion_mobile/features/locataires/screens/nouveau_locataire_screen.dart';
import 'package:hope_gestion_mobile/core/screens/shell_screen.dart';
import 'package:hope_gestion_mobile/main.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  /// Construit l app avec une taille mobile standard.
  Future<void> buildApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
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

    // Éléments du header
    expect(find.text('Bonjour, Warisse OTCHADE'), findsOneWidget);
    expect(find.text('LUNDI 14 AVRIL'), findsOneWidget);

    // KPIs — labels affichés via label.toUpperCase() dans AppKpiCard
    expect(find.text('ENCAISS.'), findsOneWidget);
    expect(find.text('2,45 M'), findsOneWidget);
    expect(find.text('DÉPENSES'), findsOneWidget);
    expect(find.text('890 K'), findsOneWidget);
    expect(find.text('IMPAYÉS'), findsOneWidget);
    expect(find.text('320 K'), findsOneWidget);

    // Flux chart
    expect(find.text('FLUX · 7 JOURS'), findsOneWidget);
    expect(find.text('+1 560 000 F'), findsOneWidget);

    // Quick Actions
    expect(find.text('CRÉER'), findsOneWidget);
    expect(find.text('Bien'), findsOneWidget);
    expect(find.text('Locataire'), findsOneWidget);

    // Loyers récents
    expect(find.text('LOYERS RÉCENTS'), findsOneWidget);
    expect(find.text('Apt. 12 — Mbour'), findsOneWidget);
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

    // Premier bien de la liste
    expect(find.text('Apt. 12 — Mbour'), findsOneWidget);
    expect(find.text('185 000 F / mois'), findsOneWidget);

    // Badges statut
    expect(find.text('OCCUPÉ'), findsWidgets);
    expect(find.text('VACANT'), findsWidgets);
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
    await tester.enterText(find.byType(TextField), 'Duplex');
    await tester.pumpAndSettle();

    expect(find.text('Duplex — Almadies'), findsOneWidget);
    expect(find.text('Apt. 12 — Mbour'), findsNothing);
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

    // Vérifier l'étape 1
    expect(find.text('Nouveau bien'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Identité du bien'), findsOneWidget);

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

    // Vérifier les éléments clés
    expect(find.text('AVRIL 2026'), findsOneWidget);
    expect(find.text('Finances'), findsWidgets);
    expect(find.text('SOLDE DISPONIBLE'), findsOneWidget);
    expect(find.text('1 560 000 F'), findsOneWidget);
    expect(find.text('+2,45 M'), findsOneWidget);
    expect(find.text('-890 K'), findsOneWidget);
    expect(find.text('Encaisser'), findsOneWidget);
    expect(find.text('Dépense'), findsOneWidget);
    expect(find.text('DERNIÈRES OPÉRATIONS'), findsOneWidget);
    expect(find.text('Loyer reçu'), findsWidgets);
    expect(find.text('Réparation plomberie'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────
  // Test 10 : DocumentsScreen (smoke test & filtrage)
  // ─────────────────────────────────────────────────────────────

  testWidgets('DocumentsScreen smoke test & filtrage via navigation', (
    WidgetTester tester,
  ) async {
    await buildApp(tester);
    await tapTab(tester, 4); // Onglet Docs

    // Vérifier les éléments clés
    expect(find.text('42 DOCUMENTS'), findsOneWidget);
    expect(find.text('Documents'), findsWidgets);
    expect(find.text('QUITTANCES'), findsOneWidget);
    expect(find.text('CONTRATS'), findsOneWidget);
    expect(find.text('FACTURES'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('22'), findsOneWidget);
    expect(find.text('RÉCENTS'), findsOneWidget);
    expect(find.text('Quittance · Avril 2026'), findsOneWidget);
    expect(find.text('Générée'), findsWidgets);
    expect(find.text('Contrat de location'), findsOneWidget);
    expect(find.text('Signé'), findsWidgets);
    expect(find.text('Facture HG-2026-041'), findsOneWidget);
    expect(find.text('À relancer'), findsOneWidget);

    // Filtrer par QUITTANCES
    await tester.tap(find.text('QUITTANCES'));
    await tester.pumpAndSettle();

    // Vérifier le filtre actif
    expect(find.text('Quittance · Avril 2026'), findsOneWidget);
    expect(find.text('Contrat de location'), findsNothing);
    expect(find.text('Facture HG-2026-041'), findsNothing);

    // Réinitialiser avec "Tout afficher"
    await tester.tap(find.text('Tout afficher'));
    await tester.pumpAndSettle();
    expect(find.text('Contrat de location'), findsOneWidget);
  });
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

final Uint8List _transparentPng = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
