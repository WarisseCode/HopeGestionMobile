import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/depense.dart';
import '../models/depense_validation.dart';
import '../models/echeance.dart';
import '../models/finance_parsing.dart';
import '../models/finance_stats.dart';
import '../models/paiement.dart';
import 'finances_results.dart';

/// Source de vérité des données Finances réelles (phase 4.5), même pattern
/// que `BiensRepository` (constructeur public + `instance`/`initialize`).
///
/// Routes de lecture utilisées — celles de la page Finances du web, pas les
/// doublons `/api/paiements` et `/api/depenses` (montés mais appelés par
/// aucun client) :
/// - `GET /api/finances` (paiements, filtres de période) ;
/// - `GET /api/expenses` (dépenses, filtres de période et d'immeuble) ;
/// - `GET /api/expenses/categories` ;
/// - `GET /api/finances/stats` (synthèse du mois) ;
/// - `GET /api/locations/:id/echeancier` (échéances d'un bail).
///
/// Aucune de ces routes n'est paginée : elles renvoient toute la période
/// demandée, d'où l'intérêt de toujours passer une période.
///
/// **Écriture** :
/// - `PUT /api/finances/schedules/:id/pay` (encaissement par échéance,
///   étape 2/3, T-044) — voir [payerEcheance]. Décision validée : pas de
///   repli sur `POST /api/finances` pour les loyers (deux routes aux effets
///   différents sur les échéances, voir journal T-041/T-042).
/// - `POST /api/expenses` (enregistrement d'une dépense, étape 3/3) — voir
///   [creerDepense].
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

  /// `GET /api/locations/:id/echeancier` → `{ echeancier: [...] }` (colonnes
  /// brutes de `payment_schedules`, voir [Echeance]). Non mis en cache dans
  /// le dépôt (contrairement à [paiements]/[depenses]) : appelé pour un bail
  /// précis, transitoire à l'écran d'encaissement.
  Future<EcheancesListResult> listEcheances(int leaseId) async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/locations/$leaseId/echeancier',
      );
      final raw = response.data?['echeancier'];
      if (raw is! List) {
        throw const FormatException(
          'Réponse de /locations/:id/echeancier sans champ "echeancier" exploitable.',
        );
      }
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(Echeance.fromJson)
          .toList();
      return EcheancesListSuccess(items);
    } on ApiException catch (e) {
      return EcheancesListFailure(e.message, e.type);
    } on FormatException catch (e) {
      return EcheancesListFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `PUT /api/finances/schedules/:id/pay` — encaisse tout ou partie d'une
  /// échéance. Envoie exactement les noms attendus par `payScheduleRules`
  /// (`HopeGestionV2/backend/routes/financeRoutes.ts`) : `montant`,
  /// `mode_paiement`, `date_paiement` (AAAA-MM-JJ), `reference`.
  ///
  /// [montant] omis (`null`) → le serveur encaisse le reste dû ; fourni, il
  /// doit être > 0 et ≤ reste dû sous peine de 400 (non revérifié ici, déjà
  /// imposé par le formulaire). 409 si l'échéance est déjà soldée (verrou en
  /// base côté serveur, double envoi ou mise à jour concurrente).
  Future<PayerEcheanceResult> payerEcheance({
    required int echeanceId,
    double? montant,
    required String modePaiement,
    required String datePaiement,
    String? reference,
  }) async {
    try {
      final body = {
        'montant': ?montant,
        'mode_paiement': modePaiement,
        'date_paiement': datePaiement,
        'reference': ?reference,
      };
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/finances/schedules/$echeanceId/pay',
        method: 'PUT',
        data: body,
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException(
          'Réponse vide de /finances/schedules/:id/pay.',
        );
      }
      return PayerEcheanceSuccess(
        message: (data['message'] as String?) ?? 'Paiement enregistré.',
        soldee: data['soldee'] == true,
        resteDu: asDoubleOrNull(data['reste_du']) ?? 0,
        receiptUrl: data['receiptUrl'] as String?,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 409) return PayerEcheanceDejaSoldee(e.message);
      if (e.type == ApiExceptionType.validation) {
        return PayerEcheanceValidationFailed(e.message);
      }
      return PayerEcheanceFailure(e.message, e.type);
    } on FormatException catch (e) {
      return PayerEcheanceFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `POST /api/expenses` (`expenseRoutes.ts`) — multipart (`FormData`),
  /// champs exactement ceux attendus par `expenseCreateRules` : `amount`,
  /// `date_expense`, `category`, `building_id`, `lot_id`, `owner_id`,
  /// `description`, `supplier_name`, fichier `proof`. Champs vides (`null`)
  /// omis plutôt qu'envoyés vides.
  ///
  /// [buildingId]/[lotId]/[ownerId] : le serveur dérive le propriétaire de
  /// l'immeuble en priorité, puis du lot, puis d'`owner_id` (revérifié côté
  /// serveur contre les propriétaires gérés), sinon 422 — voir le formulaire
  /// (`DepenseScreen`), qui impose toujours l'un des trois avant l'envoi.
  ///
  /// [justificatif] : vérifié contre [validerTailleJustificatif] **avant**
  /// tout appel réseau — le serveur (`uploadMiddleware.ts`) rejette bien un
  /// fichier trop volumineux, mais via un 500 générique sans code dédié (la
  /// route ne définit pas de gestionnaire d'erreur multer/`fileFilter`
  /// spécifique, voir journal), donc pas de moyen fiable de distinguer ce
  /// rejet d'une vraie panne serveur une fois la requête partie.
  Future<CreerDepenseResult> creerDepense({
    required String categorie,
    required double montant,
    required DateTime date,
    String? intitule,
    String? fournisseur,
    int? buildingId,
    int? lotId,
    int? ownerId,
    File? justificatif,
  }) async {
    if (justificatif != null) {
      final octets = await justificatif.length();
      final erreurTaille = validerTailleJustificatif(octets);
      if (erreurTaille != null) {
        return CreerDepenseFichierRefuse(erreurTaille);
      }
    }
    try {
      final proofFile = justificatif != null
          ? await MultipartFile.fromFile(justificatif.path)
          : null;
      final formData = FormData.fromMap({
        'amount': montant,
        'date_expense': formatDateIso(date),
        'category': categorie,
        'building_id': ?buildingId,
        'lot_id': ?lotId,
        'owner_id': ?ownerId,
        'description': ?intitule,
        'supplier_name': ?fournisseur,
        'proof': ?proofFile,
      });
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/expenses',
        method: 'POST',
        data: formData,
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('Réponse vide de /expenses.');
      }
      return CreerDepenseSuccess(Depense.fromJson(data));
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.network || e.type == ApiExceptionType.timeout) {
        return CreerDepenseNetworkError(e.message);
      }
      if (e.type == ApiExceptionType.validation || e.statusCode == 422) {
        return CreerDepenseValidationFailed(e.message);
      }
      return CreerDepenseFailure(e.message, e.type);
    } on FormatException catch (e) {
      return CreerDepenseFailure(e.message, ApiExceptionType.unknown);
    }
  }
}
