import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/api_exception.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:hope_gestion_mobile/features/dashboard/models/dashboard_data.dart';
import 'package:hope_gestion_mobile/features/dashboard/data/dashboard_result.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> _kpiJson() => {
  'kpis': <dynamic>[],
  'summary': {
    'totalBiens': 5,
    'totalLots': 20,
    'lotsOccupes': 15,
    'lotsLibres': 5,
    'tauxOccupation': 75,
    'loyersEncaisses': 1500000,
    'loyersImpayes': 200000,
    'contratsActifs': 15,
    'plaintesOuvertes': 2,
    'reservationsEnAttente': 1,
    'montantARecouvrer': 200000,
    'echelonementsEnRetard': 0,
  },
};

Map<String, dynamic> _chartMonthlyJson() => {
  'chartData': [
    {'name': 'Juil', 'revenus': 1200000, 'depenses': 300000},
    {'name': 'Août', 'revenus': 1400000, 'depenses': 350000},
    {'name': 'Sep', 'revenus': 1500000, 'depenses': 400000},
  ],
  'period': '6m',
};

Map<String, dynamic> _chart7dJson() => {
  'chartData': [
    {'name': '17 Sep', 'revenus': 100000, 'depenses': 20000},
    {'name': '18 Sep', 'revenus': 150000, 'depenses': 30000},
    {'name': '23 Sep', 'revenus': 200000, 'depenses': 50000},
  ],
  'period': '7d',
};

Map<String, dynamic> _activityJson() => {
  'activities': [
    {
      'id': 1,
      'type': 'payment',
      'title': 'Paiement reçu',
      'description': 'Yacine Diop - loyer',
      'created_at': '2026-09-20T10:00:00.000Z',
      // NUMERIC renvoyé en chaîne par node-postgres, pas en nombre JSON —
      // voir `_recentRentFromActivity` (`dashboard_data.dart`).
      'montant': '185000.00',
    },
    {
      'id': 2,
      'type': 'contract',
      'title': 'Nouveau bail',
      'description': 'L12 - Fatou Ndiaye',
      'created_at': '2026-09-19T09:00:00.000Z',
    },
    {
      'id': 3,
      'type': 'payment',
      'title': 'Paiement reçu',
      'description': 'M. Camara - caution',
      'created_at': '2026-09-18T08:00:00.000Z',
      'montant': '320000.00',
    },
  ],
};

/// Construit un `DashboardRepository` avec un `ApiClient` piloté par
/// [responder], qui distingue les deux appels `/dashboard/chart-data`
/// (mensuel par défaut vs `?period=7d`) via `options.queryParameters`.
DashboardRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final tokenStorage = TokenStorage();
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(responder);
  final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
  return DashboardRepository(apiClient: apiClient);
}

void main() {
  // TokenStorage/ApiClient ont besoin d'un double du plugin
  // flutter_secure_storage même si ces tests ne touchent jamais au disque
  // (voir token_storage_test.dart).
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  test('load() : succès, les 4 réponses sont combinées correctement', () async {
    final repo = _repo((options) async {
      switch (options.path) {
        case '/dashboard/kpi':
          return jsonResponse(_kpiJson(), 200);
        case '/dashboard/chart-data':
          if (options.queryParameters['period'] == '7d') {
            return jsonResponse(_chart7dJson(), 200);
          }
          return jsonResponse(_chartMonthlyJson(), 200);
        case '/dashboard/activity':
          return jsonResponse(_activityJson(), 200);
      }
      throw UnimplementedError(options.path);
    });

    final result = await repo.load();

    expect(result, isA<DashboardLoadSuccess>());
    final data = (result as DashboardLoadSuccess).data;

    // KPIs : encaissements/impayés depuis /kpi, dépenses dérivées du
    // dernier point (mois courant) de /chart-data mensuel.
    expect(data.encaissements.value, '1 500 000 F');
    expect(data.encaissements.note, 'Ce mois');
    expect(data.depenses.value, '400 000 F');
    expect(data.depenses.note, '27% du CA'); // 400 000 / 1 500 000
    expect(data.impayes.value, '200 000 F');

    // Flux 7 jours : labels et montants réels (pas de pourcentages 0-100).
    expect(data.fluxDays, hasLength(3));
    expect(data.fluxDays[0].label, '17 Sep');
    expect(data.fluxDays[0].inAmount, 100000);
    expect(data.fluxDays[0].outAmount, 20000);
    // Net = (100k+150k+200k) - (20k+30k+50k) = 450k - 100k = 350k.
    expect(data.netFlux, '+350 000 F');

    // Activité récente : uniquement les entrées type=='payment' (2 sur 3),
    // aucun nom de bien inventé — la description réelle du paiement sert de
    // libellé, la date réelle de sous-titre.
    expect(data.recentRents, hasLength(2));
    expect(data.recentRents[0].id, '1');
    expect(data.recentRents[0].property, 'Yacine Diop - loyer');
    expect(data.recentRents[0].amount, '185 000 F');
    expect(data.recentRents[0].amountValue, 185000);
    expect(data.recentRents[0].tenant, '20/09');
    expect(data.recentRents[0].status, 'Payé');
    expect(data.recentRents[1].id, '3');
    expect(data.recentRents[1].amountValue, 320000);
  });

  test(
    'loyer récent : montant NUMERIC en chaîne accepté, absent/illisible → "—"',
    () {
      // `DashboardData.fromApi` directement (pas de round-trip HTTP) : plus
      // simple pour isoler `_recentRentFromActivity`, qui n'est pas exportée.
      final data = DashboardData.fromApi(
        kpi: _kpiJson(),
        chartMonthly: _chartMonthlyJson(),
        chart7d: _chart7dJson(),
        activity: {
          'activities': [
            {
              'id': 1,
              'type': 'payment',
              'description': 'Chaîne (cas réel du serveur)',
              'montant': '185000.00',
            },
            {
              'id': 2,
              'type': 'payment',
              'description': 'Absent',
            },
            {
              'id': 3,
              'type': 'payment',
              'description': 'Illisible',
              'montant': 'abc',
            },
          ],
        },
      );

      expect(data.recentRents[0].amount, '185 000 F');
      expect(data.recentRents[0].amountValue, 185000);
      expect(data.recentRents[1].amount, '—');
      expect(data.recentRents[1].amountValue, 0);
      expect(data.recentRents[2].amount, '—');
      expect(data.recentRents[2].amountValue, 0);
    },
  );

  test('load() : erreur réseau sur un appel → DashboardLoadFailure(network)', () async {
    final repo = _repo((options) async {
      if (options.path == '/dashboard/kpi') {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      // Les autres appels partent en parallèle (Future.wait) : peu importe
      // qu'ils réussissent, la première erreur suffit à faire échouer load().
      switch (options.path) {
        case '/dashboard/chart-data':
          return jsonResponse(
            options.queryParameters['period'] == '7d'
                ? _chart7dJson()
                : _chartMonthlyJson(),
            200,
          );
        case '/dashboard/activity':
          return jsonResponse(_activityJson(), 200);
      }
      throw UnimplementedError(options.path);
    });

    final result = await repo.load();

    expect(result, isA<DashboardLoadFailure>());
    expect((result as DashboardLoadFailure).type, ApiExceptionType.network);
  });

  test('load() : erreur serveur (500) sur un appel → DashboardLoadFailure(server)', () async {
    final repo = _repo((options) async {
      if (options.path == '/dashboard/activity') {
        return jsonResponse({'message': 'Erreur serveur.'}, 500);
      }
      switch (options.path) {
        case '/dashboard/kpi':
          return jsonResponse(_kpiJson(), 200);
        case '/dashboard/chart-data':
          return jsonResponse(
            options.queryParameters['period'] == '7d'
                ? _chart7dJson()
                : _chartMonthlyJson(),
            200,
          );
      }
      throw UnimplementedError(options.path);
    });

    final result = await repo.load();

    expect(result, isA<DashboardLoadFailure>());
    expect((result as DashboardLoadFailure).type, ApiExceptionType.server);
  });
}
