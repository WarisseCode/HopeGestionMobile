import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/documents/data/baux_repository.dart';
import 'package:hope_gestion_mobile/features/documents/data/baux_results.dart';
import 'package:hope_gestion_mobile/features/documents/models/nouveau_bail.dart';

import '../../../support/fake_http_adapter.dart';

BauxRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(responder);
  return BauxRepository(
    apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
  );
}

Future<CreerBailResult> _creer(
  BauxRepository repo, {
  String? conditions = 'Usage commercial',
}) => repo.creerBail(
  tenantId: 3,
  lotId: 12,
  ownerId: 7,
  dateDebut: DateTime(2026, 10, 5),
  dureeMois: 12,
  loyerMensuel: 185000,
  caution: 370000,
  avanceMois: 2,
  chargesMensuelles: 10000,
  jourEcheance: 5,
  conditionsParticulieres: conditions,
);

Map<String, dynamic> _bailCreeJson() => {
  'id': 42,
  'reference_bail': 'BAIL-2026-0042',
  'loyer_actuel': '185000.00',
  'date_debut': '2026-10-05',
  'date_fin': '2027-10-05',
  'statut': 'actif',
  'owner_id': 7,
};

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  group('creerBail (POST /locations)', () {
    test('succès : payload exact et bail parsé', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse(_bailCreeJson(), 201);
      });

      final result = await _creer(repo) as CreerBailSuccess;

      expect(seen!.path, '/locations');
      expect(seen!.method, 'POST');
      expect(seen!.data, {
        'tenant_id': 3,
        'lot_id': 12,
        'owner_id': 7,
        'type_contrat': 'location',
        'type_paiement': 'classique',
        'date_debut': '2026-10-05',
        'duree_contrat': 12,
        'date_fin': '2027-10-05',
        'loyer_mensuel': 185000.0,
        'caution': 370000.0,
        'avance': 2, // nombre de mois brut, comme le web (pas de conversion FCFA)
        'charges_mensuelles': 10000.0,
        'jour_echeance': 5,
        'conditions_particulieres': 'Usage commercial',
      });
      // `2 == 2.0` en Dart : vérifie aussi le type (entier, pas un montant).
      expect((seen!.data as Map)['avance'], isA<int>());
      expect(result.bail.id, 42);
      expect(result.bail.referenceBail, 'BAIL-2026-0042');
      expect(result.bail.loyerActuel, 185000);
    });

    test('conditions vides : champ omis, jour_echeance et owner_id toujours présents', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse(_bailCreeJson(), 201);
      });

      await _creer(repo, conditions: '   ');

      final data = seen!.data as Map;
      expect(data.containsKey('conditions_particulieres'), isFalse);
      expect(data['jour_echeance'], 5);
      expect(data['owner_id'], 7);
    });

    test('400 « déjà une affectation active » : résultat dédié', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'message': 'Ce lot a déjà une affectation active',
        }, 400),
      );

      final result = await _creer(repo);

      expect(result, isA<CreerBailLotDejaAffecte>());
      expect(
        (result as CreerBailLotDejaAffecte).message,
        'Ce lot a déjà une affectation active',
      );
    });

    test('autre 400 : validation générique', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'errors': [
            {'path': 'jour_echeance', 'msg': "Jour d'échéance invalide (1-31)"},
          ],
        }, 400),
      );

      final result = await _creer(repo) as CreerBailValidationFailed;

      expect(result.message, "Jour d'échéance invalide (1-31)");
      expect(result.fieldErrors['jour_echeance'], isNotNull);
    });

    test('403 : permission refusée', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Accès refusé'}, 403),
      );

      expect(await _creer(repo), isA<CreerBailPermissionRefusee>());
    });

    test('erreur réseau : résultat réseau, une seule requête', () async {
      var appels = 0;
      final repo = _repo((options) async {
        appels++;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      expect(await _creer(repo), isA<CreerBailNetworkError>());
      expect(appels, 1);
    });

    test('timeout : résultat réseau', () async {
      final repo = _repo((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      });

      expect(await _creer(repo), isA<CreerBailNetworkError>());
    });

    test('500 : échec générique de type serveur', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Erreur serveur'}, 500),
      );

      final result = await _creer(repo) as CreerBailFailure;
      expect(result.type, ApiExceptionType.server);
    });

    test('201 sans id exploitable : échec signalant une création probable', () async {
      final repo = _repo((options) async => jsonResponse({'ok': true}, 201));

      final result = await _creer(repo) as CreerBailFailure;
      expect(result.message, contains('probablement été créé'));
    });
  });

  group('getBail (GET /locations/:id)', () {
    Map<String, dynamic> location() => {
      'id': 42,
      'reference_bail': 'BAIL-2026-0042',
      'statut': 'actif',
      'type_paiement': 'classique',
      'loyer_actuel': '185000.00',
      'loyer_mensuel': '185000.00',
      'caution': '370000.00',
      'avance': 2,
      'charges_mensuelles': '10000.00',
      'jour_echeance': 5,
      'date_debut': '2026-10-05',
      'date_fin': '2027-10-05',
      'locataire_nom': 'Diop',
      'locataire_prenoms': 'Yacine',
      'locataire_telephone': '+22990000001',
      'locataire_email': 'yacine@example.com',
      'ref_lot': 'A1',
      'lot_type': 'appartement',
      'immeuble_nom': 'Résidence Palmiers',
      'immeuble_adresse': 'Rue 12, Cotonou',
      'proprietaire_nom': 'Mamadou Camara',
    };

    test('succès : tous les champs parsés, échéancier vide', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse({
          'location': location(),
          'echeancier': <dynamic>[],
        }, 200);
      });

      final result = await repo.getBail(42) as BailDetailSuccess;

      expect(seen!.path, '/locations/42');
      expect(seen!.method, 'GET');
      final bail = result.bail;
      expect(bail.id, 42);
      expect(bail.referenceBail, 'BAIL-2026-0042');
      expect(bail.statut, 'actif');
      expect(bail.typePaiement, 'classique');
      expect(bail.loyerMensuel, 185000);
      expect(bail.caution, 370000);
      expect(bail.avanceMois, 2);
      expect(bail.chargesMensuelles, 10000);
      expect(bail.jourEcheance, 5);
      expect(bail.dateDebut, DateTime(2026, 10, 5));
      expect(bail.dateFin, DateTime(2027, 10, 5));
      expect(bail.locataireNomComplet, 'Diop Yacine');
      expect(bail.locataireTelephone, '+22990000001');
      expect(bail.locataireEmail, 'yacine@example.com');
      expect(bail.refLot, 'A1');
      expect(bail.lotType, 'appartement');
      expect(bail.immeubleNom, 'Résidence Palmiers');
      expect(bail.immeubleAdresse, 'Rue 12, Cotonou');
      expect(bail.proprietaireNom, 'Mamadou Camara');
      expect(bail.echeancier, isEmpty);
    });

    test('succès : échéancier non vide, trié par date', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'location': {...location(), 'avance': '3.00'},
          'echeancier': [
            {
              'id': 2,
              'lease_id': 42,
              'total_amount': '185000.00',
              'amount_paid': '0.00',
              'due_date': '2026-12-05',
              'status': 'pending',
            },
            {
              'id': 1,
              'lease_id': 42,
              'total_amount': '185000.00',
              'amount_paid': '185000.00',
              'due_date': '2026-11-05',
              'status': 'paid',
            },
          ],
        }, 200),
      );

      final bail = (await repo.getBail(42) as BailDetailSuccess).bail;

      expect(bail.avanceMois, 3); // NUMERIC en chaîne toléré
      expect(bail.echeancier.map((e) => e.id), [1, 2]);
      expect(bail.echeancier.first.estSoldee, isTrue);
      expect(bail.echeancier.last.leaseId, 42);
    });

    test('échéancier absent : liste vide, pas une erreur', () async {
      final repo = _repo(
        (options) async => jsonResponse({'location': location()}, 200),
      );

      final bail = (await repo.getBail(42) as BailDetailSuccess).bail;
      expect(bail.echeancier, isEmpty);
    });

    test('réponse sans location : échec de format', () async {
      final repo = _repo(
        (options) async => jsonResponse({'echeancier': <dynamic>[]}, 200),
      );

      final result = await repo.getBail(42) as BailDetailFailure;
      expect(result.type, ApiExceptionType.unknown);
    });

    test('404 : introuvable (bail inexistant ou hors périmètre)', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'message': 'Contrat non trouvé ou accès refusé',
        }, 404),
      );

      final result = await repo.getBail(42);
      expect(result, isA<BailDetailIntrouvable>());
    });

    test('403 : accès refusé', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Accès refusé'}, 403),
      );

      expect(await repo.getBail(42), isA<BailDetailAccesRefuse>());
    });

    test('réseau : erreur réseau', () async {
      final repo = _repo((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      expect(await repo.getBail(42), isA<BailDetailNetworkError>());
    });

    test('n\'appelle jamais /locations/:id/echeancier', () async {
      final paths = <String>[];
      final repo = _repo((options) async {
        paths.add(options.path);
        return jsonResponse({
          'location': location(),
          'echeancier': <dynamic>[],
        }, 200);
      });

      await repo.getBail(42);
      expect(paths, ['/locations/42']);
    });
  });

  group('getBailActifDuLot (GET /locations, filtre client)', () {
    Map<String, dynamic> ligne({
      required int id,
      required int lotId,
      required String statut,
      String? reference,
    }) => {
      'id': id,
      'reference_bail': reference ?? 'BAIL-$id',
      'lot_id': lotId,
      'tenant_id': 3,
      'date_debut': '2026-10-05',
      'date_fin': '2027-10-05',
      'loyer_mensuel': '185000.00',
      'statut': statut,
      'locataire_nom': 'Diop',
      'locataire_prenoms': 'Yacine',
      'locataire_telephone': '+22990000001',
      'locataire_photo': '/uploads/yacine.jpg',
      'ref_lot': 'A1',
    };

    test('bail trouvé : tous les champs, sans paramètre statut', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return jsonResponse({
          'locations': [ligne(id: 42, lotId: 12, statut: 'actif')],
        }, 200);
      });

      final result = await repo.getBailActifDuLot(12) as BailActifTrouve;

      expect(seen!.path, '/locations');
      expect(seen!.method, 'GET');
      expect(seen!.queryParameters.containsKey('statut'), isFalse);
      final bail = result.bail;
      expect(bail.id, 42);
      expect(bail.referenceBail, 'BAIL-42');
      expect(bail.tenantId, 3);
      expect(bail.locataireNom, 'Diop');
      expect(bail.locatairePrenoms, 'Yacine');
      expect(bail.locataireNomComplet, 'Diop Yacine');
      expect(bail.locataireTelephone, '+22990000001');
      expect(bail.locatairePhoto, '/uploads/yacine.jpg');
      expect(bail.dateDebut, DateTime(2026, 10, 5));
      expect(bail.dateFin, DateTime(2027, 10, 5));
      expect(bail.loyerMensuel, 185000);
      expect(bail.statut, 'actif');
    });

    test('lot vacant : LotSansBailActif (succès, pas une erreur)', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'locations': [ligne(id: 1, lotId: 99, statut: 'actif')],
        }, 200),
      );

      expect(await repo.getBailActifDuLot(12), isA<LotSansBailActif>());
    });

    test('liste vide : LotSansBailActif', () async {
      final repo = _repo(
        (options) async => jsonResponse({'locations': <dynamic>[]}, 200),
      );

      expect(await repo.getBailActifDuLot(12), isA<LotSansBailActif>());
    });

    test('filtrage : résiliés et autres lots ignorés, plus récent actif/signé', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          // Ordre serveur : created_at DESC.
          'locations': [
            ligne(id: 50, lotId: 12, statut: 'resilie'),
            ligne(id: 49, lotId: 7, statut: 'actif'),
            {'statut': 'actif', 'lot_id': 12}, // sans id : ignorée
            ligne(id: 48, lotId: 12, statut: 'signe'),
            ligne(id: 40, lotId: 12, statut: 'actif'),
            ligne(id: 30, lotId: 12, statut: 'termine'),
          ],
        }, 200),
      );

      final result = await repo.getBailActifDuLot(12) as BailActifTrouve;
      expect(result.bail.id, 48);
      expect(result.bail.statut, 'signe');
    });

    test('uniquement des baux résiliés sur le lot : LotSansBailActif', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'locations': [
            ligne(id: 50, lotId: 12, statut: 'resilie'),
            ligne(id: 30, lotId: 12, statut: 'termine'),
          ],
        }, 200),
      );

      expect(await repo.getBailActifDuLot(12), isA<LotSansBailActif>());
    });

    test('403 : accès refusé', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Accès refusé'}, 403),
      );

      final result = await repo.getBailActifDuLot(12);
      expect(result, isA<BailActifAccesRefuse>());
      expect((result as BailActifAccesRefuse).message, 'Accès refusé');
    });

    test('réseau : erreur réseau', () async {
      final repo = _repo((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      expect(await repo.getBailActifDuLot(12), isA<BailActifNetworkError>());
    });

    test('réponse sans locations : échec de format', () async {
      final repo = _repo((options) async => jsonResponse({'ok': true}, 200));

      final result = await repo.getBailActifDuLot(12) as BailActifFailure;
      expect(result.type, ApiExceptionType.unknown);
    });

    test('500 : échec générique de type serveur', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Erreur serveur'}, 500),
      );

      final result = await repo.getBailActifDuLot(12) as BailActifFailure;
      expect(result.type, ApiExceptionType.server);
    });
  });

  group('calculs (fonctions pures)', () {
    test('date_fin = date_debut + durée en mois', () {
      expect(calculerDateFinBail(DateTime(2026, 10, 5), 12), DateTime(2027, 10, 5));
      expect(calculerDateFinBail(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
    });

    test('fin de mois ramenée au dernier jour du mois cible', () {
      expect(calculerDateFinBail(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(calculerDateFinBail(DateTime(2027, 12, 31), 2), DateTime(2028, 2, 29));
    });

    test('avance : mois × loyer, libellé FCFA', () {
      expect(convertirAvanceEnFcfa(avanceMois: 2, loyerMensuel: 185000), 370000);
      expect(
        libelleAvance(avanceMois: 2, loyerMensuel: 185000),
        '2 mois = 370 000 FCFA',
      );
    });

    test('validations', () {
      expect(validerDureeBail(0), isNotNull);
      expect(validerDureeBail(12), isNull);
      expect(validerLoyerBail(0), isNotNull);
      expect(validerLoyerBail(1), isNull);
      expect(validerMontantPositifOuNul(0), isNull);
      expect(validerMontantPositifOuNul(null), isNotNull);
      expect(validerAvanceMois(0), isNull);
      expect(validerJourEcheance(0), isNotNull);
      expect(validerJourEcheance(32), isNotNull);
      expect(validerJourEcheance(31), isNull);
      expect(
        validerConditionsParticulieres('a' * (conditionsParticulieresMaxLength + 1)),
        isNotNull,
      );
      expect(
        validerConditionsParticulieres('a' * conditionsParticulieresMaxLength),
        isNull,
      );
    });
  });
}
