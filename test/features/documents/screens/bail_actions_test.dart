import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/core/widgets/app_button.dart';
import 'package:hope_gestion_mobile/features/documents/data/baux_repository.dart';
import 'package:hope_gestion_mobile/features/documents/data/baux_results.dart';
import 'package:hope_gestion_mobile/features/documents/models/bail_detail.dart';
import 'package:hope_gestion_mobile/features/documents/screens/bail_actions.dart';
import 'package:hope_gestion_mobile/features/documents/screens/signer_bail_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

/// Tests isolés des feuilles de résiliation/renouvellement et de l'écran de
/// signature (mixin `EnvoiActionBail`), ouverts depuis un hôte minimal qui
/// capture la valeur de fermeture (`IssueActionBail?`). Le câblage avec la
/// fiche (rechargement `getBail` et `listLots`) est couvert par
/// `bail_detail_screen_test.dart`.

const _bail = BailDetail(
  id: 42,
  statut: 'actif',
  referenceBail: 'BAIL-2026-0042',
  loyerMensuel: 185000,
  dateDebut: null,
  dateFin: null,
);

final _bailAvecDates = BailDetail(
  id: 42,
  statut: 'actif',
  referenceBail: 'BAIL-2026-0042',
  loyerMensuel: 185000,
  dateDebut: DateTime(2026, 10, 5),
  dateFin: DateTime(2027, 10, 5),
);

const _messagePermission =
    'Votre compte n\'a pas l\'autorisation de modifier les baux.';

/// Faux serveur des `POST /locations/42/*` uniquement : aucun `GET` attendu
/// depuis les feuilles/l'écran d'action.
class _Serveur {
  /// Statut des `POST`, ou `null` = erreur réseau.
  int? status = 200;

  /// Si renseigné, les `POST` attendent sa complétion avant de répondre.
  Completer<void>? bloquer;
  final actions = <(String, Map<String, dynamic>)>[];
  final autres = <String>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    if (options.method != 'POST') {
      autres.add('${options.method} ${options.path}');
      throw UnimplementedError(options.path);
    }
    actions.add((options.path, Map<String, dynamic>.from(options.data as Map)));
    await bloquer?.future;
    final s = status;
    if (s == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (s == 400) {
      return jsonResponse({
        'errors': [
          {'path': 'motif', 'msg': 'Valeur refusée'},
        ],
      }, 400);
    }
    if (s == 404) return jsonResponse({'message': 'Contrat non trouvé'}, 404);
    if (s == 500) return jsonResponse({'message': 'Erreur interne'}, 500);
    if (s != 200) return jsonResponse({'message': 'Accès refusé'}, s);
    return jsonResponse({'message': 'ok'}, 200);
  }
}

/// Valeur de fermeture capturée par l'hôte ; `fermee` distingue « fermé avec
/// `null` » de « jamais fermé ».
class _Issue {
  bool fermee = false;
  IssueActionBail? valeur;
}

enum _Action { resilier, renouveler, signer }

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Monte un hôte, ouvre l'action [action] et renvoie le serveur et l'issue.
Future<(_Serveur, _Issue)> _ouvrir(
  WidgetTester tester,
  _Action action, {
  BailDetail? bail,
  void Function(_Serveur)? configurer,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final serveur = _Serveur();
  configurer?.call(serveur);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(serveur.repondre);
  BauxRepository.initialize(
    BauxRepository(
      apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
    ),
  );

  final issue = _Issue();
  final cible = bail ?? _bailAvecDates;
  DateTime maintenant() => DateTime(2026, 12, 20);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final IssueActionBail? r = switch (action) {
                  _Action.resilier => await ouvrirResiliationBail(
                    context,
                    cible,
                    maintenant: maintenant,
                  ),
                  _Action.renouveler => await ouvrirRenouvellementBail(
                    context,
                    cible,
                    maintenant: maintenant,
                  ),
                  _Action.signer =>
                    await Navigator.of(context).push<IssueActionBail>(
                      MaterialPageRoute(
                        builder: (_) => SignerBailScreen(bail: cible),
                      ),
                    ),
                };
                issue
                  ..fermee = true
                  ..valeur = r;
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await _settle(tester);
  return (serveur, issue);
}

Finder _appButton(String label) => find.byWidgetPredicate(
  (w) => w is AppButton && w.label == label,
  description: 'AppButton « $label »',
);

/// Callback courant d'un [AppButton] (null = désactivé).
VoidCallback? _onPressed(WidgetTester tester, String label) =>
    tester.widget<AppButton>(_appButton(label)).onPressed;

Future<void> _choisirDateProposee(WidgetTester tester) async {
  await tester.tap(find.text('Choisir une date'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _signer(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const Key('signature-pad')),
    const Offset(120, 40),
  );
  await tester.pump();
}

/// Prépare l'action jusqu'à juste avant « Confirmer ».
Future<void> _preparer(WidgetTester tester, _Action action) async {
  switch (action) {
    case _Action.resilier:
      break;
    case _Action.renouveler:
      await _choisirDateProposee(tester);
    case _Action.signer:
      await _signer(tester);
  }
}

/// Settle supplémentaire pour la signature : export PNG réel (moteur).
Future<void> _attendreEnvoi(WidgetTester tester, _Action action) async {
  await _settle(tester);
  if (action == _Action.signer) await _settle(tester);
}

Type _typeEcran(_Action action) => switch (action) {
  _Action.resilier => ResilierBailSheet,
  _Action.renouveler => RenouvelerBailSheet,
  _Action.signer => SignerBailScreen,
};

String _chemin(_Action action) => switch (action) {
  _Action.resilier => '/locations/42/resilier',
  _Action.renouveler => '/locations/42/renouveler',
  _Action.signer => '/locations/42/sign',
};

/// Ferme sans succès : bouton Annuler (feuilles) ou flèche retour (écran).
Future<void> _fermer(WidgetTester tester, _Action action) async {
  if (action == _Action.signer) {
    await tester.tap(
      find.descendant(
        of: find.byType(SignerBailScreen),
        matching: find.byIcon(LucideIcons.arrow_left),
      ),
    );
  } else {
    await tester.tap(_appButton('Annuler'));
  }
  await _settle(tester);
}

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  group('decrireEchecActionBail', () {
    test('succès : null', () {
      expect(decrireEchecActionBail(const ActionBailSuccess()), isNull);
    });

    test('400 : message serveur préfixé, issue certaine', () {
      final r = decrireEchecActionBail(
        const ActionBailValidationFailed('Motif trop long', {}),
      );
      expect(r?.message, 'Le serveur a refusé ces informations : Motif trop long');
      expect(r?.incertain, isFalse);
    });

    test('403 : message fixe, issue certaine', () {
      final r = decrireEchecActionBail(
        const ActionBailPermissionRefusee('Forbidden'),
      );
      expect(r?.message, _messagePermission);
      expect(r?.incertain, isFalse);
    });

    test('réseau : « peut-être appliquée », issue incertaine', () {
      final r = decrireEchecActionBail(const ActionBailNetworkError('x'));
      expect(r?.message, startsWith('Une erreur réseau est survenue.'));
      expect(r?.message, contains('peut-être été appliquée'));
      expect(r?.incertain, isTrue);
    });

    test('5xx : message serveur + avertissement, issue incertaine', () {
      final r = decrireEchecActionBail(
        const ActionBailFailure('Erreur interne', ApiExceptionType.server),
      );
      expect(r?.message, startsWith('Erreur interne '));
      expect(r?.message, contains('peut-être été appliquée'));
      expect(r?.incertain, isTrue);
    });

    for (final type in [
      ApiExceptionType.notFound,
      ApiExceptionType.unauthorized,
      ApiExceptionType.unknown,
    ]) {
      test('autre échec ($type) : message brut, issue certaine', () {
        final r = decrireEchecActionBail(ActionBailFailure('Brut', type));
        expect(r?.message, 'Brut');
        expect(r?.incertain, isFalse);
      });
    }
  });

  // Variantes d'échec communes aux trois actions : message affiché, pas de
  // fermeture (pas de faux succès), un seul envoi, et valeur de fermeture
  // `incertain` uniquement pour réseau/5xx.
  final echecs = <(String, int?, Matcher, IssueActionBail?)>[
    (
      '400',
      400,
      equals('Le serveur a refusé ces informations : Valeur refusée'),
      null,
    ),
    ('403', 403, equals(_messagePermission), null),
    ('404 (autre)', 404, equals('Contrat non trouvé'), null),
    ('500', 500, contains('peut-être été appliquée'), IssueActionBail.incertain),
    (
      'réseau',
      null,
      allOf(
        startsWith('Une erreur réseau est survenue.'),
        contains('peut-être été appliquée'),
      ),
      IssueActionBail.incertain,
    ),
  ];

  for (final action in _Action.values) {
    group('${action.name} :', () {
      testWidgets('succès : un envoi, fermeture avec succes', (tester) async {
        final (serveur, issue) = await _ouvrir(tester, action);
        await _preparer(tester, action);

        await tester.tap(_appButton('Confirmer'));
        await _attendreEnvoi(tester, action);

        expect(serveur.actions, hasLength(1));
        expect(serveur.actions.single.$1, _chemin(action));
        expect(serveur.autres, isEmpty);
        expect(find.byType(_typeEcran(action)), findsNothing);
        expect(issue.fermee, isTrue);
        expect(issue.valeur, IssueActionBail.succes);
      });

      for (final (nom, status, message, attendue) in echecs) {
        testWidgets('échec $nom : message, écran conservé, '
            'fermeture → $attendue', (tester) async {
          final (serveur, issue) = await _ouvrir(
            tester,
            action,
            configurer: (s) => s.status = status,
          );
          await _preparer(tester, action);

          await tester.tap(_appButton('Confirmer'));
          await _attendreEnvoi(tester, action);

          expect(serveur.actions, hasLength(1));
          expect(find.byType(_typeEcran(action)), findsOneWidget);
          expect(issue.fermee, isFalse); // pas de faux succès
          final erreur = tester.widget<MessageErreurActionBail>(
            find.byType(MessageErreurActionBail),
          );
          expect(erreur.message, message);
          // Bouton réactivé : nouvel essai manuel possible, jamais auto.
          expect(_onPressed(tester, 'Confirmer'), isNotNull);

          await _fermer(tester, action);

          expect(find.byType(_typeEcran(action)), findsNothing);
          expect(issue.fermee, isTrue);
          expect(issue.valeur, attendue);
          expect(serveur.actions, hasLength(1));
        });
      }

      testWidgets('échec incertain puis échec certain : issue reste '
          'incertaine', (tester) async {
        final (serveur, issue) = await _ouvrir(
          tester,
          action,
          configurer: (s) => s.status = null,
        );
        await _preparer(tester, action);

        await tester.tap(_appButton('Confirmer'));
        await _attendreEnvoi(tester, action);
        serveur.status = 403;
        await tester.tap(_appButton('Confirmer'));
        await _attendreEnvoi(tester, action);

        expect(serveur.actions, hasLength(2));
        expect(find.text(_messagePermission), findsOneWidget);
        await _fermer(tester, action);
        expect(issue.valeur, IssueActionBail.incertain);
      });

      testWidgets('verrou anti-double-envoi : second appel, fermeture et '
          'retour système ignorés pendant l\'envoi', (tester) async {
        final (serveur, issue) = await _ouvrir(
          tester,
          action,
          configurer: (s) => s.bloquer = Completer<void>(),
        );
        await _preparer(tester, action);

        // Callbacks capturés AVANT le premier appel : le second appel
        // contourne la désactivation visuelle du bouton et teste le verrou
        // lui-même (`envoiEnCours`).
        final confirmer = _onPressed(tester, 'Confirmer')!;
        final annuler = action == _Action.signer
            ? null
            : _onPressed(tester, 'Annuler')!;
        confirmer();
        confirmer();
        await _attendreEnvoi(tester, action);
        confirmer();
        annuler?.call();
        await tester.binding.handlePopRoute();
        await _settle(tester);

        expect(serveur.actions, hasLength(1));
        expect(find.byType(_typeEcran(action)), findsOneWidget);
        expect(issue.fermee, isFalse);
        expect(_onPressed(tester, 'Confirmer'), isNull);
        expect(
          find.descendant(
            of: find.byType(_typeEcran(action)),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );

        serveur.bloquer!.complete();
        await _attendreEnvoi(tester, action);

        expect(serveur.actions, hasLength(1));
        expect(find.byType(_typeEcran(action)), findsNothing);
        expect(issue.valeur, IssueActionBail.succes);
      });

      testWidgets('annulation sans envoi : fermeture avec null', (
        tester,
      ) async {
        final (serveur, issue) = await _ouvrir(tester, action);

        await _fermer(tester, action);

        expect(serveur.actions, isEmpty);
        expect(issue.fermee, isTrue);
        expect(issue.valeur, isNull);
      });

      // Contrôle positif du retour système utilisé dans le test du verrou :
      // hors envoi, il passe bien par `fermer` et ferme l'écran.
      testWidgets('retour système après échec incertain : fermeture avec '
          'incertain', (tester) async {
        final (_, issue) = await _ouvrir(
          tester,
          action,
          configurer: (s) => s.status = null,
        );
        await _preparer(tester, action);
        await tester.tap(_appButton('Confirmer'));
        await _attendreEnvoi(tester, action);

        await tester.binding.handlePopRoute();
        await _settle(tester);

        expect(find.byType(_typeEcran(action)), findsNothing);
        expect(issue.fermee, isTrue);
        expect(issue.valeur, IssueActionBail.incertain);
      });
    });
  }

  group('résiliation : payload', () {
    testWidgets('motif nettoyé et date du jour envoyés', (tester) async {
      final (serveur, _) = await _ouvrir(tester, _Action.resilier);
      expect(find.text('20/12/2026'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '  Départ  ');
      await tester.tap(_appButton('Confirmer'));
      await _settle(tester);

      expect(serveur.actions, hasLength(1));
      expect(serveur.actions.single.$1, '/locations/42/resilier');
      expect(serveur.actions.single.$2, {
        'motif': 'Départ',
        'date_resiliation': '2026-12-20',
      });
    });
  });

  group('renouvellement : payload', () {
    testWidgets('nouvelle_date_fin toujours envoyée, loyer pré-rempli '
        'inchangé non envoyé', (tester) async {
      final (serveur, _) = await _ouvrir(tester, _Action.renouveler);
      expect(find.text('185000'), findsOneWidget);

      await _choisirDateProposee(tester);
      await tester.tap(_appButton('Confirmer'));
      await _settle(tester);

      expect(serveur.actions.single.$2, {'nouvelle_date_fin': '2028-10-05'});
    });

    testWidgets('loyer ressaisi à l\'identique (espaces) : non envoyé', (
      tester,
    ) async {
      final (serveur, _) = await _ouvrir(tester, _Action.renouveler);

      await _choisirDateProposee(tester);
      await tester.enterText(find.byType(TextField), '185 000');
      await tester.tap(_appButton('Confirmer'));
      await _settle(tester);

      expect(serveur.actions.single.$2, {'nouvelle_date_fin': '2028-10-05'});
    });

    testWidgets('loyer vidé : non envoyé, date envoyée', (tester) async {
      final (serveur, _) = await _ouvrir(tester, _Action.renouveler);

      await _choisirDateProposee(tester);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(_appButton('Confirmer'));
      await _settle(tester);

      expect(serveur.actions.single.$2, {'nouvelle_date_fin': '2028-10-05'});
    });

    testWidgets('loyer modifié (virgule décimale) : envoyé avec la date', (
      tester,
    ) async {
      final (serveur, _) = await _ouvrir(tester, _Action.renouveler);

      await _choisirDateProposee(tester);
      await tester.enterText(find.byType(TextField), '190 000,5');
      await tester.tap(_appButton('Confirmer'));
      await _settle(tester);

      expect(serveur.actions.single.$2, {
        'nouvelle_date_fin': '2028-10-05',
        'nouveau_loyer': 190000.5,
      });
    });

    testWidgets('bail sans dates : date de fin toujours exigée, '
        'proposée un an après aujourd\'hui', (tester) async {
      final (serveur, _) = await _ouvrir(
        tester,
        _Action.renouveler,
        bail: _bail,
      );
      expect(find.textContaining('non renseignée'), findsOneWidget);

      await tester.tap(_appButton('Confirmer'));
      await _settle(tester);
      expect(serveur.actions, isEmpty);
      expect(
        find.text('Choisissez la nouvelle date de fin du bail.'),
        findsOneWidget,
      );

      await _choisirDateProposee(tester);
      await tester.tap(_appButton('Confirmer'));
      await _settle(tester);

      expect(serveur.actions.single.$2, {'nouvelle_date_fin': '2027-12-20'});
    });
  });

  group('signature : écran', () {
    testWidgets('bannière : arrêt des échéances automatiques', (tester) async {
      await _ouvrir(tester, _Action.signer);

      expect(find.text('BAIL-2026-0042'), findsOneWidget);
      expect(
        find.textContaining(
          'Les échéances mensuelles ne seront plus générées '
          'automatiquement pour ce bail.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('pad vide : Confirmer et Effacer désactivés, aucun envoi', (
      tester,
    ) async {
      final (serveur, _) = await _ouvrir(tester, _Action.signer);

      expect(_onPressed(tester, 'Confirmer'), isNull);
      expect(_onPressed(tester, 'Effacer'), isNull);
      await tester.tap(_appButton('Confirmer'));
      await _settle(tester);
      expect(serveur.actions, isEmpty);
    });

    testWidgets('PNG réel en base64, préfixe ajouté par le repository', (
      tester,
    ) async {
      final (serveur, _) = await _ouvrir(tester, _Action.signer);

      await _signer(tester);
      await tester.tap(_appButton('Confirmer'));
      await _attendreEnvoi(tester, _Action.signer);

      final data = serveur.actions.single.$2;
      expect(data.keys, ['signatureImage']);
      final image = data['signatureImage'] as String;
      expect(image, startsWith(BauxRepository.prefixeSignaturePng));
      final b64 = image.substring(BauxRepository.prefixeSignaturePng.length);
      // Préfixe unique (le repository l'ajoute, l'écran non).
      expect(b64, isNot(startsWith('data:')));
      final png = base64Decode(b64);
      // Signature PNG puis premier chunk IHDR.
      expect(png.take(8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      expect(ascii.decode(png.sublist(12, 16)), 'IHDR');
      final largeur = ByteData.sublistView(png, 16, 20).getUint32(0);
      final hauteur = ByteData.sublistView(png, 20, 24).getUint32(0);
      expect(largeur, greaterThan(0));
      expect(hauteur, greaterThan(0));
    });

    testWidgets('échec puis Effacer : message d\'erreur retiré', (
      tester,
    ) async {
      await _ouvrir(
        tester,
        _Action.signer,
        configurer: (s) => s.status = 403,
      );

      await _signer(tester);
      await tester.tap(_appButton('Confirmer'));
      await _attendreEnvoi(tester, _Action.signer);
      expect(find.text(_messagePermission), findsOneWidget);

      await tester.tap(_appButton('Effacer'));
      await tester.pump();

      expect(find.byType(MessageErreurActionBail), findsNothing);
      expect(find.text('Signez ici'), findsOneWidget);
    });
  });
}
