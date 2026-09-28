import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/biens/data/biens_repository.dart';
import 'package:hope_gestion_mobile/features/biens/data/biens_results.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> _immeubleJson({
  int id = 1,
  String nom = 'Résidence Palmiers',
  // `nbLots`/`lotsOccupes`/`occupation` sont calculés côté serveur à partir
  // de COUNT() (bigint → chaîne côté Postgres) avant d'être réinjectés dans
  // la réponse : reproduit ici pour vérifier le parsing défensif, même si
  // le backend les convertit déjà en nombre avant l'envoi JSON.
  String nbLots = '8',
  String lotsOccupes = '5',
}) => {
  'id': id,
  'nom': nom,
  'type': 'Immeuble',
  'ville': 'Cotonou',
  'statut': 'actif',
  'nbLots': nbLots,
  'lotsOccupes': lotsOccupes,
  'occupation': 63,
  'etatOccupation': 'En location',
  'proprietaire': 'Mamadou Camara',
};

Map<String, dynamic> _lotJson({
  int id = 10,
  String reference = 'Apt. 12',
  String superficie = '86.5',
  String loyer = '185000',
}) => {
  'id': id,
  'reference': reference,
  'building_id': 1,
  'immeuble': 'Résidence Palmiers',
  'etage': 2,
  'superficie': superficie,
  'nbPieces': 3,
  'loyer': loyer,
  'charges': '15000',
  'statut': 'occupe',
};

BiensRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final tokenStorage = TokenStorage();
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(responder);
  final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
  return BiensRepository(apiClient: apiClient);
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  group('listImmeubles (GET /biens/immeubles)', () {
    test(
      'succès : mappe la liste, y compris les agrégats renvoyés en chaînes',
      () async {
        final repo = _repo((options) async {
          expect(options.path, '/biens/immeubles');
          return jsonResponse({
            'immeubles': [_immeubleJson()],
          }, 200);
        });

        final result = await repo.listImmeubles();

        expect(result, isA<ImmeublesListSuccess>());
        final items = (result as ImmeublesListSuccess).items;
        expect(items, hasLength(1));
        expect(items.first.nom, 'Résidence Palmiers');
        expect(items.first.nbLots, 8);
        expect(items.first.lotsOccupes, 5);
        expect(items.first.ownerName, 'Mamadou Camara');
        expect(repo.immeubles, hasLength(1));
      },
    );

    test('erreur réseau → ImmeublesListFailure(network)', () async {
      final repo = _repo((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      final result = await repo.listImmeubles();

      expect(result, isA<ImmeublesListFailure>());
      expect(
        (result as ImmeublesListFailure).type,
        ApiExceptionType.network,
      );
      expect(repo.immeubles, isEmpty);
    });
  });

  group('listLots (GET /biens/lots)', () {
    test('succès : mappe la liste', () async {
      final repo = _repo((options) async {
        expect(options.path, '/biens/lots');
        return jsonResponse({
          'lots': [_lotJson()],
        }, 200);
      });

      final result = await repo.listLots();

      expect(result, isA<LotsListSuccess>());
      final items = (result as LotsListSuccess).items;
      expect(items, hasLength(1));
      expect(items.first.reference, 'Apt. 12');
      expect(items.first.superficie, 86.5);
      expect(items.first.loyer, 185000.0);
      expect(items.first.etage, '2');
      expect(repo.lots, hasLength(1));
    });

    test('erreur serveur (500) → LotsListFailure(server)', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Erreur serveur'}, 500),
      );

      final result = await repo.listLots();

      expect(result, isA<LotsListFailure>());
      expect((result as LotsListFailure).type, ApiExceptionType.server);
    });
  });

  group('createImmeuble (POST /biens/immeubles)', () {
    test(
      'succès : envoie les champs attendus (200, ligne complète) puis rafraîchit',
      () async {
        var postCalls = 0;
        var getCalls = 0;
        final repo = _repo((options) async {
          if (options.method == 'POST' && options.path == '/biens/immeubles') {
            postCalls++;
            final data = options.data as Map;
            expect(data['nom'], 'Résidence Palmiers');
            expect(data['owner_id'], 7);
            // Champs optionnels vides omis, sauf `adresse` : NOT NULL côté
            // backend (satisfait par une chaîne vide, pas d'omission
            // possible — correctif T-033 sur T-032).
            expect(data.containsKey('description'), isFalse);
            expect(data['adresse'], '');
            return jsonResponse(_immeubleJson(), 200);
          }
          if (options.method == 'GET' && options.path == '/biens/immeubles') {
            getCalls++;
            return jsonResponse({
              'immeubles': [_immeubleJson()],
            }, 200);
          }
          throw UnimplementedError('${options.method} ${options.path}');
        });

        final result = await repo.createImmeuble(
          nom: 'Résidence Palmiers',
          ownerId: 7,
        );

        expect(result, isA<CreateImmeubleSuccess>());
        expect((result as CreateImmeubleSuccess).id, 1);
        expect(postCalls, 1);
        expect(getCalls, 1);
        expect(repo.immeubles, hasLength(1));
      },
    );

    test('400 de validation → CreateImmeubleValidationFailed', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'message': 'Certaines informations sont invalides.',
          'errors': [
            {'path': 'nom', 'msg': "Le nom est obligatoire"},
          ],
        }, 400),
      );

      final result = await repo.createImmeuble(nom: '');

      expect(result, isA<CreateImmeubleValidationFailed>());
      expect(
        (result as CreateImmeubleValidationFailed).fieldErrors['nom'],
        isNotNull,
      );
    });
  });

  group('updateImmeuble (POST /biens/immeubles avec id)', () {
    Future<UpdateImmeubleResult> update(
      BiensRepository repo, {
      int? ownerId = 7,
    }) => repo.updateImmeuble(
      id: 1,
      nom: 'Résidence Palmiers',
      type: 'Immeuble',
      adresse: null,
      ville: 'Cotonou',
      pays: 'Bénin',
      quartier: 'Haie Vive',
      description: 'R+3',
      latitude: 6.36,
      longitude: 2.42,
      gestionnaireId: 12,
      statut: 'actif',
      photos: const ['/uploads/properties/a.jpg', '/uploads/properties/b.jpg'],
      photo: '/uploads/properties/a.jpg',
      videoUrl: 'https://video.test/v.mp4',
      planMasseUrl: '/uploads/plans/p.pdf',
      nombreEtages: 0,
      totalLots: 20,
      ownerId: ownerId,
    );

    test(
      'envoie TOUS les champs (réécriture sans COALESCE), dont owner_id, '
      'puis rafraîchit',
      () async {
        Map? sent;
        var getCalls = 0;
        final repo = _repo((options) async {
          if (options.method == 'POST' && options.path == '/biens/immeubles') {
            sent = options.data as Map;
            return jsonResponse(_immeubleJson(), 200);
          }
          if (options.method == 'GET' && options.path == '/biens/immeubles') {
            getCalls++;
            return jsonResponse({
              'immeubles': [_immeubleJson()],
            }, 200);
          }
          throw UnimplementedError('${options.method} ${options.path}');
        });

        final result = await update(repo);

        expect(result, isA<UpdateImmeubleSuccess>());
        expect(getCalls, 1);
        expect(sent, {
          'id': 1,
          'nom': 'Résidence Palmiers',
          'type': 'Immeuble',
          // `adresse` NOT NULL côté base : chaîne vide plutôt que null.
          'adresse': '',
          'ville': 'Cotonou',
          'pays': 'Bénin',
          'quartier': 'Haie Vive',
          'description': 'R+3',
          'latitude': 6.36,
          'longitude': 2.42,
          'gestionnaire_id': 12,
          'statut': 'actif',
          'photos': ['/uploads/properties/a.jpg', '/uploads/properties/b.jpg'],
          'photo': '/uploads/properties/a.jpg',
          'video_url': 'https://video.test/v.mp4',
          'plan_masse_url': '/uploads/plans/p.pdf',
          'nombre_etages': 0,
          'total_lots': 20,
          'owner_id': 7,
        });
      },
    );

    test('les champs vides sont envoyés à null, jamais omis', () async {
      Map? sent;
      final repo = _repo((options) async {
        if (options.method == 'POST') {
          sent = options.data as Map;
          return jsonResponse(_immeubleJson(), 200);
        }
        return jsonResponse({'immeubles': <dynamic>[]}, 200);
      });

      await update(repo, ownerId: null);

      expect(sent!.containsKey('owner_id'), isTrue);
      expect(sent!['owner_id'], isNull);
    });

    test('404 (introuvable ou non visible par RLS) → UpdateImmeubleFailure',
        () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'message': 'Immeuble non trouvé ou accès non autorisé.',
        }, 404),
      );

      final result = await update(repo);

      expect(result, isA<UpdateImmeubleFailure>());
      expect(
        (result as UpdateImmeubleFailure).type,
        ApiExceptionType.notFound,
      );
    });
  });

  group('createLot (POST /biens/lots)', () {
    test('succès : envoie les champs attendus puis rafraîchit', () async {
      var postCalls = 0;
      var getCalls = 0;
      final repo = _repo((options) async {
        if (options.method == 'POST' && options.path == '/biens/lots') {
          postCalls++;
          final data = options.data as Map;
          expect(data['building_id'], 1);
          expect(data['reference'], 'Apt. 12');
          return jsonResponse(_lotJson(), 200);
        }
        if (options.method == 'GET' && options.path == '/biens/lots') {
          getCalls++;
          return jsonResponse({
            'lots': [_lotJson()],
          }, 200);
        }
        throw UnimplementedError('${options.method} ${options.path}');
      });

      final result = await repo.createLot(buildingId: 1, reference: 'Apt. 12');

      expect(result, isA<CreateLotSuccess>());
      expect((result as CreateLotSuccess).id, 10);
      expect(postCalls, 1);
      expect(getCalls, 1);
    });

    test(
      '403 (limite du plan atteinte) → CreateLotFailure(forbidden)',
      () async {
        final repo = _repo(
          (options) async => jsonResponse({
            'message':
                'Limite atteinte. Votre plan (Essentiel) permet un maximum de 5 biens.',
          }, 403),
        );

        final result = await repo.createLot(buildingId: 1, reference: 'Apt. 1');

        expect(result, isA<CreateLotFailure>());
        expect((result as CreateLotFailure).type, ApiExceptionType.forbidden);
        expect(result.message, contains('Limite atteinte'));
      },
    );

    test(
      '400 (immeuble introuvable) → CreateLotValidationFailed (tout 400 est '
      'typé "validation" par ApiException, sans distinction de cause)',
      () async {
        final repo = _repo(
          (options) async => jsonResponse(
            {'message': 'Immeuble invalide, introuvable ou non autorisé.'},
            400,
          ),
        );

        final result = await repo.createLot(buildingId: 999, reference: 'X');

        expect(result, isA<CreateLotValidationFailed>());
        expect(
          (result as CreateLotValidationFailed).message,
          'Immeuble invalide, introuvable ou non autorisé.',
        );
      },
    );
  });

  group('deleteImmeuble (DELETE /biens/immeubles/:id)', () {
    test('succès : retire l\'immeuble localement', () async {
      final repo = _repo((options) async {
        if (options.method == 'GET') {
          return jsonResponse({
            'immeubles': [_immeubleJson(id: 1), _immeubleJson(id: 2)],
          }, 200);
        }
        expect(options.method, 'DELETE');
        expect(options.path, '/biens/immeubles/1');
        return jsonResponse({'message': 'Immeuble déplacé vers la corbeille.'}, 200);
      });

      await repo.listImmeubles();
      expect(repo.immeubles, hasLength(2));

      final result = await repo.deleteImmeuble(1);

      expect(result, isA<DeleteImmeubleSuccess>());
      expect(repo.immeubles, hasLength(1));
      expect(repo.immeubles.first.id, 2);
    });

    test('409 (lots rattachés) → DeleteImmeubleHasLots, liste inchangée', () async {
      final repo = _repo((options) async {
        if (options.method == 'GET') {
          return jsonResponse({
            'immeubles': [_immeubleJson(id: 1)],
          }, 200);
        }
        return jsonResponse({
          'message':
              'Impossible de supprimer : 3 lot(s) sont rattachés à cet immeuble. Supprimez-les d\'abord.',
        }, 409);
      });

      await repo.listImmeubles();
      final result = await repo.deleteImmeuble(1);

      expect(result, isA<DeleteImmeubleHasLots>());
      expect(repo.immeubles, hasLength(1));
    });
  });

  group('deleteLot (DELETE /biens/lots/:id)', () {
    test('succès : retire le lot localement', () async {
      final repo = _repo((options) async {
        if (options.method == 'GET') {
          return jsonResponse({
            'lots': [_lotJson(id: 10), _lotJson(id: 11)],
          }, 200);
        }
        expect(options.method, 'DELETE');
        expect(options.path, '/biens/lots/10');
        return jsonResponse({'message': 'Lot déplacé vers la corbeille.'}, 200);
      });

      await repo.listLots();
      final result = await repo.deleteLot(10);

      expect(result, isA<DeleteLotSuccess>());
      expect(repo.lots, hasLength(1));
      expect(repo.lots.first.id, 11);
    });

    test('échec (404) → DeleteLotFailure, liste inchangée', () async {
      final repo = _repo((options) async {
        if (options.method == 'GET') {
          return jsonResponse({
            'lots': [_lotJson(id: 10)],
          }, 200);
        }
        return jsonResponse({'message': 'Lot introuvable ou accès refusé.'}, 404);
      });

      await repo.listLots();
      final result = await repo.deleteLot(10);

      expect(result, isA<DeleteLotFailure>());
      expect((result as DeleteLotFailure).type, ApiExceptionType.notFound);
      expect(repo.lots, hasLength(1));
    });
  });
}
