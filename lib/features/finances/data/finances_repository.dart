import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/depense.dart';
import '../models/finance_parsing.dart';
import '../models/finance_stats.dart';
import '../models/paiement.dart';
import 'finances_results.dart';

/// Source de vérité des données Finances réelles (phase 4.5), même pattern
/// que `BiensRepository` (constructeur public + `instance`/`initialize`).
///
/// **Lecture seule pour l'instant** : seules les routes de lecture sont
/// certaines après le diagnostic (journal T-041). Les écritures
/// (encaissement, dépense) attendent la validation du périmètre : il existe
/// trois routes d'enregistrement de paiement aux effets différents sur les
/// échéances, voir journal.
///
/// Routes utilisées — celles de la page Finances du web, pas les doublons
/// `/api/paiements` et `/api/depenses` (montés mais appelés par aucun
/// client) :
/// - `GET /api/finances` (paiements, filtres de période) ;
/// - `GET /api/expenses` (dépenses, filtres de période et d'immeuble) ;
/// - `GET /api/expenses/categories` ;
/// - `GET /api/finances/stats` (synthèse du mois).
///
/// Aucune de ces routes n'est paginée : elles renvoient toute la période
/// demandée, d'où l'intérêt de toujours passer une période.
class FinancesRepository extends ChangeNotifier {
  FinancesRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  static FinancesRepository? _instance;

  static FinancesRepository get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'FinancesRepository.instance accédée avant '
        'FinancesRepository.initialize().',
      );
    }
    return current;
  }

  static void initialize(FinancesRepository repository) {
    _instance = repository;
  }

  final ApiClient _apiClient;

  List<Paiement> _paiements = [];
  List<Depense> _depenses = [];
  List<CategorieDepense> _categories = [];

  List<Paiement> get paiements => List.unmodifiable(_paiements);
  List<Depense> get depenses => List.unmodifiable(_depenses);
  List<CategorieDepense> get categories => List.unmodifiable(_categories);

  /// Bornes incluses (`date_paiement >= start_date AND <= end_date`).
  static Map<String, dynamic>? _periode(DateTime? debut, DateTime? fin) {
    final params = <String, dynamic>{
      if (debut != null) 'start_date': formatDateIso(debut),
      if (fin != null) 'end_date': formatDateIso(fin),
    };
    return params.isEmpty ? null : params;
  }

  /// `GET /api/finances` → `{ payments: [...] }`, trié par date décroissante
  /// côté serveur.
  Future<PaiementsListResult> listPaiements({
    DateTime? debut,
    DateTime? fin,
    int? leaseId,
  }) async {
    try {
      final query = {
        ...?_periode(debut, fin),
        'lease_id': ?leaseId,
      };
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/finances',
        queryParameters: query.isEmpty ? null : query,
      );
      final raw = response.data?['payments'];
      if (raw is! List) {
        throw const FormatException(
          'Réponse de /finances sans champ "payments" exploitable.',
        );
      }
      _paiements = raw
          .whereType<Map<String, dynamic>>()
          .map(Paiement.fromJson)
          .toList();
      notifyListeners();
      return PaiementsListSuccess(_paiements);
    } on ApiException catch (e) {
      return PaiementsListFailure(e.message, e.type);
    } on FormatException catch (e) {
      return PaiementsListFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// Un paiement par identifiant — pour le tableau de bord, qui ne connaît
  /// que l'`id` des paiements récents (`/dashboard/activity`).
  ///
  /// Le backend n'a **pas** de route `GET /api/finances/:id` : on cherche
  /// d'abord dans les paiements déjà chargés, sinon on relit
  /// `GET /api/finances` **sans période** (toute la liste, non paginée) et
  /// on y cherche l'identifiant, sans remplacer [paiements] (la liste du
  /// mois affichée par l'écran Finances).
  Future<PaiementResult> findPaiement(int id) async {
    for (final p in _paiements) {
      if (p.id == id) return PaiementTrouve(p);
    }
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/finances',
      );
      final raw = response.data?['payments'];
      if (raw is! List) {
        throw const FormatException(
          'Réponse de /finances sans champ "payments" exploitable.',
        );
      }
      for (final json in raw.whereType<Map<String, dynamic>>()) {
        if (json['id'] == id) return PaiementTrouve(Paiement.fromJson(json));
      }
      return const PaiementIntrouvable();
    } on ApiException catch (e) {
      return PaiementFailure(e.message, e.type);
    } on FormatException catch (e) {
      return PaiementFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `GET /api/expenses` → **tableau nu** (pas d'objet enveloppe,
  /// contrairement à `/finances`), trié par date décroissante côté serveur.
  Future<DepensesListResult> listDepenses({
    DateTime? debut,
    DateTime? fin,
    int? buildingId,
  }) async {
    try {
      final query = {
        ...?_periode(debut, fin),
        'building_id': ?buildingId,
      };
      final response = await _apiClient.request<List<dynamic>>(
        '/expenses',
        queryParameters: query.isEmpty ? null : query,
      );
      final raw = response.data;
      if (raw == null) {
        throw const FormatException('Réponse vide de /expenses.');
      }
      _depenses = raw
          .whereType<Map<String, dynamic>>()
          .map(Depense.fromJson)
          .toList();
      notifyListeners();
      return DepensesListSuccess(_depenses);
    } on ApiException catch (e) {
      return DepensesListFailure(e.message, e.type);
    } on FormatException catch (e) {
      return DepensesListFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `GET /api/expenses/categories` → tableau nu, trié par nom côté serveur.
  Future<CategoriesDepenseResult> listCategoriesDepense() async {
    try {
      final response = await _apiClient.request<List<dynamic>>(
        '/expenses/categories',
      );
      final raw = response.data;
      if (raw == null) {
        throw const FormatException('Réponse vide de /expenses/categories.');
      }
      _categories = raw
          .whereType<Map<String, dynamic>>()
          .map(CategorieDepense.fromJson)
          .toList();
      notifyListeners();
      return CategoriesDepenseSuccess(_categories);
    } on ApiException catch (e) {
      return CategoriesDepenseFailure(e.message, e.type);
    } on FormatException catch (e) {
      return CategoriesDepenseFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `GET /api/finances/stats?month=&year=` (mois courant par défaut côté
  /// serveur si absents). Voir [FinanceStats] pour les définitions exactes.
  Future<FinanceStatsResult> getStats({int? mois, int? annee}) async {
    try {
      final query = {
        'month': ?mois,
        'year': ?annee,
      };
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/finances/stats',
        queryParameters: query.isEmpty ? null : query,
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('Réponse vide de /finances/stats.');
      }
      return FinanceStatsSuccess(FinanceStats.fromJson(data));
    } on ApiException catch (e) {
      return FinanceStatsFailure(e.message, e.type);
    } on FormatException catch (e) {
      return FinanceStatsFailure(e.message, ApiExceptionType.unknown);
    }
  }
}
