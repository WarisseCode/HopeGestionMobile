import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/locataires/data/locataire_results.dart';
import 'package:hope_gestion_mobile/features/locataires/data/owners_repository.dart';
import 'package:hope_gestion_mobile/features/locataires/models/owner.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> _ownerJson({
  int id = 5,
  String name = 'Camara',
  String? firstName = 'Awa',
  // `COUNT(*)` Postgres renvoyé en chaîne par node-postgres.
  Object? totalProperties = '3',
  Object? totalLots = '12',
}) => {
  'id': id,
  'name': name,
  'first_name': firstName,
  'phone': '+22990000001',
  'email': 'awa@example.com',
  'address': 'Rue 12',
  'city': 'Cotonou',
  'type': 'individual',
  'photo': null,
  'total_properties': totalProperties,
  'total_lots': totalLots,
};

OwnersRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(responder);
  return OwnersRepository(
    apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
  );
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  group('Owner.fromJson', () {
    test('compteurs en chaîne, en entier ou absents', () {
      expect(Owner.fromJson(_ownerJson()).totalProperties, 3);
      expect(Owner.fromJson(_ownerJson()).totalLots, 12);
      expect(Owner.fromJson(_ownerJson(totalProperties: 2)).totalProperties, 2);
      expect(
        Owner.fromJson(_ownerJson(totalProperties: null)).totalProperties,
        isNull,
      );
      expect(Owner.fromJson(_ownerJson(totalLots: 'abc')).totalLots, isNull);
    });

    test('coordonnées, initiales et info', () {
      final owner = Owner.fromJson(_ownerJson());
      expect(owner.phone, '+22990000001');
      expect(owner.email, 'awa@example.com');
      expect(owner.address, 'Rue 12');
      expect(owner.city, 'Cotonou');
      expect(owner.type, 'individual');
      expect(owner.displayName, 'Camara Awa');
      expect(owner.initials, 'CA');
      expect(owner.info, '+22990000001 · 3 biens');
    });

    test('info : singulier, repli sans téléphone ni compteur', () {
      final un = Owner.fromJson({
        'id': 1,
        'name': 'SCI Almadies',
        'total_properties': '1',
      });
      expect(un.info, '1 bien');
      expect(un.initials, 'S');
      expect(Owner.fromJson({'id': 2, 'name': 'X'}).info, 'Propriétaire');
    });

    test('id ou name manquant → FormatException', () {
      expect(
        () => Owner.fromJson({'id': '1', 'name': 'X'}),
        throwsFormatException,
      );
      expect(() => Owner.fromJson({'id': 1}), throwsFormatException);
    });
  });

  group('refresh / list (GET /owners)', () {
    test('refresh : succès, items mis à jour et listeners notifiés', () async {
      final repo = _repo((options) async {
        expect(options.path, '/owners');
        return jsonResponse({
          'success': true,
          'owners': [_ownerJson()],
        }, 200);
      });
      var notified = 0;
      repo.addListener(() => notified++);

      final result = await repo.refresh();

      expect(result, isA<OwnersListSuccess>());
      expect(repo.items, hasLength(1));
      expect(repo.items.first.totalProperties, 3);
      expect(notified, 1);
    });

    test('list : ne modifie pas items (usage sélecteur local)', () async {
      final repo = _repo(
        (_) async => jsonResponse({
          'owners': [_ownerJson()],
        }, 200),
      );

      final result = await repo.list();

      expect((result as OwnersListSuccess).owners, hasLength(1));
      expect(repo.items, isEmpty);
    });

    for (final (status, type) in [
      (401, ApiExceptionType.unauthorized),
      (403, ApiExceptionType.forbidden),
    ]) {
      test('$status → OwnersListFailure($type), items conservés', () async {
        var fail = false;
        final repo = _repo((_) async {
          if (fail) return jsonResponse({'message': 'Refusé'}, status);
          return jsonResponse({
            'owners': [_ownerJson()],
          }, 200);
        });
        await repo.refresh();
        fail = true;

        final result = await repo.refresh();

        expect(result, isA<OwnersListFailure>());
        expect((result as OwnersListFailure).type, type);
        expect(repo.items, hasLength(1));
      });
    }

    test('erreur réseau → OwnersListFailure(network)', () async {
      final repo = _repo((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });

      final result = await repo.refresh();

      expect((result as OwnersListFailure).type, ApiExceptionType.network);
      expect(repo.items, isEmpty);
    });

    test('réponse sans "owners" → OwnersListFailure(unknown)', () async {
      final repo = _repo((_) async => jsonResponse({'success': true}, 200));

      final result = await repo.refresh();

      expect((result as OwnersListFailure).type, ApiExceptionType.unknown);
    });
  });

  group('getDetail (GET /owners/:id)', () {
    test('succès', () async {
      final repo = _repo((options) async {
        expect(options.path, '/owners/5');
        return jsonResponse({
          'success': true,
          'owner': _ownerJson(totalProperties: null, totalLots: null),
          'users': <dynamic>[],
        }, 200);
      });

      final result = await repo.getDetail(5);

      expect((result as OwnerDetailSuccess).owner.displayName, 'Camara Awa');
      expect(repo.items, isEmpty);
    });

    for (final (status, type) in [
      (403, ApiExceptionType.forbidden),
      (404, ApiExceptionType.notFound),
    ]) {
      test('$status → OwnerDetailFailure($type)', () async {
        final repo = _repo(
          (_) async => jsonResponse({'message': 'Erreur'}, status),
        );

        final result = await repo.getDetail(5);

        expect((result as OwnerDetailFailure).type, type);
      });
    }
  });
}
