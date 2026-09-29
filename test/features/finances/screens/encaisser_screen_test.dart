import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/core/theme/app_theme.dart';
import 'package:hope_gestion_mobile/core/theme/theme_controller.dart';
import 'package:hope_gestion_mobile/features/finances/data/finances_repository.dart';
import 'package:hope_gestion_mobile/features/finances/screens/encaisser_screen.dart';
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

/// Ligne réelle de `payment_schedules` (voir `/locations/:id/echeancier`).
Map<String, dynamic> _echeanceJson({
  int id = 12,
  int leaseId = 8,
  String total = '185000.00',
  String amountPaid = '0.00',
  String? dueDate = '2026-09-05T12:00:00.000Z',
  String status = 'pending',
  String statut = 'en_attente',
}) => {
  'id': id,
  'lease_id': leaseId,
  'total_amount': total,
  'amount_paid': amountPaid,
  'due_date': dueDate,
  'status': status,
  'statut': statut,
  'description': 'Loyer 9/2026',
};

/// Faux serveur couvrant les quatre routes utilisées par `EncaisserScreen` :
/// `/locataires`, `/locataires/:id`, `/locations/:id/echeancier`,
/// `PUT /finances/schedules/:id/pay`.
class _Serveur {
  List<Map<String, dynamic>> locataires = [_locataireJson()];
  Map<int, List<Map<String, dynamic>>> baux = {
    1: [_bailJson()],
  };
  Map<int, List<Map<String, dynamic>>> echeanciers = {
    8: [_echeanceJson()],
  };

  /// Réponse et code HTTP du prochain `PUT .../pay` ; [payExceptionType], si
  /// posé, est levé à la place (simule une coupure réseau ou un délai dépassé).
  Map<String, dynamic> payResponse = {
    'message': 'Échéance marquée comme payée',
    'soldee': true,
    'reste_du': 0,
    'receiptUrl': null,
  };
  int payStatusCode = 200;
  DioExceptionType? payExceptionType;

  final requetes = <RequestOptions>[];
  final payAppels = <Map<String, dynamic>>[];

  static final _detailRe = RegExp(r'^/locataires/(\d+)$');
  static final _echeancierRe = RegExp(r'^/locations/(\d+)/echeancier$');
  static final _payRe = RegExp(r'^/finances/schedules/(\d+)/pay$');

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
    final echeancier = _echeancierRe.firstMatch(options.path);
    if (echeancier != null) {
      final leaseId = int.parse(echeancier.group(1)!);
      return jsonResponse({'echeancier': echeanciers[leaseId] ?? []}, 200);
    }
    final pay = _payRe.firstMatch(options.path);
    if (pay != null) {
      payAppels.add(Map<String, dynamic>.from(options.data as Map? ?? {}));
      final type = payExceptionType;
      if (type != null) throw DioException(requestOptions: options, type: type);
      return jsonResponse(payResponse, payStatusCode);
    }
    throw UnimplementedError(options.path);
  }

  int appelsSur(RegExp re) => requetes.where((r) => re.hasMatch(r.path)).length;
}

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
  final dioFinances = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(serveur.repondre);
  FinancesRepository.initialize(
    FinancesRepository(apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dioFinances)),
  );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: EncaisserScreen(locataireId: locataireId, maintenant: maintenant),
    ),
  );
  await _settle(tester);
  return serveur;
}

/// Chaque requête est un vrai aller-retour Dio : laisser l'I/O se faire hors
/// de l'horloge factice (`runAsync`), puis reconstruire.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
}

/// Avance jusqu'à l'étape Formulaire : locataire connu (`locataireId: 1`,
/// étape Locataire sautée), un seul bail actif (étape Bail sautée), puis tap
/// sur l'unique échéance ouverte.
Future<_Serveur> _versLeFormulaire(
  WidgetTester tester, {
  DateTime Function()? maintenant,
  void Function(_Serveur)? configurer,
}) async {
  final serveur = await _pump(tester, locataireId: 1, maintenant: maintenant, configurer: configurer);
  expect(find.text('Encaisser un loyer'), findsNothing); // étape Échéance d'abord
  await tester.tap(find.text('Loyer 9/2026'));
  await _settle(tester);
  expect(find.text('Encaisser un loyer'), findsOneWidget);
  return serveur;
}

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
  });
  tearDown(() => ThemeController.instance.setDark(false));

  group('entrée depuis la fiche locataire (locataireId fourni)', () {
    testWidgets('un seul bail actif : étapes Locataire et Bail sautées', (tester) async {
      await _pump(tester, locataireId: 1);

      // Directement sur l'étape Échéance : ni recherche de locataire, ni
      // liste de baux.
      expect(find.text('Choisir une échéance'), findsOneWidget);
      expect(find.text('Rechercher un locataire...'), findsNothing);
      expect(find.text('Loyer 9/2026'), findsOneWidget);
    });

    testWidgets('retour arrière depuis Échéance ferme directement l\'écran', (
      tester,
    ) async {
      final serveur = _Serveur();
      LocatairesRepository.initialize(
        LocatairesRepository(
          apiClient: ApiClient(
            tokenStorage: TokenStorage(),
            dio: Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = FakeAdapter(serveur.repondre),
          ),
        ),
      );
      FinancesRepository.initialize(
        FinancesRepository(
          apiClient: ApiClient(
            tokenStorage: TokenStorage(),
            dio: Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = FakeAdapter(serveur.repondre),
          ),
        ),
      );
      // Poussé par-dessus un premier écran : un `pop` réussi doit démasquer
      // ce dernier plutôt que de changer d'étape à l'intérieur d'EncaisserScreen.
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EncaisserScreen(locataireId: 1)),
                  ),
                  child: const Text('Ouvrir encaissement'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir encaissement'));
      await tester.pumpAndSettle();
      await _settle(tester);

      expect(find.text('Choisir une échéance'), findsOneWidget);

      // Aucune étape n'a été quittée avant celle-ci (locataire/bail sautés) :
      // le retour arrière doit fermer l'écran, pas afficher une étape vide.
      await tester.tap(find.byIcon(LucideIcons.arrow_left));
      await tester.pumpAndSettle();

      expect(find.text('Choisir une échéance'), findsNothing);
      expect(find.text('Ouvrir encaissement'), findsOneWidget);
    });

    testWidgets('plusieurs baux actifs : étape Bail affichée', (tester) async {
      await _pump(
        tester,
        locataireId: 1,
        configurer: (s) => s.baux = {
          1: [
            _bailJson(id: 8, refLot: 'A1'),
            _bailJson(id: 9, refLot: 'B2', statut: 'signe'),
          ],
        },
      );

      expect(find.text('Choisir un bail'), findsOneWidget);
      expect(find.textContaining('A1'), findsOneWidget);
      expect(find.textContaining('B2'), findsOneWidget);
    });

    testWidgets('aucun bail : message clair', (tester) async {
      await _pump(tester, locataireId: 1, configurer: (s) => s.baux = {1: []});

      expect(find.text('Aucun bail enregistré pour ce locataire.'), findsOneWidget);
    });

    testWidgets('aucune échéance ouverte : message clair', (tester) async {
      await _pump(tester, locataireId: 1, configurer: (s) => s.echeanciers = {8: []});

      expect(
        find.textContaining('Aucune échéance ouverte pour ce bail'),
        findsOneWidget,
      );
    });
  });

  group('depuis la liste Locataire (aucun locataireId)', () {
    testWidgets('recherche puis sélection avance vers Bail/Échéance', (
      tester,
    ) async {
      await _pump(
        tester,
        configurer: (s) => s.locataires = [
          _locataireJson(id: 1, nom: 'Diop', prenoms: 'Yacine'),
          _locataireJson(id: 2, nom: 'Ndiaye', prenoms: 'Fatou', tel: '+22991111111'),
        ],
      );

      expect(find.text('Choisir un locataire'), findsOneWidget);
      expect(find.text('Yacine Diop'), findsOneWidget);
      expect(find.text('Fatou Ndiaye'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'fatou');
      await tester.pump();
      expect(find.text('Yacine Diop'), findsNothing);
      expect(find.text('Fatou Ndiaye'), findsOneWidget);

      await tester.tap(find.text('Fatou Ndiaye'));
      await _settle(tester);

      // Un seul bail actif chez le locataire 1 par défaut ; ici 2 n'a pas de
      // bail configuré → message clair, pas de plantage.
      expect(find.text('Aucun bail enregistré pour ce locataire.'), findsOneWidget);
    });
  });

  group('formulaire : montant', () {
    testWidgets('pré-rempli au reste dû (acompte déjà versé)', (tester) async {
      await _versLeFormulaire(
        tester,
        configurer: (s) => s.echeanciers = {
          8: [_echeanceJson(amountPaid: '50000.00', status: 'partial', statut: 'partiel')],
        },
      );

      // Reste dû = 185000 - 50000 = 135000 : c'est la valeur pré-remplie,
      // pas le total de l'échéance. Lu directement sur le contrôleur — le
      // champ « placeholder » (hintText) porte la même valeur par ailleurs
      // (voir `_buildEtapeFormulaire`), donc un `find.text` seul ne suffirait
      // pas à distinguer le contenu réel du texte d'indication.
      final montantField = tester.widget<TextField>(find.byType(TextField).first);
      expect(montantField.controller!.text, '135000');
    });

    testWidgets('supérieur au reste dû refusé, aucun envoi', (tester) async {
      final serveur = await _versLeFormulaire(tester);

      final montantField = find.widgetWithText(TextField, '185000');
      await tester.enterText(montantField, '999999');
      await tester.tap(find.text('Continuer'));
      await tester.pump();

      expect(find.textContaining('dépasse le reste dû'), findsOneWidget);
      expect(serveur.appelsSur(RegExp(r'/pay$')), 0);
    });

    testWidgets('nul refusé, aucun envoi', (tester) async {
      final serveur = await _versLeFormulaire(tester);

      final montantField = find.widgetWithText(TextField, '185000');
      await tester.enterText(montantField, '0');
      await tester.tap(find.text('Continuer'));
      await tester.pump();

      expect(find.textContaining('supérieur à 0'), findsOneWidget);
      expect(serveur.appelsSur(RegExp(r'/pay$')), 0);
    });
  });

  // `validerDateEncaissement` est testée en fonction pure ci-dessous : le
  // sélecteur de date affiché à l'écran (`showDatePicker`) plafonne déjà
  // `lastDate` à aujourd'hui, donc une date future n'est jamais atteignable
  // par l'interface — la règle protège tout de même le cas défensif.
  group('validerDateEncaissement (fonction pure)', () {
    final aujourdhui = DateTime(2026, 9, 28);

    test('date future refusée', () {
      expect(
        validerDateEncaissement(DateTime(2026, 9, 29), aujourdhui),
        contains('futur'),
      );
    });

    test('aujourd\'hui accepté', () {
      expect(validerDateEncaissement(aujourdhui, aujourdhui), isNull);
    });

    test('date passée acceptée', () {
      expect(validerDateEncaissement(DateTime(2026, 9, 1), aujourdhui), isNull);
    });

    test('compare le jour civil, pas l\'heure', () {
      final aujourdhuiSoir = DateTime(2026, 9, 28, 23, 59);
      expect(validerDateEncaissement(aujourdhui, aujourdhuiSoir), isNull);
    });
  });

  group('validerMontantEncaissement (fonction pure)', () {
    test('nul ou négatif refusé', () {
      expect(validerMontantEncaissement(0, 185000), contains('supérieur à 0'));
      expect(validerMontantEncaissement(-10, 185000), contains('supérieur à 0'));
      expect(validerMontantEncaissement(null, 185000), contains('supérieur à 0'));
    });

    test('supérieur au reste dû refusé', () {
      expect(validerMontantEncaissement(185001, 185000), contains('dépasse le reste dû'));
    });

    test('égal au reste dû accepté', () {
      expect(validerMontantEncaissement(185000, 185000), isNull);
    });

    test('tolérance d\'un demi-franc (arrondi du reste dû)', () {
      expect(validerMontantEncaissement(135000, 134999.6), isNull);
    });
  });

  group('envoi', () {
    testWidgets('double appui = une seule requête', (tester) async {
      final serveur = await _versLeFormulaire(tester);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmer'), findsOneWidget);

      // Deux appuis rapprochés, sans laisser la première requête se terminer
      // entre les deux (le verrou est posé de façon synchrone).
      await tester.tap(find.text('Confirmer'));
      await tester.tap(find.text('Confirmer'));
      await _settle(tester);

      expect(serveur.appelsSur(RegExp(r'/pay$')), 1);
    });

    testWidgets('succès avec quittance (solde) : bouton "Ouvrir la quittance"', (
      tester,
    ) async {
      await _versLeFormulaire(
        tester,
        configurer: (s) => s.payResponse = {
          'message': 'Échéance marquée comme payée',
          'soldee': true,
          'reste_du': 0,
          'receiptUrl': '/uploads/receipts/q.pdf',
        },
      );
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await _settle(tester);

      expect(find.text('Échéance marquée comme payée'), findsOneWidget);
      expect(find.text('Ouvrir la quittance'), findsOneWidget);
    });

    testWidgets('succès sans quittance (acompte) : pas de bouton quittance', (
      tester,
    ) async {
      await _versLeFormulaire(
        tester,
        configurer: (s) => s.payResponse = {
          'message': 'Acompte enregistré',
          'soldee': false,
          'reste_du': 135000,
          'receiptUrl': null,
        },
      );
      final montantField = find.widgetWithText(TextField, '185000');
      await tester.enterText(montantField, '50000');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await _settle(tester);

      expect(find.text('Acompte enregistré'), findsOneWidget);
      expect(find.text('Ouvrir la quittance'), findsNothing);

      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();
    });

    testWidgets('409 (déjà soldée) : message, retour et rechargement des échéances', (
      tester,
    ) async {
      final serveur = await _versLeFormulaire(
        tester,
        configurer: (s) {
          s.payStatusCode = 409;
          s.payResponse = {'message': 'Échéance déjà soldée'};
        },
      );
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer'));
      await _settle(tester);

      expect(find.text('Choisir une échéance'), findsOneWidget);
      expect(find.textContaining('Échéance déjà soldée'), findsOneWidget);
      // L'échéancier a été rechargé : 2 appels (initial + après le 409).
      expect(serveur.appelsSur(RegExp(r'/echeancier$')), 2);
    });

    testWidgets(
      '400 : message du serveur dans le formulaire, rien n\'est perdu',
      (tester) async {
        await _versLeFormulaire(
          tester,
          configurer: (s) {
            s.payStatusCode = 400;
            s.payResponse = {'message': 'Montant invalide'};
          },
        );
        await tester.enterText(find.widgetWithText(TextField, '185000'), '150000');
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmer'));
        await _settle(tester);

        // Toujours sur le formulaire, montant saisi conservé.
        expect(find.text('Encaisser un loyer'), findsOneWidget);
        expect(find.textContaining('Montant invalide'), findsOneWidget);
        expect(find.text('150000'), findsOneWidget);
      },
    );

    testWidgets(
      'erreur réseau : pas de nouvel envoi automatique, message et rechargement',
      (tester) async {
        final serveur = await _versLeFormulaire(
          tester,
          configurer: (s) => s.payExceptionType = DioExceptionType.connectionError,
        );
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmer'));
        await _settle(tester);

        expect(find.text('Choisir une échéance'), findsOneWidget);
        expect(
          find.textContaining('encaissement a peut-être tout de même été enregistré'),
          findsOneWidget,
        );
        // Un seul essai de paiement (pas de relance automatique), et
        // l'échéancier a bien été rechargé.
        expect(serveur.appelsSur(RegExp(r'/pay$')), 1);
        expect(serveur.appelsSur(RegExp(r'/echeancier$')), 2);
      },
    );
  });

  for (final dark in [false, true]) {
    testWidgets('rendu clair/sombre sans débordement — toutes les étapes (sombre: $dark)', (
      tester,
    ) async {
      await _pump(
        tester,
        dark: dark,
        configurer: (s) => s.locataires = [
          _locataireJson(id: 1, nom: 'Diop Sonko Marie-Christine', prenoms: 'Yacine'),
        ],
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Yacine Diop Sonko Marie-Christine'));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Choisir une échéance'), findsOneWidget);

      await tester.tap(find.text('Loyer 9/2026'));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Encaisser un loyer'), findsOneWidget);

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Confirmer l\'encaissement'), findsOneWidget);
    });
  }
}
