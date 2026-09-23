import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/locataires/data/locataire_results.dart';
import 'package:hope_gestion_mobile/features/locataires/data/locataires_repository.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> _tenantJson({
  int id = 1,
  String nom = 'Diop',
  String prenoms = 'Yacine',
  // Postgres renvoie souvent COUNT/SUM sous forme de chaînes (bigint/numeric) :
  // reproduit volontairement ici pour vérifier le parsing défensif.
  String activeLeases = '2',
  String loyerTotal = '370000.00',
}) => {
  'id': id,
  'nom': nom,
  'prenoms': prenoms,
  'telephone_principal': '+22990000000',
  'type': 'Locataire',
  'statut': 'Actif',
  'active_leases': activeLeases,
  'loyer_total': loyerTotal,
  'lot_nom': 'Apt. 12',
  'payment_status': 'paid',
};

LocatairesRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final tokenStorage = TokenStorage();
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(responder);
  final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
  return LocatairesRepository(apiClient: apiClient);
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  group('refresh (GET /locataires)', () {
    test('succès : mappe la liste, y compris les agrégats numériques renvoyés en chaînes', () async {
      final repo = _repo((options) async {
        expect(options.path, '/locataires');
        return jsonResponse({
          'locataires': [_tenantJson()],
        }, 200);
      });

      final result = await repo.refresh();

      expect(result, isA<LocatairesListSuccess>());
      final items = (result as LocatairesListSuccess).items;
      expect(items, hasLength(1));
      expect(items.first.displayName, 'Yacine Diop');
      expect(items.first.activeLeases, 2);
      expect(items.first.loyerTotal, 370000.0);
      expect(repo.items, hasLength(1));
    });

    test('erreur réseau → LocatairesListFailure(network)', () async {
      final repo = _repo((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      final result = await repo.refresh();

      expect(result, isA<LocatairesListFailure>());
      expect((result as LocatairesListFailure).type, ApiExceptionType.network);
      expect(repo.items, isEmpty);
    });
  });

  group('getDetail (GET /locataires/:id)', () {
    test('succès : locataire + baux + paiements', () async {
      final repo = _repo((options) async {
        expect(options.path, '/locataires/1');
        return jsonResponse({
          'locataire': _tenantJson(),
          'baux': [
            {
              'id': 10,
              'statut': 'actif',
              'building_name': 'Résidence Palmiers',
              'ref_lot': 'Apt. 12',
              'loyer_actuel': '185000',
              'payment_status': 'paid',
            },
          ],
          'paiements': [
            {
              'id': 100,
              'montant': '185000',
              'type': 'loyer',
              'mode_paiement': 'MTN MoMo',
              'date_paiement': '2026-09-01',
            },
          ],
        }, 200);
      });

      final result = await repo.getDetail(1);

      expect(result, isA<LocataireDetailSuccess>());
      final success = result as LocataireDetailSuccess;
      expect(success.locataire.displayName, 'Yacine Diop');
      expect(success.baux, hasLength(1));
      expect(success.baux.first.buildingName, 'Résidence Palmiers');
      expect(success.paiements, hasLength(1));
      expect(success.paiements.first.montant, 185000.0);
    });

    test('erreur serveur (500) → LocataireDetailFailure(server)', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Erreur serveur'}, 500),
      );

      final result = await repo.getDetail(1);

      expect(result, isA<LocataireDetailFailure>());
      expect((result as LocataireDetailFailure).type, ApiExceptionType.server);
    });
  });

  group('create (POST /locataires)', () {
    test('succès : envoie les champs attendus puis rafraîchit la liste', () async {
      var postCalls = 0;
      var getCalls = 0;
      final repo = _repo((options) async {
        if (options.method == 'POST' && options.path == '/locataires') {
          postCalls++;
          final data = options.data as Map;
          expect(data['nom'], 'Diop');
          expect(data['prenoms'], 'Yacine');
          expect(data['telephone_principal'], '+22990000000');
          expect(data['type'], 'Locataire');
          expect(data['paiement_echelonne'], false);
          expect(data['owner_id'], 7);
          // Champs optionnels vides omis, pas envoyés comme chaîne vide.
          expect(data.containsKey('email'), isFalse);
          return jsonResponse(
            {'message': 'Locataire créé', 'id': 42, 'invitation_code': 'LOC-XYZ'},
            201,
          );
        }
        if (options.method == 'GET' && options.path == '/locataires') {
          getCalls++;
          return jsonResponse({
            'locataires': [_tenantJson(id: 42)],
          }, 200);
        }
        throw UnimplementedError('${options.method} ${options.path}');
      });

      final result = await repo.create(
        nom: 'Diop',
        prenoms: 'Yacine',
        telephonePrincipal: '+22990000000',
        email: '',
        ownerId: 7,
      );

      expect(result, isA<CreateLocataireSuccess>());
      expect((result as CreateLocataireSuccess).id, 42);
      expect(postCalls, 1);
      expect(getCalls, 1);
      expect(repo.items, hasLength(1));
    });

    test(
      'envoie date_expiration_piece au format AAAA-MM-JJ (ISO, non ambigu pour Postgres)',
      () async {
        var postCalls = 0;
        final repo = _repo((options) async {
          if (options.method == 'POST' && options.path == '/locataires') {
            postCalls++;
            final data = options.data as Map;
            expect(data['date_expiration_piece'], '2030-09-20');
            return jsonResponse(
              {'message': 'Locataire créé', 'id': 42, 'invitation_code': 'LOC-XYZ'},
              201,
            );
          }
          if (options.method == 'GET' && options.path == '/locataires') {
            return jsonResponse({'locataires': <dynamic>[]}, 200);
          }
          throw UnimplementedError('${options.method} ${options.path}');
        });

        final result = await repo.create(
          nom: 'Diop',
          prenoms: 'Yacine',
          telephonePrincipal: '+22990000000',
          dateExpirationPiece: '2030-09-20',
        );

        expect(result, isA<CreateLocataireSuccess>());
        expect(postCalls, 1);
      },
    );

    test('409 (doublon téléphone/email) → CreateLocataireDuplicate', () async {
      final repo = _repo(
        (options) async => jsonResponse(
          {'message': 'Un locataire avec ce téléphone ou cet email existe déjà.'},
          409,
        ),
      );

      final result = await repo.create(
        nom: 'Diop',
        prenoms: 'Yacine',
        telephonePrincipal: '+22990000000',
      );

      expect(result, isA<CreateLocataireDuplicate>());
    });

    test('400 de validation → CreateLocataireValidationFailed', () async {
      final repo = _repo(
        (options) async => jsonResponse({
          'message': 'Certaines informations sont invalides.',
          'errors': [
            {'path': 'telephone_principal', 'msg': 'Le téléphone principal est obligatoire'},
          ],
        }, 400),
      );

      final result = await repo.create(
        nom: 'Diop',
        prenoms: 'Yacine',
        telephonePrincipal: '',
      );

      expect(result, isA<CreateLocataireValidationFailed>());
      expect(
        (result as CreateLocataireValidationFailed).fieldErrors['telephone_principal'],
        isNotNull,
      );
    });
  });

  group('update (PUT /locataires/:id)', () {
    test('succès : envoie tous les champs (pas de mise à jour partielle) puis rafraîchit', () async {
      var putCalls = 0;
      var getCalls = 0;
      final repo = _repo((options) async {
        if (options.method == 'PUT' && options.path == '/locataires/1') {
          putCalls++;
          final data = options.data as Map;
          // Tous les champs éditables doivent être présents, même null,
          // pour ne pas se faire écraser silencieusement côté backend
          // (voir doc de LocatairesRepository.update).
          expect(data.containsKey('nom'), isTrue);
          expect(data.containsKey('statut'), isTrue);
          expect(data.containsKey('adresse_actuelle'), isTrue);
          expect(data['statut'], 'Rejeté');
          return jsonResponse({'message': 'Locataire mis à jour'}, 200);
        }
        if (options.method == 'GET' && options.path == '/locataires') {
          getCalls++;
          return jsonResponse({'locataires': <dynamic>[]}, 200);
        }
        throw UnimplementedError('${options.method} ${options.path}');
      });

      final result = await repo.update(
        id: 1,
        nom: 'Diop',
        prenoms: 'Yacine',
        telephonePrincipal: '+22990000000',
        type: 'Locataire',
        statut: 'Rejeté',
        paiementEchelonne: false,
      );

      expect(result, isA<UpdateLocataireSuccess>());
      expect(putCalls, 1);
      expect(getCalls, 1);
    });

    test('400 de validation → UpdateLocataireValidationFailed', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Email invalide'}, 400),
      );

      final result = await repo.update(
        id: 1,
        nom: 'Diop',
        prenoms: 'Yacine',
        telephonePrincipal: '+22990000000',
        type: 'Locataire',
        statut: 'Actif',
        paiementEchelonne: false,
      );

      expect(result, isA<UpdateLocataireValidationFailed>());
    });
  });

  group('delete (DELETE /locataires/:id)', () {
    test('succès : retire le locataire localement', () async {
      final repo = _repo((options) async {
        if (options.method == 'GET') {
          return jsonResponse({
            'locataires': [_tenantJson(id: 1), _tenantJson(id: 2)],
          }, 200);
        }
        expect(options.method, 'DELETE');
        expect(options.path, '/locataires/1');
        return jsonResponse({'message': 'Locataire déplacé vers la corbeille'}, 200);
      });

      await repo.refresh();
      expect(repo.items, hasLength(2));

      final result = await repo.delete(1);

      expect(result, isA<DeleteLocataireSuccess>());
      expect(repo.items, hasLength(1));
      expect(repo.items.first.id, 2);
    });

    test('échec (404) → DeleteLocataireFailure, liste inchangée', () async {
      final repo = _repo((options) async {
        if (options.method == 'GET') {
          return jsonResponse({
            'locataires': [_tenantJson(id: 1)],
          }, 200);
        }
        return jsonResponse({'message': 'Ressource introuvable ou accès refusé.'}, 404);
      });

      await repo.refresh();
      final result = await repo.delete(1);

      expect(result, isA<DeleteLocataireFailure>());
      expect((result as DeleteLocataireFailure).type, ApiExceptionType.notFound);
      expect(repo.items, hasLength(1));
    });
  });
}
