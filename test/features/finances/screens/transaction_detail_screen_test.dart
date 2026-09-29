import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/core/theme/app_theme.dart';
import 'package:hope_gestion_mobile/core/theme/theme_controller.dart';
import 'package:hope_gestion_mobile/features/finances/data/finances_repository.dart';
import 'package:hope_gestion_mobile/features/finances/models/depense.dart';
import 'package:hope_gestion_mobile/features/finances/models/mouvement.dart';
import 'package:hope_gestion_mobile/features/finances/models/paiement.dart';
import 'package:hope_gestion_mobile/features/finances/screens/transaction_detail_screen.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../support/fake_clipboard.dart';
import '../../../support/fake_http_adapter.dart';
import '../../../support/fake_url_launcher.dart';
import '../../../support/mock_http_overrides.dart';

Paiement _paiement({String? quittanceUrl}) => Paiement(
  id: 12,
  montant: 185000,
  date: DateTime(2026, 9, 15),
  leaseId: 8,
  modePaiement: 'mobile_money',
  reference: 'MM-2026-09-15-0001234567890',
  type: 'loyer',
  description: 'Loyer de septembre, réglé en deux fois au guichet',
  referenceBail: 'BAIL-2026-008-AVEC-UNE-REFERENCE-TRES-LONGUE',
  locataireNom: 'DIOP-NDIAYE',
  locatairePrenoms: 'Yacine Marie-Christine',
  proprietaireNom: 'CAMARA Mamadou',
  quittanceUrl: quittanceUrl,
);

Depense _depense({String? justificatif}) => Depense(
  id: 4,
  categorie: 'Travaux / Entretien',
  montant: 45000,
  date: DateTime(2026, 9, 10),
  description: 'Réparation plomberie de la colonne d\'eau principale',
  fournisseur: 'Plomberie Générale du Littoral SARL',
  immeubleNom: 'Résidence des Palmiers au nom particulièrement long',
  lotReference: 'A12',
  justificatifUrl: justificatif,
);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  ThemeController.instance.setDark(dark);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: home,
    ),
  );
  await tester.pump();
}

/// Chargement par id : vrai aller-retour Dio, I/O hors horloge factice
/// puis avance de l'horloge (même helper que `finances_screen_test.dart`).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
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
    // Pas d'implémentation native de url_launcher en test (MissingPluginException
    // sinon) : succès par défaut, chaque test d'échec pose son propre double.
    UrlLauncherPlatform.instance = FakeUrlLauncher();
    // Idem pour Clipboard.setData/getData (repli d'« Ouvrir » en échec) :
    // sans double, l'appel reste en attente indéfiniment.
    FakeClipboard().install();
  });
  tearDown(() => ThemeController.instance.setDark(false));

  for (final dark in [false, true]) {
    testWidgets('détail d\'un paiement, sans débordement (sombre: $dark)', (
      tester,
    ) async {
      await _pump(
        tester,
        TransactionDetailScreen(
          mouvement: MouvementPaiement(
            _paiement(quittanceUrl: '/uploads/receipts/quittance_202609-12.pdf'),
          ),
        ),
        dark: dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Détail du paiement'), findsOneWidget);
      expect(find.text('+185 000 F'), findsOneWidget);
      expect(find.text('Encaissement · Loyer'), findsOneWidget);
      expect(find.text('Validé'), findsOneWidget);
      expect(find.text('Yacine Marie-Christine DIOP-NDIAYE'), findsOneWidget);
      expect(
        find.text('BAIL-2026-008-AVEC-UNE-REFERENCE-TRES-LONGUE'),
        findsOneWidget,
      );
      expect(find.text('15/09/2026'), findsOneWidget);
      expect(find.text('Mobile Money'), findsOneWidget);
      expect(find.text('MM-2026-09-15-0001234567890'), findsOneWidget);
      expect(find.text('Quittance (PDF)'), findsOneWidget);
      expect(
        find.textContaining('/uploads/receipts/quittance_202609-12.pdf'),
        findsOneWidget,
      );
    });

    testWidgets('détail d\'une dépense, sans débordement (sombre: $dark)', (
      tester,
    ) async {
      await _pump(
        tester,
        TransactionDetailScreen(
          mouvement: MouvementDepense(
            _depense(justificatif: '/uploads/expenses/facture-plomberie.jpg'),
          ),
        ),
        dark: dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Détail de la dépense'), findsOneWidget);
      expect(find.text('-45 000 F'), findsOneWidget);
      expect(find.text('Dépense · Travaux / Entretien'), findsOneWidget);
      expect(find.text('Travaux / Entretien'), findsOneWidget);
      expect(
        find.text('Résidence des Palmiers au nom particulièrement long'),
        findsOneWidget,
      );
      expect(find.text('A12'), findsOneWidget);
      expect(find.text('Plomberie Générale du Littoral SARL'), findsOneWidget);
      expect(find.text('10/09/2026'), findsOneWidget);
      // Justificatif image : aperçu via `AppConfig.resolveFileUrl`.
      expect(find.text('JUSTIFICATIF'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        endsWith('/uploads/expenses/facture-plomberie.jpg'),
      );
      expect((image.image as NetworkImage).url, startsWith('http'));
    });
  }

  testWidgets('paiement sans quittance : pas de lien', (tester) async {
    await _pump(
      tester,
      TransactionDetailScreen(mouvement: MouvementPaiement(_paiement())),
    );

    expect(find.text('Quittance (PDF)'), findsNothing);
  });

  testWidgets('dépense : justificatif PDF → lien « Ouvrir », sans justificatif',
      (tester) async {
    await _pump(
      tester,
      TransactionDetailScreen(
        mouvement: MouvementDepense(
          _depense(justificatif: 'https://cdn.test/expenses/facture.pdf'),
        ),
      ),
    );
    expect(find.text('Justificatif'), findsOneWidget);
    expect(find.text('https://cdn.test/expenses/facture.pdf'), findsOneWidget);
    expect(find.text('Ouvrir'), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await _pump(
      tester,
      TransactionDetailScreen(mouvement: MouvementDepense(_depense())),
    );
    expect(find.text('Aucun justificatif joint.'), findsOneWidget);
  });

  group('« Ouvrir » un fichier (quittance ou justificatif PDF)', () {
    testWidgets('succès : lance le lien résolu, pas de repli', (tester) async {
      final launcher = FakeUrlLauncher(result: true);
      UrlLauncherPlatform.instance = launcher;

      await _pump(
        tester,
        TransactionDetailScreen(
          mouvement: MouvementPaiement(
            _paiement(quittanceUrl: '/uploads/receipts/quittance_202609-12.pdf'),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(launcher.launched, hasLength(1));
      expect(
        launcher.launched.single,
        endsWith('/uploads/receipts/quittance_202609-12.pdf'),
      );
      expect(launcher.launched.single, startsWith('http'));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
      'échec (aucune application compatible) : copie le lien, message clair',
      (tester) async {
        UrlLauncherPlatform.instance = FakeUrlLauncher(result: false);

        await _pump(
          tester,
          TransactionDetailScreen(
            mouvement: MouvementDepense(
              _depense(justificatif: 'https://cdn.test/expenses/facture.pdf'),
            ),
          ),
        );
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining("Impossible d'ouvrir ce fichier"),
          findsOneWidget,
        );
        final copie = await Clipboard.getData(Clipboard.kTextPlain);
        expect(copie?.text, 'https://cdn.test/expenses/facture.pdf');
      },
    );

    testWidgets(
      'échec (exception plateforme) : copie le lien aussi, sans planter',
      (tester) async {
        UrlLauncherPlatform.instance = FakeUrlLauncher(throws: true);

        await _pump(
          tester,
          TransactionDetailScreen(
            mouvement: MouvementDepense(
              _depense(justificatif: 'https://cdn.test/expenses/facture.pdf'),
            ),
          ),
        );
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.textContaining("Impossible d'ouvrir ce fichier"),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets(
    'depuis le tableau de bord : charge le paiement par son id',
    (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeAdapter((options) async {
          expect(options.path, '/finances');
          expect(options.queryParameters, isEmpty);
          return jsonResponse({
            'payments': [
              {
                'id': 3,
                'amount': '90000.00',
                'payment_date': '2026-09-01T12:00:00.000Z',
                'statut': 'valide',
              },
              {
                'id': 12,
                'amount': '185000.00',
                'payment_date': '2026-09-15T12:00:00.000Z',
                'payment_method': 'especes',
                'type': 'loyer',
                'statut': 'valide',
                'locataire_nom': 'Diop',
                'locataire_prenoms': 'Yacine',
              },
            ],
          }, 200);
        });
      FinancesRepository.initialize(
        FinancesRepository(
          apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
        ),
      );

      await _pump(tester, const TransactionDetailScreen.paiement(paiementId: 12));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Yacine Diop'), findsOneWidget);
      expect(find.text('+185 000 F'), findsOneWidget);
      expect(find.text('Espèces'), findsOneWidget);
    },
  );

  testWidgets('depuis le tableau de bord : paiement introuvable', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter(
        (_) async => jsonResponse({'payments': <dynamic>[]}, 200),
      );
    FinancesRepository.initialize(
      FinancesRepository(
        apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
      ),
    );

    await _pump(tester, const TransactionDetailScreen.paiement(paiementId: 99));
    await _settle(tester);

    expect(find.text('Ce paiement est introuvable.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
