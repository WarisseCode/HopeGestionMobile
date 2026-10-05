import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/notifications/data/notifications_repository.dart';
import 'package:hope_gestion_mobile/features/notifications/data/notifications_results.dart';
import 'package:hope_gestion_mobile/features/notifications/models/alerte.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> _alerteJson({
  String id = 'late_12',
  String type = 'Paiement',
  String priorite = 'Haute',
}) => {
  'id': id,
  'reference': 'RET-12',
  'titre': 'Loyer en retard',
  'description': 'Loyer de Diop Yacine (A1 - Horizon) non payé.',
  'destinataire': 'Gestionnaire',
  'type': type,
  'priorite': priorite,
  'dateCreation': '2026-10-05T08:00:00.000Z',
  'statut': 'Active',
  'link': '/dashboard/locations/12',
};

NotificationsRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(responder);
  return NotificationsRepository(
    apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
  );
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  group('AlerteCategorie.fromType', () {
    test('mapping des types backend vers les catégories mobiles', () {
      expect(AlerteCategorie.fromType('Paiement'), AlerteCategorie.impaye);
      expect(AlerteCategorie.fromType('Contrat'), AlerteCategorie.contrat);
      expect(AlerteCategorie.fromType('Intervention'), AlerteCategorie.alerte);
      expect(AlerteCategorie.fromType('Commercial'), AlerteCategorie.alerte);
    });

    test('type inconnu ou absent → alerte générique', () {
      expect(AlerteCategorie.fromType('Autre'), AlerteCategorie.alerte);
      expect(AlerteCategorie.fromType(null), AlerteCategorie.alerte);
    });

    test('aucune catégorie « paiement reçu »', () {
      expect(AlerteCategorie.values.map((c) => c.name), [
        'impaye',
        'contrat',
        'alerte',
      ]);
    });
  });

  group('Alerte.fromJson', () {
    test('lit tous les champs', () {
      final a = Alerte.fromJson(_alerteJson());
      expect(a.id, 'late_12');
      expect(a.type, 'Paiement');
      expect(a.categorie, AlerteCategorie.impaye);
      expect(a.titre, 'Loyer en retard');
      expect(a.description, contains('Diop Yacine'));
      expect(a.reference, 'RET-12');
      expect(a.destinataire, 'Gestionnaire');
      expect(a.priorite, 'Haute');
      expect(a.dateCreation, '2026-10-05T08:00:00.000Z');
      expect(a.statut, 'Active');
      expect(a.link, '/dashboard/locations/12');
    });

    test('champs optionnels absents ou mal typés tolérés', () {
      final a = Alerte.fromJson({'id': 'vac_3', 'titre': 5});
      expect(a.titre, '');
      expect(a.description, '');
      expect(a.priorite, isNull);
      expect(a.dateCreation, isNull);
      expect(a.categorie, AlerteCategorie.alerte);
    });

    test('id absent, vide ou non-chaîne → FormatException', () {
      expect(() => Alerte.fromJson({'titre': 'X'}), throwsFormatException);
      expect(() => Alerte.fromJson({'id': ''}), throwsFormatException);
      expect(() => Alerte.fromJson({'id': 12}), throwsFormatException);
    });
  });

  group('refresh', () {
    test('succès : items, dismissedCount, notification', () async {
      final paths = <String>[];
      final repo = _repo((options) async {
        paths.add('${options.method} ${options.path}');
        return jsonResponse({
          'alerts': [
            _alerteJson(),
            _alerteJson(id: 'exp_4', type: 'Contrat'),
            _alerteJson(id: 'ticket_9', type: 'Intervention'),
          ],
          'dismissedCount': 2,
        }, 200);
      });
      var notified = 0;
      repo.addListener(() => notified++);

      final result = await repo.refresh();

      expect(result, isA<AlertesListSuccess>());
      expect(paths, ['GET /alertes']);
      expect(repo.items.map((a) => a.id), ['late_12', 'exp_4', 'ticket_9']);
      expect(repo.items.map((a) => a.categorie), [
        AlerteCategorie.impaye,
        AlerteCategorie.contrat,
        AlerteCategorie.alerte,
      ]);
      expect(repo.dismissedCount, 2);
      expect(notified, 1);
    });

    test('liste vide et dismissedCount absent → 0', () async {
      final repo = _repo((_) async => jsonResponse({'alerts': []}, 200));
      final result = await repo.refresh();
      expect(result, isA<AlertesListSuccess>());
      expect(repo.items, isEmpty);
      expect(repo.dismissedCount, 0);
    });

    test('réponse sans "alerts" → échec unknown, items conservés', () async {
      var call = 0;
      final repo = _repo((_) async {
        call++;
        return call == 1
            ? jsonResponse({
                'alerts': [_alerteJson()],
              }, 200)
            : jsonResponse({'autre': true}, 200);
      });
      await repo.refresh();
      final result = await repo.refresh();
      expect(result, isA<AlertesListFailure>());
      expect((result as AlertesListFailure).type, ApiExceptionType.unknown);
      expect(repo.items, hasLength(1));
    });

    test('alerte sans id → échec unknown', () async {
      final repo = _repo(
        (_) async => jsonResponse({
          'alerts': [
            {'titre': 'X'},
          ],
        }, 200),
      );
      final result = await repo.refresh();
      expect((result as AlertesListFailure).type, ApiExceptionType.unknown);
    });

    for (final (status, type) in [
      (401, ApiExceptionType.unauthorized),
      (403, ApiExceptionType.forbidden),
      (500, ApiExceptionType.server),
    ]) {
      test('$status → $type', () async {
        final repo = _repo(
          (_) async => jsonResponse({'message': 'Erreur $status'}, status),
        );
        final result = await repo.refresh();
        expect(result, isA<AlertesListFailure>());
        expect((result as AlertesListFailure).type, type);
        expect(result.message, 'Erreur $status');
        expect(repo.items, isEmpty);
      });
    }

    test('réseau → network', () async {
      final repo = _repo(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      final result = await repo.refresh();
      expect((result as AlertesListFailure).type, ApiExceptionType.network);
    });
  });

  group('list', () {
    test('ne modifie pas items', () async {
      final repo = _repo(
        (_) async => jsonResponse({
          'alerts': [_alerteJson()],
          'dismissedCount': 1,
        }, 200),
      );
      final result = await repo.list();
      expect((result as AlertesListSuccess).alertes, hasLength(1));
      expect(result.dismissedCount, 1);
      expect(repo.items, isEmpty);
      expect(repo.dismissedCount, 0);
    });
  });

  group('dismiss', () {
    test('succès : POST encodé, alerte retirée, compteur incrémenté', () async {
      final paths = <String>[];
      final repo = _repo((options) async {
        paths.add('${options.method} ${options.path}');
        if (options.method == 'GET') {
          return jsonResponse({
            'alerts': [_alerteJson(), _alerteJson(id: 'vac 7/b')],
            'dismissedCount': 0,
          }, 200);
        }
        return jsonResponse({'success': true}, 200);
      });
      await repo.refresh();
      var notified = 0;
      repo.addListener(() => notified++);

      final r1 = await repo.dismiss('late_12');
      final r2 = await repo.dismiss('vac 7/b');

      expect(r1, isA<DismissAlerteSuccess>());
      expect(r2, isA<DismissAlerteSuccess>());
      expect(paths, [
        'GET /alertes',
        'POST /alertes/late_12/dismiss',
        'POST /alertes/vac%207%2Fb/dismiss',
      ]);
      expect(repo.items, isEmpty);
      expect(repo.dismissedCount, 2);
      expect(notified, 2);
    });

    for (final (status, type) in [
      (401, ApiExceptionType.unauthorized),
      (403, ApiExceptionType.forbidden),
    ]) {
      test('$status → $type, alerte conservée', () async {
        final repo = _repo((options) async {
          if (options.method == 'GET') {
            return jsonResponse({
              'alerts': [_alerteJson()],
            }, 200);
          }
          return jsonResponse({'message': 'Refus'}, status);
        });
        await repo.refresh();
        final result = await repo.dismiss('late_12');
        expect((result as DismissAlerteFailure).type, type);
        expect(result.message, 'Refus');
        expect(repo.items, hasLength(1));
        expect(repo.dismissedCount, 0);
      });
    }

    test('réseau → network, alerte conservée', () async {
      final repo = _repo((options) async {
        if (options.method == 'GET') {
          return jsonResponse({
            'alerts': [_alerteJson()],
          }, 200);
        }
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      await repo.refresh();
      final result = await repo.dismiss('late_12');
      expect((result as DismissAlerteFailure).type, ApiExceptionType.network);
      expect(repo.items, hasLength(1));
    });
  });

  test('initialize → instance renvoie le même objet', () {
    final repo = _repo((_) async => jsonResponse({'alerts': []}, 200));
    NotificationsRepository.initialize(repo);
    expect(identical(NotificationsRepository.instance, repo), isTrue);
  });
}
