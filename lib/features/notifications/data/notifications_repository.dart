import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/alerte.dart';
import 'notifications_results.dart';

/// `GET /api/alertes` et `POST /api/alertes/:id/dismiss` — alertes
/// calculées par le serveur (retards de loyer, fins de bail, interventions,
/// lots vacants), affichées par `NotificationsScreen`.
///
/// `GET /api/notifications` n'est volontairement pas utilisé : c'est un
/// journal d'événements sans contenu métier exploitable.
///
/// `DELETE /api/alertes/dismissed` n'est pas exposé : il réinitialise les
/// alertes ignorées (les fait toutes réapparaître), ce qui n'est pas un
/// « tout ignorer ».
class NotificationsRepository extends ChangeNotifier {
  NotificationsRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  static NotificationsRepository? _instance;

  static NotificationsRepository get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'NotificationsRepository.instance accédée avant '
        'NotificationsRepository.initialize().',
      );
    }
    return current;
  }

  static void initialize(NotificationsRepository repository) {
    _instance = repository;
  }

  final ApiClient _apiClient;

  List<Alerte> _items = [];
  int _dismissedCount = 0;

  List<Alerte> get items => List.unmodifiable(_items);

  int get dismissedCount => _dismissedCount;

  /// Lecture ponctuelle, sans effet sur [items].
  Future<AlertesListResult> list() async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/alertes',
      );
      final raw = response.data?['alerts'];
      if (raw is! List) {
        throw const FormatException(
          'Réponse de /alertes sans champ "alerts" exploitable.',
        );
      }
      final alertes = raw
          .whereType<Map<String, dynamic>>()
          .map(Alerte.fromJson)
          .toList();
      final count = response.data?['dismissedCount'];
      return AlertesListSuccess(alertes, count is int ? count : 0);
    } on ApiException catch (e) {
      return AlertesListFailure(e.message, e.type);
    } on FormatException catch (e) {
      return AlertesListFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// [list] puis mise à jour de [items]/[dismissedCount] au succès ; en cas
  /// d'échec, la dernière valeur connue est conservée.
  Future<AlertesListResult> refresh() async {
    final result = await list();
    if (result is AlertesListSuccess) {
      _items = result.alertes;
      _dismissedCount = result.dismissedCount;
      notifyListeners();
    }
    return result;
  }

  /// `POST /alertes/:id/dismiss`. Au succès, l'alerte est retirée de
  /// [items] et [dismissedCount] incrémenté localement (pas de rechargement
  /// complet) ; en cas d'échec, rien ne change.
  Future<DismissAlerteResult> dismiss(String id) async {
    try {
      await _apiClient.request<Map<String, dynamic>>(
        '/alertes/${Uri.encodeComponent(id)}/dismiss',
        method: 'POST',
      );
    } on ApiException catch (e) {
      return DismissAlerteFailure(e.message, e.type);
    }
    final before = _items.length;
    _items = _items.where((a) => a.id != id).toList();
    if (_items.length != before) _dismissedCount++;
    notifyListeners();
    return const DismissAlerteSuccess();
  }
}
