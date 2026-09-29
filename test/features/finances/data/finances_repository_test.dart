import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/finances/data/finances_repository.dart';
import 'package:hope_gestion_mobile/features/finances/data/finances_results.dart';

import '../../../support/fake_http_adapter.dart';

/// `jsonResponse` n'accepte qu'un objet : `/expenses` et
/// `/expenses/categories` renvoient un tableau nu.
ResponseBody _listResponse(List<dynamic> body, int statusCode) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// Forme réelle d'une ligne de `GET /api/finances` (`SELECT_PAYMENTS_FIELDS`
/// + jointures) : NUMERIC en chaîne, DATE en instant ISO. Instants à midi
/// UTC : même jour calendaire quel que soit le fuseau de la machine de test
/// (le cas minuit est couvert par `finance_parsing_test.dart`).
Map<String, dynamic> _paymentJson({
  int id = 1,
  String amount = '185000.00',
  String paymentDate = '2026-09-15T12:00:00.000Z',
}) => {
  'id': id,
  'lease_id': 8,
  'schedule_id': null,
  'amount': amount,
  'payment_date': paymentDate,
  'payment_method': 'especes',
  'reference': 'RECU-0926',
  'type': 'loyer',
  'statut': 'valide',
  'description': null,
  'created_at': '2026-09-15T10:12:00.000Z',
  'owner_id': 3,
  'reference_bail': 'BAIL-2026-008',
  'loyer_mensuel': '185000.00',
  'locataire_nom': 'DIOP',
  'locataire_prenoms': 'Yacine',
  'proprietaire_nom': 'CAMARA',
};

/// Forme réelle d'une ligne de `GET /api/expenses` (`e.*` + jointures).
Map<String, dynamic> _expenseJson({int id = 4}) => {
  'id': id,
  'building_id': 1,
  'lot_id': null,
  'owner_id': 3,
  'category': 'Travaux / Entretien',
  'description': 'Réparation plomberie',
  'amount': '45000.00',
  'date_expense': '2026-09-10T12:00:00.000Z',
  'supplier_name': 'ETS Plomberie',
  'status': 'paid',
  'proof_url': '/uploads/expenses/123-abc.jpg',
  'created_at': '2026-09-10T09:00:00.000Z',
  'updated_at': '2026-09-10T09:00:00.000Z',
  'building_name': 'Résidence Palmiers',
  'ref_lot': null,
  'category_label': 'Travaux / Entretien',
};

FinancesRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(responder);
  return FinancesRepository(
    apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
  );
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  group('listPaiements (GET /finances)', () {
    test('succès : parse la réponse réelle et transmet la période', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse({
          'payments': [_paymentJson(), _paymentJson(id: 2, amount: '50000')],
        }, 200);
      });

      final result = await repo.listPaiements(
        debut: DateTime(2026, 9, 1),
        fin: DateTime(2026, 9, 30),
      );

      expect(result, isA<PaiementsListSuccess>());
      expect(seen!.path, '/finances');
      expect(seen!.queryParameters, {
        'start_date': '2026-09-01',
        'end_date': '2026-09-30',
      });
      expect(repo.paiements, hasLength(2));
      final p = repo.paiements.first;
      expect(p.montant, 185000);
      expect(p.date, DateTime(2026, 9, 15));
      expect(p.modePaiement, 'especes');
      expect(p.locataireNomComplet, 'Yacine DIOP');
      expect(p.estValide, isTrue);
      expect(p.scheduleId, isNull);
    });

    test('sans période : aucun paramètre de requête', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse({'payments': <dynamic>[]}, 200);
      });

      await repo.listPaiements();

      expect(seen!.queryParameters, isEmpty);
    });

    test('réponse sans "payments" → PaiementsListFailure', () async {
      final repo = _repo((options) async => jsonResponse({'data': []}, 200));

      final result = await repo.listPaiements();

      expect(result, isA<PaiementsListFailure>());
      expect(
        (result as PaiementsListFailure).type,
        ApiExceptionType.unknown,
      );
    });

    test('ligne malformée (sans amount) → PaiementsListFailure', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'payments': [
            {'id': 1, 'payment_date': '2026-09-15'},
          ],
        }, 200),
      );

      expect(await repo.listPaiements(), isA<PaiementsListFailure>());
    });

    test('erreur serveur (500) → PaiementsListFailure', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Erreur serveur'}, 500),
      );

      final result = await repo.listPaiements();

      expect(result, isA<PaiementsListFailure>());
      expect((result as PaiementsListFailure).message, 'Erreur serveur');
    });
  });

  group('listDepenses (GET /expenses)', () {
    test('succès : tableau nu, période et immeuble transmis', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return _listResponse([_expenseJson()], 200);
      });

      final result = await repo.listDepenses(
        debut: DateTime(2026, 9, 1),
        fin: DateTime(2026, 9, 30),
        buildingId: 1,
      );

      expect(result, isA<DepensesListSuccess>());
      expect(seen!.path, '/expenses');
      expect(seen!.queryParameters, {
        'start_date': '2026-09-01',
        'end_date': '2026-09-30',
        'building_id': 1,
      });
      final d = repo.depenses.single;
      expect(d.montant, 45000);
      expect(d.date, DateTime(2026, 9, 10));
      expect(d.categorie, 'Travaux / Entretien');
      expect(d.intitule, 'Réparation plomberie');
      expect(d.immeubleNom, 'Résidence Palmiers');
      expect(d.justificatifUrl, '/uploads/expenses/123-abc.jpg');
    });

    test('description vide (web) → intitulé = catégorie', () async {
      final repo = _repo(
        (options) async =>
            _listResponse([_expenseJson()..['description'] = ''], 200),
      );

      await repo.listDepenses();

      expect(repo.depenses.single.intitule, 'Travaux / Entretien');
    });

    test('403 → DepensesListFailure', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Accès refusé'}, 403),
      );

      final result = await repo.listDepenses();

      expect(result, isA<DepensesListFailure>());
      expect((result as DepensesListFailure).type, ApiExceptionType.forbidden);
    });
  });

  group('listCategoriesDepense (GET /expenses/categories)', () {
    test('succès', () async {
      final repo = _repo(
        (options) async => _listResponse([
          {
            'id': 1,
            'name': 'Assurance PNO',
            'is_deductible': true,
            'description': null,
          },
          {'id': 2, 'name': 'Travaux / Entretien', 'is_deductible': true},
        ], 200),
      );

      final result = await repo.listCategoriesDepense();

      expect(result, isA<CategoriesDepenseSuccess>());
      expect(repo.categories.map((c) => c.nom), [
        'Assurance PNO',
        'Travaux / Entretien',
      ]);
    });
  });

  group('getStats (GET /finances/stats)', () {
    test('succès : mois/année transmis, montants parsés', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse({
          'encashed_month': 2450000,
          'expenses_month': 890000,
          'net_balance': 1560000,
          'pending_total': 320000,
        }, 200);
      });

      final result = await repo.getStats(mois: 9, annee: 2026);

      expect(seen!.path, '/finances/stats');
      expect(seen!.queryParameters, {'month': 9, 'year': 2026});
      final stats = (result as FinanceStatsSuccess).stats;
      expect(stats.encaisse, 2450000);
      expect(stats.depenses, 890000);
      expect(stats.soldeNet, 1560000);
      expect(stats.resteAEncaisser, 320000);
    });

    test('compte sans propriétaire : réponse à zéro', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'encashed_month': 0,
          'expenses_month': 0,
          'net_balance': 0,
          'pending_total': 0,
        }, 200),
      );

      final stats = (await repo.getStats() as FinanceStatsSuccess).stats;

      expect(stats.soldeNet, 0);
    });
  });

  group('listEcheances (GET /locations/:id/echeancier)', () {
    test('succès : parse les lignes brutes de payment_schedules', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse({
          'echeancier': [
            {
              'id': 12,
              'lease_id': 8,
              'total_amount': '185000.00',
              'amount_paid': '0.00',
              'due_date': '2026-09-05T12:00:00.000Z',
              'status': 'pending',
              'statut': 'en_attente',
              'numero_echeance': null,
              'description': 'Loyer 9/2026',
            },
          ],
        }, 200);
      });

      final result = await repo.listEcheances(8);

      expect(seen!.path, '/locations/8/echeancier');
      final items = (result as EcheancesListSuccess).items;
      expect(items, hasLength(1));
      expect(items.single.id, 12);
      expect(items.single.total, 185000);
    });

    test('réponse sans champ "echeancier" → échec', () async {
      final repo = _repo((options) async => jsonResponse({}, 200));

      final result = await repo.listEcheances(8);

      expect(result, isA<EcheancesListFailure>());
    });

    test('erreur réseau → EcheancesListFailure', () async {
      final repo = _repo(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repo.listEcheances(8) as EcheancesListFailure;

      expect(result.type, ApiExceptionType.network);
    });
  });

  group('payerEcheance (PUT /finances/schedules/:id/pay)', () {
    test('envoie exactement montant, mode_paiement, date_paiement, reference', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse({
          'message': 'Acompte enregistré',
          'soldee': false,
          'reste_du': 135000,
          'receiptUrl': null,
        }, 200);
      });

      await repo.payerEcheance(
        echeanceId: 12,
        montant: 50000,
        modePaiement: 'mobile_money',
        datePaiement: '2026-09-15',
        reference: 'MM-123',
      );

      expect(seen!.path, '/finances/schedules/12/pay');
      expect(seen!.method, 'PUT');
      expect(seen!.data, {
        'montant': 50000.0,
        'mode_paiement': 'mobile_money',
        'date_paiement': '2026-09-15',
        'reference': 'MM-123',
      });
    });

    test('montant et référence omis quand null (le serveur encaisse le reste dû)', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse({
          'message': 'Échéance marquée comme payée',
          'soldee': true,
          'reste_du': 0,
          'receiptUrl': '/uploads/receipts/q.pdf',
        }, 200);
      });

      await repo.payerEcheance(
        echeanceId: 12,
        modePaiement: 'especes',
        datePaiement: '2026-09-15',
      );

      expect(seen!.data, {
        'mode_paiement': 'especes',
        'date_paiement': '2026-09-15',
      });
    });

    test('succès au solde : soldee, reste_du et receiptUrl transmis', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'message': 'Échéance marquée comme payée',
          'soldee': true,
          'reste_du': 0,
          'receiptUrl': '/uploads/receipts/q.pdf',
        }, 200),
      );

      final result = await repo.payerEcheance(
        echeanceId: 12,
        modePaiement: 'especes',
        datePaiement: '2026-09-15',
      ) as PayerEcheanceSuccess;

      expect(result.message, 'Échéance marquée comme payée');
      expect(result.soldee, isTrue);
      expect(result.resteDu, 0);
      expect(result.receiptUrl, '/uploads/receipts/q.pdf');
    });

    test('succès en acompte : receiptUrl absent', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'message': 'Acompte enregistré',
          'soldee': false,
          'reste_du': 135000,
        }, 200),
      );

      final result = await repo.payerEcheance(
        echeanceId: 12,
        montant: 50000,
        modePaiement: 'especes',
        datePaiement: '2026-09-15',
      ) as PayerEcheanceSuccess;

      expect(result.soldee, isFalse);
      expect(result.resteDu, 135000);
      expect(result.receiptUrl, isNull);
    });

    test('400 (montant au-delà du reste dû) → PayerEcheanceValidationFailed', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Montant invalide'}, 400),
      );

      final result = await repo.payerEcheance(
        echeanceId: 12,
        montant: 999999,
        modePaiement: 'especes',
        datePaiement: '2026-09-15',
      );

      expect(result, isA<PayerEcheanceValidationFailed>());
      expect((result as PayerEcheanceValidationFailed).message, 'Montant invalide');
    });

    test('409 (déjà soldée) → PayerEcheanceDejaSoldee', () async {
      final repo = _repo(
        (options) async =>
            jsonResponse({'message': 'Échéance déjà soldée'}, 409),
      );

      final result = await repo.payerEcheance(
        echeanceId: 12,
        modePaiement: 'especes',
        datePaiement: '2026-09-15',
      );

      expect(result, isA<PayerEcheanceDejaSoldee>());
      expect((result as PayerEcheanceDejaSoldee).message, 'Échéance déjà soldée');
    });

    test('erreur réseau → PayerEcheanceFailure(network)', () async {
      final repo = _repo(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repo.payerEcheance(
        echeanceId: 12,
        modePaiement: 'especes',
        datePaiement: '2026-09-15',
      );

      expect(result, isA<PayerEcheanceFailure>());
      expect((result as PayerEcheanceFailure).type, ApiExceptionType.network);
    });

    test('délai dépassé → PayerEcheanceFailure(timeout)', () async {
      final repo = _repo(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      );

      final result = await repo.payerEcheance(
        echeanceId: 12,
        modePaiement: 'especes',
        datePaiement: '2026-09-15',
      );

      expect(result, isA<PayerEcheanceFailure>());
      expect((result as PayerEcheanceFailure).type, ApiExceptionType.timeout);
    });
  });

  group('creerDepense (POST /expenses)', () {
    late File tempFile;

    setUpAll(() async {
      tempFile = File(
        '${Directory.systemTemp.path}/creer_depense_repository_test.jpg',
      );
      await tempFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
    });

    tearDownAll(() async {
      if (await tempFile.exists()) await tempFile.delete();
    });

    test('envoie exactement les champs attendus, dont proof en multipart', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse(_expenseJson(), 201);
      });

      await repo.creerDepense(
        categorie: 'Travaux / Entretien',
        montant: 45000,
        date: DateTime(2026, 9, 10),
        intitule: 'Réparation plomberie',
        fournisseur: 'ETS Plomberie',
        buildingId: 1,
        ownerId: 3,
        justificatif: tempFile,
      );

      expect(seen!.path, '/expenses');
      expect(seen!.method, 'POST');
      expect(seen!.data, isA<FormData>());
      final formData = seen!.data as FormData;
      String field(String key) =>
          formData.fields.firstWhere((f) => f.key == key).value;
      expect(field('amount'), '45000.0');
      expect(field('date_expense'), '2026-09-10');
      expect(field('category'), 'Travaux / Entretien');
      expect(field('building_id'), '1');
      expect(field('owner_id'), '3');
      expect(field('description'), 'Réparation plomberie');
      expect(field('supplier_name'), 'ETS Plomberie');
      expect(formData.files, hasLength(1));
      expect(formData.files.first.key, 'proof');
    });

    test('champs facultatifs vides (null) omis', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse(_expenseJson(), 201);
      });

      await repo.creerDepense(
        categorie: 'Travaux / Entretien',
        montant: 45000,
        date: DateTime(2026, 9, 10),
        ownerId: 3,
      );

      final formData = seen!.data as FormData;
      final keys = formData.fields.map((f) => f.key).toSet();
      expect(keys, {'amount', 'date_expense', 'category', 'owner_id'});
      expect(formData.files, isEmpty);
    });

    test('succès : renvoie la dépense créée (RETURNING *)', () async {
      final repo = _repo(
        (options) async => jsonResponse(_expenseJson(id: 7), 201),
      );

      final result = await repo.creerDepense(
        categorie: 'Travaux / Entretien',
        montant: 45000,
        date: DateTime(2026, 9, 10),
        ownerId: 3,
      );

      expect(result, isA<CreerDepenseSuccess>());
      expect((result as CreerDepenseSuccess).depense.id, 7);
    });

    test('400 (validation des champs) → CreerDepenseValidationFailed', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Montant invalide (> 0)'}, 400),
      );

      final result = await repo.creerDepense(
        categorie: 'Travaux / Entretien',
        montant: 45000,
        date: DateTime(2026, 9, 10),
        ownerId: 3,
      );

      expect(result, isA<CreerDepenseValidationFailed>());
      expect(
        (result as CreerDepenseValidationFailed).message,
        'Montant invalide (> 0)',
      );
    });

    test('422 (aucun rattachement résolu) → CreerDepenseValidationFailed', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'message': 'Sélectionnez un immeuble ou un propriétaire pour cette dépense.',
        }, 422),
      );

      final result = await repo.creerDepense(
        categorie: 'Travaux / Entretien',
        montant: 45000,
        date: DateTime(2026, 9, 10),
      );

      expect(result, isA<CreerDepenseValidationFailed>());
      expect(
        (result as CreerDepenseValidationFailed).message,
        contains('immeuble ou un propriétaire'),
      );
    });

    test(
      'justificatif trop volumineux → CreerDepenseFichierRefuse, sans requête réseau',
      () async {
        final fichierVolumineux = File(
          '${Directory.systemTemp.path}/creer_depense_trop_gros.jpg',
        );
        await fichierVolumineux.writeAsBytes(
          List.filled(11 * 1024 * 1024, 0),
        );
        addTearDown(() async {
          if (await fichierVolumineux.exists()) {
            await fichierVolumineux.delete();
          }
        });

        var appels = 0;
        final repo = _repo((options) async {
          appels++;
          return jsonResponse(_expenseJson(), 201);
        });

        final result = await repo.creerDepense(
          categorie: 'Travaux / Entretien',
          montant: 45000,
          date: DateTime(2026, 9, 10),
          ownerId: 3,
          justificatif: fichierVolumineux,
        );

        expect(result, isA<CreerDepenseFichierRefuse>());
        expect(
          (result as CreerDepenseFichierRefuse).message,
          contains('10 Mo'),
        );
        expect(appels, 0);
      },
    );

    test('erreur réseau → CreerDepenseNetworkError', () async {
      final repo = _repo(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repo.creerDepense(
        categorie: 'Travaux / Entretien',
        montant: 45000,
        date: DateTime(2026, 9, 10),
        ownerId: 3,
      );

      expect(result, isA<CreerDepenseNetworkError>());
    });

    test('délai dépassé → CreerDepenseNetworkError', () async {
      final repo = _repo(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.sendTimeout,
        ),
      );

      final result = await repo.creerDepense(
        categorie: 'Travaux / Entretien',
        montant: 45000,
        date: DateTime(2026, 9, 10),
        ownerId: 3,
      );

      expect(result, isA<CreerDepenseNetworkError>());
    });

    test('erreur serveur générique (500) → CreerDepenseFailure', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Erreur serveur'}, 500),
      );

      final result = await repo.creerDepense(
        categorie: 'Travaux / Entretien',
        montant: 45000,
        date: DateTime(2026, 9, 10),
        ownerId: 3,
      );

      expect(result, isA<CreerDepenseFailure>());
      expect((result as CreerDepenseFailure).type, ApiExceptionType.server);
    });
  });
}
