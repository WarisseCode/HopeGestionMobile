import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/theme/app_theme.dart';
import 'package:hope_gestion_mobile/core/theme/theme_controller.dart';
import 'package:hope_gestion_mobile/features/documents/models/document.dart';
import 'package:hope_gestion_mobile/features/documents/models/element_document.dart';
import 'package:hope_gestion_mobile/features/documents/screens/document_detail_screen.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../support/fake_url_launcher.dart';

Future<void> _pump(
  WidgetTester tester,
  ElementDocument element, {
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  ThemeController.instance.setDark(dark);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: DocumentDetailScreen(element: element),
    ),
  );
  await tester.pumpAndSettle();
}

final _bail = ElementFichier(
  Document(
    id: 7,
    nom:
        'Contrat_de_bail_Yacine_Marie-Christine_DIOP-NDIAYE_Residence_des_'
        'Palmiers_Cotonou_Akpakpa.pdf',
    categorie: CategorieDocument.bail,
    typeMime: 'application/pdf',
    url: '/uploads/2026/09/Bail_42_3f9a.pdf',
    tailleOctets: 245760,
    entityType: 'lease',
    entityId: 42,
    description: 'Contrat de bail généré automatiquement',
    createdAt: DateTime(2026, 9, 12, 10),
  ),
);

final _quittance = ElementQuittanceManuelle(
  QuittanceManuelle(
    id: 4,
    numero: 'QUI-MAN-2026-0004',
    locataireNom: 'Yacine Marie-Christine DIOP-NDIAYE',
    proprietaireNom: 'Mamadou Camara',
    bien: 'Résidence des Palmiers · Appartement A12 · Cotonou',
    periode: 'Septembre 2026',
    montant: 185000,
    dateEmission: DateTime(2026, 9, 10),
  ),
);

void main() {
  setUp(() => UrlLauncherPlatform.instance = FakeUrlLauncher());
  tearDown(() => ThemeController.instance.setDark(false));

  for (final dark in [false, true]) {
    testWidgets('fichier : détail réel, sans débordement (sombre: $dark)', (
      tester,
    ) async {
      await _pump(tester, _bail, dark: dark);

      expect(tester.takeException(), isNull);
      expect(find.text(_bail.titre), findsOneWidget);
      expect(find.text('Ajouté le'), findsOneWidget);
      expect(find.text('12/09/2026'), findsOneWidget);
      expect(find.text('240 Ko'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('Bail n° 42'), findsOneWidget);
      expect(find.text('Contrat de bail généré automatiquement'), findsOneWidget);
      expect(find.text('Ouvrir'), findsOneWidget);
      // Faux boutons de l'ancienne maquette retirés.
      expect(find.text('Partager via WhatsApp'), findsNothing);
      expect(find.text('Télécharger'), findsNothing);
      expect(find.text('Imprimer'), findsNothing);
    });

    testWidgets(
      'quittance manuelle : données, pas de fichier (sombre: $dark)',
      (tester) async {
        await _pump(tester, _quittance, dark: dark);

        expect(tester.takeException(), isNull);
        expect(find.text('Quittance QUI-MAN-2026-0004'), findsOneWidget);
        expect(find.text('Yacine Marie-Christine DIOP-NDIAYE'), findsOneWidget);
        expect(find.text('Mamadou Camara'), findsOneWidget);
        expect(find.text('Septembre 2026'), findsOneWidget);
        expect(find.text('185 000 F'), findsOneWidget);
        expect(find.text('10/09/2026'), findsOneWidget);
        expect(find.text('Ouvrir'), findsNothing);
        expect(find.textContaining('disponible sur'), findsOneWidget);
      },
    );
  }

  testWidgets('« Ouvrir » lance le lien résolu du fichier', (tester) async {
    final launcher = FakeUrlLauncher(result: true);
    UrlLauncherPlatform.instance = launcher;
    await _pump(tester, _bail);

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(launcher.launched, hasLength(1));
    expect(
      launcher.launched.single,
      endsWith('/uploads/2026/09/Bail_42_3f9a.pdf'),
    );
    expect(launcher.launched.single, startsWith('http'));
  });

  testWidgets('fichier sans URL : pas de bouton, mention claire', (
    tester,
  ) async {
    await _pump(
      tester,
      const ElementFichier(
        Document(id: 1, nom: 'Sans fichier', categorie: CategorieDocument.autre),
      ),
    );

    expect(find.text('Ouvrir'), findsNothing);
    expect(
      find.text("Aucun fichier n'est associé à ce document."),
      findsOneWidget,
    );
  });

  testWidgets('catégorie inconnue : valeur brute affichée', (tester) async {
    await _pump(
      tester,
      ElementFichier(
        Document.tryFromJson({
          'id': 2,
          'nom': 'Ancien.pdf',
          'categorie': 'contrat_signe',
        })!,
      ),
    );

    expect(find.text('Autre (contrat_signe)'), findsOneWidget);
  });
}
