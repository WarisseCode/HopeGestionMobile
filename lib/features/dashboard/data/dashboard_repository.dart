import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/dashboard_data.dart';
import 'dashboard_result.dart';

/// Charge les données réelles du Dashboard depuis 4 routes backend
/// (`/dashboard/kpi`, `/dashboard/chart-data` en granularité mensuelle par
/// défaut, `/dashboard/chart-data?period=7d`, `/dashboard/activity`).
///
/// Pas d'état partagé entre écrans (contrairement à `AuthRepository`) : rien
/// dans l'app ne dépend des données du dashboard ailleurs que sur cet écran,
/// et ces données sont sensibles au temps (KPIs, paiements récents) — chaque
/// écran recharge à l'ouverture et au tirer-pour-rafraîchir plutôt que de
/// lire un cache potentiellement périmé.
class DashboardRepository {
  DashboardRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<DashboardResult> load() async {
    final Map<String, dynamic> kpi;
    final Map<String, dynamic> chartMonthly;
    final Map<String, dynamic> chart7d;
    final Map<String, dynamic> activity;
    try {
      final responses = await Future.wait([
        _apiClient.request<Map<String, dynamic>>('/dashboard/kpi'),
        _apiClient.request<Map<String, dynamic>>('/dashboard/chart-data'),
        _apiClient.request<Map<String, dynamic>>(
          '/dashboard/chart-data',
          queryParameters: {'period': '7d'},
        ),
        _apiClient.request<Map<String, dynamic>>('/dashboard/activity'),
      ]);
      kpi = responses[0].data ?? const {};
      chartMonthly = responses[1].data ?? const {};
      chart7d = responses[2].data ?? const {};
      activity = responses[3].data ?? const {};
    } on ApiException catch (e) {
      return DashboardLoadFailure(e.message, e.type);
    }

    try {
      final data = DashboardData.fromApi(
        kpi: kpi,
        chartMonthly: chartMonthly,
        chart7d: chart7d,
        activity: activity,
      );
      return DashboardLoadSuccess(data);
    } on FormatException catch (e) {
      return DashboardLoadFailure(e.message, ApiExceptionType.unknown);
    }
  }
}
