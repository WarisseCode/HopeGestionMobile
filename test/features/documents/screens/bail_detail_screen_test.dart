import 'dart:async';
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
import 'package:hope_gestion_mobile/features/biens/data/biens_repository.dart';
import 'package:hope_gestion_mobile/features/documents/data/baux_repository.dart';
import 'package:hope_gestion_mobile/features/documents/screens/bail_actions.dart';
import 'package:hope_gestion_mobile/features/documents/screens/bail_detail_screen.dart';
import 'package:hope_gestion_mobile/features/documents/screens/signer_bail_screen.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

class _Serveur {
  /// Statut de `GET /locations/42`, ou `null` = erreur réseau.
  int? status = 200;
  String statut = 'actif';
  String dateFin = '2027-10-05';
  List<Map<String, dynamic>> echeancier = [];
  final requetes = <String>[];

  /// Statut des `POST /locations/42/*`, ou `null` = erreur réseau.
  int? statusAction = 200;
  String messageValidation = 'Motif trop long';

  /// Si renseigné, les `POST` attendent sa complétion avant de répondre.
  Completer<void>? bloquerActions;
  final actions = <(String, Map<String, dynamic>)>[];

  Future<ResponseBody> repondre(RequestOptions options) async {
    requetes.add(options.path);
    if (options.method == 'POST') return _action(options);
    if (options.path == '/biens/lots') {
      return jsonResponse({'lots': <dynamic>[]}, 200);
    }
    if (options.path != '/locations/42') {
      throw UnimplementedError(options.path);
    }
    final s = status;
    if (s == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (s == 404) {
      return jsonResponse({
        'message': 'Contrat non trouvé ou accès refusé',
      }, 404);
    }
    if (s != 200) return jsonResponse({'message': 'Accès refusé'}, s);
    return jsonResponse({
      'location': {
        'id': 42,
        'reference_bail': 'BAIL-2026-0042',
        'statut': statut,
        'loyer_mensuel': '185000.00',
        'caution': '370000.00',
        'avance': 2,
        'charges_mensuelles': '10000.00',
        'jour_echeance': 5,
        'date_debut': '2026-10-05',
        'date_fin': dateFin,
        'locataire_nom': 'Diop',
        'locataire_prenoms': 'Yacine',
        'locataire_telephone': '+22990000001',
        'locataire_email': 'yacine@example.com',
        'ref_lot': 'A1',
        'lot_type': 'appartement',
        'immeuble_nom': 'Résidence Palmiers',
        'immeuble_adresse': 'Rue 12, Cotonou',
        'proprietaire_nom': 'Mamadou Camara',
      },
      'echeancier': echeancier,
    }, 200);
  }

  Future<ResponseBody> _action(RequestOptions options) async {
    actions.add((options.path, Map<String, dynamic>.from(options.data as Map)));
    await bloquerActions?.future;
    final s = statusAction;
    if (s == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (s == 400) {
      return jsonResponse({
        'errors': [
          {'path': 'motif', 'msg': messageValidation},
        ],
      }, 400);
    }
    if (s != 200) return jsonResponse({'message': 'Accès refusé'}, s);
    switch (options.path) {
      case '/locations/42/resilier':
        statut = 'resilie';
        return jsonResponse({'message': 'Bail résilié avec succès'}, 200);
      case '/locations/42/renouveler':
        statut = 'actif';
        dateFin = (options.data as Map)['nouvelle_date_fin'] as String;
        return jsonResponse({
          'message': 'ok',
          'location': {'id': 42},
        }, 200);
      case '/locations/42/sign':
        statut = 'signe';
        return jsonResponse({
          'message': 'Contrat signé',
          'signatureUrl': '/uploads/signatures/42.png',
        }, 200);
    }
    throw UnimplementedError(options.path);
  }

  int get appels => requetes.where((p) => p == '/locations/42').length;
  int get appelsLots => requetes.where((p) => p == '/biens/lots').length;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  // Deux paliers : laisse aussi se terminer l'animation de fermeture d'une
  // feuille/d'un écran d'action déclenchée pendant les boucles ci-dessus.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<_Serveur> _pump(
  WidgetTester tester, {
  void Function(_Serveur)? configurer,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final serveur = _Serveur();
  configurer?.call(serveur);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(serveur.repondre);
  final apiClient = ApiClient(tokenStorage: TokenStorage(), dio: dio);
  BauxRepository.initialize(BauxRepository(apiClient: apiClient));
  BiensRepository.initialize(BiensRepository(apiClient: apiClient));

  await tester.pumpWidget(
    MaterialApp(
      home: BailDetailScreen(
        bailId: 42,
        maintenant: () => DateTime(2026, 12, 20),
      ),
    ),
  );
  await _settle(tester);
  return serveur;
}

Finder _bouton(String label) => find.widgetWithText(InkWell, label);

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  testWidgets('succès : en-tête et toutes les sections', (tester) async {
    await _pump(tester);

    expect(find.text('BAIL-2026-0042'), findsOneWidget);
    expect(find.text('Actif'), findsOneWidget);

    expect(find.text('LOCATAIRE'), findsOneWidget);
    expect(find.text('Diop Yacine'), findsOneWidget);
    expect(find.text('+22990000001'), findsOneWidget);
    expect(find.text('yacine@example.com'), findsOneWidget);

    expect(find.text('LOGEMENT'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('Appartement'), findsOneWidget);
    expect(find.text('Résidence Palmiers'), findsOneWidget);
    expect(find.text('Rue 12, Cotonou'), findsOneWidget);

    expect(find.text('PROPRIÉTAIRE'), findsOneWidget);
    expect(find.text('Mamadou Camara'), findsOneWidget);

    expect(find.text('CONDITIONS FINANCIÈRES'), findsOneWidget);
    expect(find.text('185 000 F'), findsOneWidget);
    expect(find.text('10 000 F'), findsOneWidget);
    expect(find.text('370 000 F'), findsOneWidget);
    // Avance en mois, jamais convertie en FCFA.
    expect(find.text('2 mois'), findsOneWidget);
    expect(find.textContaining('FCFA'), findsNothing);
    expect(find.text('Le 5 du mois'), findsOneWidget);
    expect(find.text('05/10/2026'), findsOneWidget);
    expect(find.text('05/10/2027'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('échéancier vide : message informatif, pas une erreur', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('ÉCHÉANCIER (0)'), findsOneWidget);
    expect(
      find.text(
        'Aucune échéance pour le moment : c\'est normal pour un bail '
        'récent, les échéances sont générées au fil des mois.',
      ),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('échéancier : badges d\'état cohérents avec Finances', (
    tester,
  ) async {
    await _pump(
      tester,
      configurer: (s) => s.echeancier = [
        {
          'id': 1,
          'total_amount': '185000.00',
          'amount_paid': '185000.00',
          'due_date': '2026-11-05',
          'status': 'paid',
        },
        {
          'id': 2,
          'total_amount': '185000.00',
          'amount_paid': '0.00',
          'due_date': '2026-12-05',
        },
        {
          'id': 3,
          'total_amount': '185000.00',
          'amount_paid': '50000.00',
          'due_date': '2027-01-05',
          'status': 'partial',
        },
        {
          'id': 4,
          'total_amount': '185000.00',
          'amount_paid': '0.00',
          'due_date': '2027-02-05',
        },
      ],
    );

    expect(find.text('ÉCHÉANCIER (4)'), findsOneWidget);
    expect(find.text('Payée'), findsOneWidget);
    expect(find.text('En retard'), findsOneWidget);
    expect(find.text('Acompte'), findsOneWidget);
    expect(find.text('À payer'), findsOneWidget);
    expect(find.text('Versé 50 000 F · Reste 135 000 F'), findsOneWidget);
    expect(find.textContaining('Aucune échéance'), findsNothing);
  });

  testWidgets('404 : message clair, pas de Réessayer', (tester) async {
    await _pump(tester, configurer: (s) => s.status = 404);

    expect(find.text('Bail introuvable'), findsOneWidget);
    expect(find.textContaining('n\'existe pas'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('403 : accès refusé, pas de Réessayer', (tester) async {
    await _pump(tester, configurer: (s) => s.status = 403);

    expect(find.text('Accès refusé'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('réseau : Réessayer qui recharge', (tester) async {
    final serveur = await _pump(tester, configurer: (s) => s.status = null);

    expect(find.text('Connexion impossible'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    serveur.status = 200;
    await tester.tap(find.text('Réessayer'));
    await _settle(tester);

    expect(find.text('BAIL-2026-0042'), findsOneWidget);
    expect(serveur.appels, 2);
  });

  testWidgets('tirer pour actualiser : nouvel appel', (tester) async {
    final serveur = await _pump(tester);

    // Même approche que `locataires_screen_test` : le geste lui-même relève
    // du framework, seul le câblage `onRefresh` est testé.
    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await tester.runAsync(indicator.onRefresh);
    await _settle(tester);

    expect(serveur.appels, 2);
    expect(find.text('BAIL-2026-0042'), findsOneWidget);
  });

  testWidgets('actualisation en échec réseau : fiche conservée + SnackBar', (
    tester,
  ) async {
    final serveur = await _pump(tester);

    serveur.status = null;
    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await tester.runAsync(indicator.onRefresh);
    await _settle(tester);

    expect(find.text('BAIL-2026-0042'), findsOneWidget);
    expect(find.textContaining('Actualisation impossible'), findsOneWidget);
    expect(find.text('Connexion impossible'), findsNothing);
  });

  group('actions : visibilité selon le statut', () {
    testWidgets('actif : Signer, Renouveler, Résilier', (tester) async {
      await _pump(tester);

      expect(find.text('ACTIONS'), findsOneWidget);
      expect(_bouton('Signer'), findsOneWidget);
      expect(_bouton('Renouveler'), findsOneWidget);
      expect(_bouton('Résilier'), findsOneWidget);
      expect(find.text('Bail résilié'), findsNothing);
    });

    testWidgets('signe : Renouveler et Résilier, pas de re-signature', (
      tester,
    ) async {
      await _pump(tester, configurer: (s) => s.statut = 'signe');

      expect(_bouton('Signer'), findsNothing);
      expect(_bouton('Renouveler'), findsOneWidget);
      expect(_bouton('Résilier'), findsOneWidget);
    });

    testWidgets('resilie : aucune action, mention « Bail résilié »', (
      tester,
    ) async {
      await _pump(tester, configurer: (s) => s.statut = 'resilie');

      expect(find.text('ACTIONS'), findsNothing);
      expect(_bouton('Signer'), findsNothing);
      expect(_bouton('Renouveler'), findsNothing);
      expect(_bouton('Résilier'), findsNothing);
      expect(find.text('Bail résilié'), findsOneWidget);
    });

    testWidgets('autre statut (termine) : aucune action, aucune mention', (
      tester,
    ) async {
      await _pump(tester, configurer: (s) => s.statut = 'termine');

      expect(find.text('ACTIONS'), findsNothing);
      expect(_bouton('Résilier'), findsNothing);
      expect(find.text('Bail résilié'), findsNothing);
    });
  });

  group('résiliation', () {
    Future<_Serveur> ouvrir(
      WidgetTester tester, {
      void Function(_Serveur)? configurer,
    }) async {
      final serveur = await _pump(tester, configurer: configurer);
      await tester.tap(_bouton('Résilier'));
      await _settle(tester);
      expect(find.byType(ResilierBailSheet), findsOneWidget);
      return serveur;
    }

    testWidgets('succès : payload, fermeture, rechargements, confirmation', (
      tester,
    ) async {
      final serveur = await ouvrir(tester);
      // Date du jour pré-remplie (horloge injectée).
      expect(find.text('20/12/2026'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Départ du locataire');
      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(serveur.actions, hasLength(1));
      expect(serveur.actions.single.$1, '/locations/42/resilier');
      expect(serveur.actions.single.$2, {
        'motif': 'Départ du locataire',
        'date_resiliation': '2026-12-20',
      });
      expect(find.byType(ResilierBailSheet), findsNothing);
      expect(serveur.appels, 2); // fiche rechargée
      expect(serveur.appelsLots, 1); // le lot redevient disponible
      expect(find.text('Bail résilié.'), findsOneWidget); // SnackBar
      expect(find.text('Résilié'), findsOneWidget); // badge rechargé
      expect(find.text('Bail résilié'), findsOneWidget);
      expect(_bouton('Résilier'), findsNothing);
    });

    testWidgets('motif vide : champ omis, date toujours envoyée', (
      tester,
    ) async {
      final serveur = await ouvrir(tester);

      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(serveur.actions.single.$2, {'date_resiliation': '2026-12-20'});
    });

    testWidgets('403 : message clair, feuille ouverte, aucun rechargement', (
      tester,
    ) async {
      final serveur = await ouvrir(
        tester,
        configurer: (s) => s.statusAction = 403,
      );

      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(find.byType(ResilierBailSheet), findsOneWidget);
      expect(
        find.text(
          'Votre compte n\'a pas l\'autorisation de modifier les baux.',
        ),
        findsOneWidget,
      );

      await tester.tap(_bouton('Annuler'));
      await _settle(tester);

      expect(find.byType(ResilierBailSheet), findsNothing);
      expect(serveur.appels, 1);
      expect(serveur.appelsLots, 0);
    });

    testWidgets('400 : message du serveur affiché', (tester) async {
      await ouvrir(tester, configurer: (s) => s.statusAction = 400);

      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(
        find.text('Le serveur a refusé ces informations : Motif trop long'),
        findsOneWidget,
      );
    });

    testWidgets(
      'réseau : avertissement « peut-être appliqué », pas de relance, '
      'rechargement à la fermeture',
      (tester) async {
        final serveur = await ouvrir(
          tester,
          configurer: (s) => s.statusAction = null,
        );

        await tester.tap(_bouton('Confirmer'));
        await _settle(tester);

        expect(serveur.actions, hasLength(1));
        expect(find.byType(ResilierBailSheet), findsOneWidget);
        expect(find.textContaining('peut-être été appliquée'), findsOneWidget);
        expect(serveur.appels, 1);

        await tester.tap(_bouton('Annuler'));
        await _settle(tester);

        // Issue incertaine : fiche et lots rechargés, pas de confirmation.
        expect(serveur.actions, hasLength(1));
        expect(serveur.appels, 2);
        expect(serveur.appelsLots, 1);
        expect(find.text('Bail résilié.'), findsNothing);
      },
    );

    testWidgets('verrou anti-double-envoi pendant l\'appel', (tester) async {
      final serveur = await ouvrir(
        tester,
        configurer: (s) => s.bloquerActions = Completer<void>(),
      );

      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);
      await tester.tap(_bouton('Confirmer'), warnIfMissed: false);
      await tester.tap(_bouton('Annuler'), warnIfMissed: false);
      await _settle(tester);

      expect(serveur.actions, hasLength(1));
      expect(find.byType(ResilierBailSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ResilierBailSheet),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      serveur.bloquerActions!.complete();
      await _settle(tester);

      expect(serveur.actions, hasLength(1));
      expect(find.byType(ResilierBailSheet), findsNothing);
      expect(find.text('Bail résilié.'), findsOneWidget);
    });
  });

  group('renouvellement', () {
    Future<_Serveur> ouvrir(
      WidgetTester tester, {
      void Function(_Serveur)? configurer,
    }) async {
      final serveur = await _pump(tester, configurer: configurer);
      await tester.tap(_bouton('Renouveler'));
      await _settle(tester);
      expect(find.byType(RenouvelerBailSheet), findsOneWidget);
      return serveur;
    }

    Future<void> choisirDateProposee(WidgetTester tester) async {
      await tester.tap(find.text('Choisir une date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    testWidgets('date de fin obligatoire : aucun envoi sans date', (
      tester,
    ) async {
      final serveur = await ouvrir(tester);

      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(
        find.text('Choisissez la nouvelle date de fin du bail.'),
        findsOneWidget,
      );
      expect(serveur.actions, isEmpty);
    });

    testWidgets('loyer pré-rempli inchangé : seule nouvelle_date_fin envoyée, '
        'fiche rechargée', (tester) async {
      final serveur = await ouvrir(tester);
      expect(find.text('185000'), findsOneWidget);

      await choisirDateProposee(tester);
      // Proposition : un an après la fin actuelle (05/10/2027).
      expect(find.text('05/10/2028'), findsOneWidget);

      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(serveur.actions, hasLength(1));
      expect(serveur.actions.single.$1, '/locations/42/renouveler');
      // `nouvelle_date_fin` toujours envoyée (bug NULL serveur).
      expect(serveur.actions.single.$2, {'nouvelle_date_fin': '2028-10-05'});
      expect(find.byType(RenouvelerBailSheet), findsNothing);
      expect(serveur.appels, 2);
      expect(serveur.appelsLots, 0);
      expect(find.text('Bail renouvelé.'), findsOneWidget);
      expect(find.text('05/10/2028'), findsOneWidget); // fin rechargée
    });

    testWidgets('nouveau loyer saisi : envoyé avec la date', (tester) async {
      final serveur = await ouvrir(tester);

      await choisirDateProposee(tester);
      await tester.enterText(find.byType(TextField), '200 000');
      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(serveur.actions.single.$2, {
        'nouvelle_date_fin': '2028-10-05',
        'nouveau_loyer': 200000.0,
      });
    });

    testWidgets('loyer invalide : erreur de champ, aucun envoi', (
      tester,
    ) async {
      final serveur = await ouvrir(tester);

      await choisirDateProposee(tester);
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(find.textContaining('loyer supérieur à 0'), findsOneWidget);
      expect(serveur.actions, isEmpty);
    });

    testWidgets('403 : message clair, feuille ouverte', (tester) async {
      await ouvrir(tester, configurer: (s) => s.statusAction = 403);

      await choisirDateProposee(tester);
      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(find.byType(RenouvelerBailSheet), findsOneWidget);
      expect(
        find.text(
          'Votre compte n\'a pas l\'autorisation de modifier les baux.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('500 : avertissement « peut-être appliqué »', (tester) async {
      final serveur = await ouvrir(
        tester,
        configurer: (s) => s.statusAction = 500,
      );

      await choisirDateProposee(tester);
      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(find.textContaining('peut-être été appliquée'), findsOneWidget);
      expect(serveur.actions, hasLength(1));
    });
  });

  group('signature', () {
    Future<_Serveur> ouvrir(
      WidgetTester tester, {
      void Function(_Serveur)? configurer,
    }) async {
      final serveur = await _pump(tester, configurer: configurer);
      await tester.tap(_bouton('Signer'));
      await _settle(tester);
      expect(find.byType(SignerBailScreen), findsOneWidget);
      return serveur;
    }

    Future<void> signer(WidgetTester tester) async {
      await tester.drag(
        find.byKey(const Key('signature-pad')),
        const Offset(120, 40),
      );
      await tester.pump();
    }

    testWidgets('pad vide : Confirmer inactif ; Effacer vide le pad', (
      tester,
    ) async {
      final serveur = await ouvrir(tester);
      expect(find.text('Signez ici'), findsOneWidget);

      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);
      expect(serveur.actions, isEmpty);

      await signer(tester);
      expect(find.text('Signez ici'), findsNothing);

      await tester.tap(_bouton('Effacer'));
      await tester.pump();
      expect(find.text('Signez ici'), findsOneWidget);

      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);
      expect(serveur.actions, isEmpty);
    });

    testWidgets(
      'succès : PNG base64 préfixé envoyé, retour à la fiche rechargée',
      (tester) async {
        final serveur = await ouvrir(tester);

        await signer(tester);
        await tester.tap(_bouton('Confirmer'));
        // Export PNG réel (moteur) puis envoi, fermeture et rechargement :
        // plus d'allers-retours asynchrones que les autres flux.
        await _settle(tester);
        await _settle(tester);

        expect(serveur.actions, hasLength(1));
        final (path, data) = serveur.actions.single;
        expect(path, '/locations/42/sign');
        final image = data['signatureImage'] as String;
        expect(image, startsWith('data:image/png;base64,'));
        final png = base64Decode(
          image.substring('data:image/png;base64,'.length),
        );
        // Signature PNG : 89 50 4E 47 0D 0A 1A 0A.
        expect(png.take(8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

        expect(find.byType(SignerBailScreen), findsNothing);
        expect(serveur.appels, 2);
        expect(serveur.appelsLots, 0);
        expect(find.text('Bail signé.'), findsOneWidget);
        expect(find.text('Signé'), findsOneWidget); // badge rechargé
        expect(_bouton('Signer'), findsNothing); // plus de re-signature
      },
    );

    testWidgets('403 : message clair, écran conservé', (tester) async {
      final serveur = await ouvrir(
        tester,
        configurer: (s) => s.statusAction = 403,
      );

      await signer(tester);
      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(find.byType(SignerBailScreen), findsOneWidget);
      expect(
        find.text(
          'Votre compte n\'a pas l\'autorisation de modifier les baux.',
        ),
        findsOneWidget,
      );
      expect(serveur.appels, 1);
    });

    testWidgets('réseau : « peut-être appliqué », rechargement au retour', (
      tester,
    ) async {
      final serveur = await ouvrir(
        tester,
        configurer: (s) => s.statusAction = null,
      );

      await signer(tester);
      await tester.tap(_bouton('Confirmer'));
      await _settle(tester);

      expect(find.textContaining('peut-être été appliquée'), findsOneWidget);
      expect(serveur.actions, hasLength(1));

      await tester.tap(
        find.descendant(
          of: find.byType(SignerBailScreen),
          matching: find.byIcon(LucideIcons.arrow_left),
        ),
      );
      await _settle(tester);

      expect(find.byType(SignerBailScreen), findsNothing);
      expect(serveur.appels, 2);
      expect(find.text('Bail signé.'), findsNothing);
    });
  });
}
