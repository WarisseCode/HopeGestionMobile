import 'dart:convert';
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
import 'package:hope_gestion_mobile/features/auth/data/auth_repository.dart';
import 'package:hope_gestion_mobile/features/biens/data/biens_repository.dart';
import 'package:hope_gestion_mobile/features/finances/data/finances_repository.dart';
import 'package:hope_gestion_mobile/features/finances/screens/depense_screen.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

/// Double d'`ImagePicker` : renvoie [nextPath] (fichier réel sur disque,
/// dont la taille réelle est donc lue par `File.length()` côté écran/dépôt)
/// ou lève si [throwOnPick]. `pickImage(source:...)` (package `image_picker`)
/// délègue à `getImageFromSource` de la plateforme.
class _FakeImagePicker extends ImagePickerPlatform {
  String? nextPath;
  bool throwOnPick = false;
  ImageSource? dernierSource;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    dernierSource = source;
    if (throwOnPick) throw Exception('Erreur picker simulée');
    final path = nextPath;
    return path == null ? null : XFile(path);
  }
}

/// `jsonResponse` (fake_http_adapter.dart) n'accepte qu'un objet :
/// `/expenses/categories` renvoie un tableau nu.
ResponseBody _listResponse(List<dynamic> body, int statusCode) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// Faux serveur couvrant les cinq routes utilisées par `DepenseScreen` :
/// `/biens/immeubles`, `/biens/lots`, `/expenses/categories`, `/owners`,
/// `POST /expenses`.
class _Serveur {
  List<Map<String, dynamic>> immeubles = [
    {'id': 1, 'nom': 'Résidence Palmiers'},
    {'id': 2, 'nom': 'Villa Almadies'},
  ];
  List<Map<String, dynamic>> lots = [
    {'id': 10, 'reference': 'A1', 'building_id': 1},
    {'id': 11, 'reference': 'B2', 'building_id': 1},
  ];
  List<Map<String, dynamic>> categories = [
    {'id': 1, 'name': 'Travaux & Réparations'},
    {'id': 2, 'name': 'Entretien'},
  ];
  List<Map<String, dynamic>> owners = [
    {'id': 5, 'name': 'CAMARA', 'first_name': 'Awa'},
  ];

  Map<String, dynamic> creerResponse = {
    'id': 42,
    'category': 'Travaux & Réparations',
    'amount': '45000.00',
    'date_expense': '2026-09-10T12:00:00.000Z',
  };
  int creerStatusCode = 201;
  DioExceptionType? creerExceptionType;

  final requetes = <RequestOptions>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options);
    switch (options.path) {
      case '/biens/immeubles':
        return jsonResponse({'immeubles': immeubles}, 200);
      case '/biens/lots':
        return jsonResponse({'lots': lots}, 200);
      case '/expenses/categories':
        return _listResponse(categories, 200);
      case '/owners':
        return jsonResponse({'owners': owners}, 200);
      case '/expenses':
        if (options.method == 'POST') {
          final type = creerExceptionType;
          if (type != null) {
            throw DioException(requestOptions: options, type: type);
          }
          return jsonResponse(creerResponse, creerStatusCode);
        }
    }
    throw UnimplementedError(options.path);
  }

  int appelsSur(String path) => requetes.where((r) => r.path == path).length;
}

Future<_Serveur> _pump(
  WidgetTester tester, {
  bool dark = false,
  DateTime Function()? maintenant,
  void Function(_Serveur)? configurer,
}) async {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  ThemeController.instance.setDark(dark);

  final serveur = _Serveur();
  configurer?.call(serveur);

  ApiClient client() {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter(serveur.repondre);
    return ApiClient(tokenStorage: TokenStorage(), dio: dio);
  }

  AuthRepository.initialize(
    AuthRepository(apiClient: client(), tokenStorage: TokenStorage()),
  );
  BiensRepository.initialize(BiensRepository(apiClient: client()));
  FinancesRepository.initialize(FinancesRepository(apiClient: client()));

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: DepenseScreen(maintenant: maintenant),
    ),
  );
  await _settle(tester);
  return serveur;
}

/// Chaque requête est un vrai aller-retour Dio : laisser l'I/O se faire hors
/// de l'horloge factice (`runAsync`), puis reconstruire — même pattern que
/// `encaisser_screen_test.dart`.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
}

/// Remplit le minimum requis (catégorie, montant, propriétaire) puis ouvre
/// le récapitulatif.
Future<void> _remplirEtOuvrirRecap(WidgetTester tester) async {
  await tester.tap(find.text('Travaux & Réparations'));
  await tester.pump();
  await tester.enterText(find.widgetWithText(TextField, '45000'), '15000');
  await tester.tap(find.text('Propriétaire'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Choisir un propriétaire'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('CAMARA Awa').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Enregistrer la dépense'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());

  late _FakeImagePicker fakePicker;
  late File photoValide;
  late File photoTropGrosse;

  setUpAll(() async {
    photoValide = File(
      '${Directory.systemTemp.path}/depense_screen_test_valide.jpg',
    );
    await photoValide.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
    photoTropGrosse = File(
      '${Directory.systemTemp.path}/depense_screen_test_trop_grosse.jpg',
    );
    await photoTropGrosse.writeAsBytes(List.filled(11 * 1024 * 1024, 0));
  });

  tearDownAll(() async {
    // Windows verrouille parfois encore le fichier (décodeur d'image du
    // dernier test) : un échec de suppression n'est pas une fuite grave (le
    // fichier reste dans le dossier temporaire du système, nettoyé par l'OS)
    // et ne doit pas faire échouer la suite.
    try {
      if (await photoValide.exists()) await photoValide.delete();
    } catch (_) {}
    try {
      if (await photoTropGrosse.exists()) await photoTropGrosse.delete();
    } catch (_) {}
  });

  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    fakePicker = _FakeImagePicker();
    ImagePickerPlatform.instance = fakePicker;
  });
  tearDown(() => ThemeController.instance.setDark(false));

  /// Ouvre le sélecteur de justificatif et choisit la galerie (le fond
  /// factice répond `photoValide`/`photoTropGrosse` selon [fakePicker
  /// .nextPath], quelle que soit la source choisie). `_settle` (et non
  /// `pumpAndSettle`) : après la sélection, l'écran lit une vraie taille de
  /// fichier sur disque (`File.length()`), une E/S réelle comme les appels
  /// Dio — même raison que `_settle` dans `encaisser_screen_test.dart`.
  Future<void> choisirJustificatif(WidgetTester tester) async {
    await tester.tap(find.text('Prendre une photo ou importer un reçu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir depuis la galerie'));
    await tester.pumpAndSettle();
    await _settle(tester);
  }

  testWidgets('catégories du serveur affichées', (tester) async {
    await _pump(tester);
    expect(find.text('Travaux & Réparations'), findsOneWidget);
    expect(find.text('Entretien'), findsOneWidget);
  });

  testWidgets('rattachement obligatoire : aucun choix → message clair', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Travaux & Réparations'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, '45000'), '15000');
    await tester.tap(find.text('Enregistrer la dépense'));
    await tester.pump();

    expect(
      find.text('Choisissez un immeuble ou un propriétaire.'),
      findsOneWidget,
    );
  });

  testWidgets('montant nul refusé', (tester) async {
    final serveur = await _pump(tester);
    await tester.tap(find.text('Travaux & Réparations'));
    await tester.pump();
    await tester.tap(find.text('Propriétaire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir un propriétaire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CAMARA Awa').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer la dépense'));
    await tester.pump();

    expect(find.textContaining('supérieur à 0'), findsOneWidget);
    expect(serveur.appelsSur('/expenses'), 0);
  });

  group('envoi', () {
    testWidgets('double appui = une seule requête', (tester) async {
      final serveur = await _pump(tester);
      await _remplirEtOuvrirRecap(tester);
      expect(find.text('Confirmer'), findsOneWidget);

      await tester.tap(find.text('Confirmer'));
      await tester.tap(find.text('Confirmer'));
      await _settle(tester);

      expect(serveur.appelsSur('/expenses'), 1);
    });

    testWidgets('succès : confirmation puis retour', (tester) async {
      await _pump(tester);
      await _remplirEtOuvrirRecap(tester);
      await tester.tap(find.text('Confirmer'));
      await _settle(tester);

      expect(find.text('Dépense enregistrée'), findsOneWidget);
    });

    testWidgets(
      '400 : message du serveur affiché, champs et justificatif conservés',
      (tester) async {
        await _pump(
          tester,
          configurer: (s) {
            s.creerStatusCode = 400;
            s.creerResponse = {'message': 'Montant invalide (> 0)'};
          },
        );
        fakePicker.nextPath = photoValide.path;
        await choisirJustificatif(tester);
        await _remplirEtOuvrirRecap(tester);
        await tester.tap(find.text('Confirmer'));
        await _settle(tester);

        // Retour au formulaire (pas la feuille de succès), montant et
        // justificatif conservés (aperçu toujours affiché, pas le repli vide).
        expect(find.text('Enregistrer une dépense'), findsOneWidget);
        expect(find.textContaining('Montant invalide'), findsOneWidget);
        expect(find.text('15000'), findsOneWidget);
        expect(find.byIcon(LucideIcons.x), findsOneWidget);
        expect(
          find.text('Prendre une photo ou importer un reçu'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'erreur réseau : pas de nouvel envoi automatique, message affiché',
      (tester) async {
        final serveur = await _pump(
          tester,
          configurer: (s) => s.creerExceptionType = DioExceptionType.connectionError,
        );
        await _remplirEtOuvrirRecap(tester);
        await tester.tap(find.text('Confirmer'));
        await _settle(tester);

        expect(
          find.textContaining('peut-être tout de même été enregistrée'),
          findsOneWidget,
        );
        // Un seul essai, formulaire toujours affiché (rien perdu), aucun
        // renvoi automatique.
        expect(serveur.appelsSur('/expenses'), 1);
        expect(find.text('Enregistrer une dépense'), findsOneWidget);
        expect(find.text('15000'), findsOneWidget);
      },
    );
  });

  group('justificatif', () {
    testWidgets('sélection : aperçu affiché, remplace le repli vide', (
      tester,
    ) async {
      await _pump(tester);
      fakePicker.nextPath = photoValide.path;

      await choisirJustificatif(tester);

      expect(
        find.text('Prendre une photo ou importer un reçu'),
        findsNothing,
      );
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('suppression : revient au repli vide', (tester) async {
      await _pump(tester);
      fakePicker.nextPath = photoValide.path;
      await choisirJustificatif(tester);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();

      expect(
        find.text('Prendre une photo ou importer un reçu'),
        findsOneWidget,
      );
    });

    testWidgets(
      'fichier trop volumineux : message clair, pas d\'aperçu',
      (tester) async {
        await _pump(tester);
        fakePicker.nextPath = photoTropGrosse.path;

        await choisirJustificatif(tester);

        expect(find.textContaining('10 Mo'), findsOneWidget);
        expect(
          find.text('Prendre une photo ou importer un reçu'),
          findsOneWidget,
        );
      },
    );
  });

  for (final dark in [false, true]) {
    testWidgets('rendu clair/sombre sans débordement (sombre: $dark)', (
      tester,
    ) async {
      await _pump(tester, dark: dark);
      expect(tester.takeException(), isNull);

      await _remplirEtOuvrirRecap(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Confirmer la dépense'), findsOneWidget);
    });
  }
}
