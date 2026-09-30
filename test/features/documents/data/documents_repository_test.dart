import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/documents/data/documents_repository.dart';
import 'package:hope_gestion_mobile/features/documents/data/documents_results.dart';
import 'package:hope_gestion_mobile/features/documents/models/document.dart';

import '../../../support/fake_http_adapter.dart';

/// `/documents` et `/quittances` renvoient un tableau nu.
ResponseBody _listResponse(List<dynamic> body, [int statusCode = 200]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

DocumentsRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(responder);
  return DocumentsRepository(
    apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
  );
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  group('listDocuments (GET /documents)', () {
    test('forme réelle : tableau nu, lignes parsées, route appelée', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return _listResponse([
          {
            'id': 7,
            'nom': 'Bail_42.pdf',
            'type': 'application/pdf',
            'url': '/uploads/2026/09/Bail_42_3f9a.pdf',
            'taille': '245760',
            'categorie': 'baux',
            'entity_type': 'lease',
            'entity_id': 42,
            'created_at': '2026-09-12T10:00:00.000Z',
          },
          {'id': 8, 'nom': 'CNI.jpg', 'categorie': 'inconnue_ancienne'},
        ]);
      });

      final result = await repo.listDocuments() as DocumentsListSuccess;

      expect(seen!.path, '/documents');
      expect(seen!.method, 'GET');
      expect(result.items, hasLength(2));
      expect(result.items.first.categorie, CategorieDocument.bail);
      expect(result.items.first.tailleOctets, 245760);
      expect(result.items.last.categorie, CategorieDocument.autre);
      expect(repo.documents, hasLength(2));
    });

    test('ligne sans id exploitable ou non-objet : ignorée', () async {
      final repo = _repo(
        (options) async => _listResponse([
          {'id': 1, 'nom': 'ok.pdf'},
          {'nom': 'sans id'},
          'pas un objet',
        ]),
      );

      final result = await repo.listDocuments() as DocumentsListSuccess;

      expect(result.items.map((d) => d.id), [1]);
    });

    test('liste vide', () async {
      final repo = _repo((options) async => _listResponse([]));
      final result = await repo.listDocuments() as DocumentsListSuccess;
      expect(result.items, isEmpty);
    });

    test('403 → DocumentsListFailure(forbidden)', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Accès refusé'}, 403),
      );

      final result = await repo.listDocuments() as DocumentsListFailure;

      expect(result.type, ApiExceptionType.forbidden);
    });

    test('500 → DocumentsListFailure(server)', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Erreur serveur'}, 500),
      );

      final result = await repo.listDocuments() as DocumentsListFailure;

      expect(result.type, ApiExceptionType.server);
    });

    test('erreur réseau → DocumentsListFailure(network)', () async {
      final repo = _repo(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repo.listDocuments() as DocumentsListFailure;

      expect(result.type, ApiExceptionType.network);
    });
  });

  group('listQuittancesManuelles (GET /quittances)', () {
    test('forme réelle : tableau nu, montant en chaîne', () async {
      RequestOptions? seen;
      final repo = _repo((options) async {
        seen = options;
        return _listResponse([
          {
            'id': 4,
            'owner_id': 3,
            'lease_id': 42,
            'numero': 'QUI-MAN-2026-0004',
            'locataire_name': 'Yacine Diop',
            'proprietaire_name': 'Mamadou Camara',
            'bien': 'Résidence Palmiers',
            'periode': 'Septembre 2026',
            'montant': '185000.00',
            'date_emission': '2026-09-10T12:00:00.000Z',
            'created_at': '2026-09-10T15:30:00.000Z',
          },
        ]);
      });

      final result =
          await repo.listQuittancesManuelles() as QuittancesManuellesSuccess;

      expect(seen!.path, '/quittances');
      expect(result.items.single.numero, 'QUI-MAN-2026-0004');
      expect(result.items.single.montant, 185000);
      expect(repo.quittancesManuelles, hasLength(1));
    });

    test('403 (finance:read refusée) → Failure(forbidden)', () async {
      final repo = _repo(
        (options) async => jsonResponse({'message': 'Accès refusé'}, 403),
      );

      final result =
          await repo.listQuittancesManuelles() as QuittancesManuellesFailure;

      expect(result.type, ApiExceptionType.forbidden);
    });

    test('erreur réseau → Failure(network)', () async {
      final repo = _repo(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result =
          await repo.listQuittancesManuelles() as QuittancesManuellesFailure;

      expect(result.type, ApiExceptionType.network);
    });
  });
}
