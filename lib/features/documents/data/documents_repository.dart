import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/document.dart';
import 'documents_results.dart';

/// Source de vérité des documents (phase 4.6, étape A — **lecture seule**),
/// même pattern que `FinancesRepository` (constructeur public +
/// `instance`/`initialize`).
///
/// Routes utilisées (celles du web) :
/// - `GET /api/documents` — permission `documents:read`, filtrage
///   propriétaire explicite côté serveur, tableau nu, non paginé ;
/// - `GET /api/quittances` — quittances manuelles, permission
///   **`finance:read`** (et non `documents:read`) : l'une des deux sources
///   peut donc être refusée (403) pendant que l'autre répond.
///
/// Les quittances de paiement (`payments.quittance_url`) ne passent pas par
/// ce dépôt : elles restent dans Finances (voir `ElementDocument`).
class DocumentsRepository extends ChangeNotifier {
  DocumentsRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  static DocumentsRepository? _instance;

  static DocumentsRepository get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'DocumentsRepository.instance accédée avant '
        'DocumentsRepository.initialize().',
      );
    }
    return current;
  }

  static void initialize(DocumentsRepository repository) {
    _instance = repository;
  }

  final ApiClient _apiClient;

  List<Document> _documents = [];
  List<QuittanceManuelle> _quittances = [];

  List<Document> get documents => List.unmodifiable(_documents);
  List<QuittanceManuelle> get quittancesManuelles =>
      List.unmodifiable(_quittances);

  /// `GET /api/documents` → tableau nu, trié par `created_at` décroissant
  /// côté serveur. Une ligne sans `id` exploitable est ignorée.
  Future<DocumentsListResult> listDocuments() async {
    try {
      final response = await _apiClient.request<List<dynamic>>('/documents');
      final raw = response.data;
      if (raw == null) {
        throw const FormatException('Réponse vide de /documents.');
      }
      _documents = raw
          .whereType<Map<String, dynamic>>()
          .map(Document.tryFromJson)
          .whereType<Document>()
          .toList();
      notifyListeners();
      return DocumentsListSuccess(_documents);
    } on ApiException catch (e) {
      return DocumentsListFailure(e.message, e.type);
    } on FormatException catch (e) {
      return DocumentsListFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `GET /api/quittances` → tableau nu (`manual_quittances`), trié par
  /// `created_at` décroissant côté serveur.
  Future<QuittancesManuellesResult> listQuittancesManuelles() async {
    try {
      final response = await _apiClient.request<List<dynamic>>('/quittances');
      final raw = response.data;
      if (raw == null) {
        throw const FormatException('Réponse vide de /quittances.');
      }
      _quittances = raw
          .whereType<Map<String, dynamic>>()
          .map(QuittanceManuelle.tryFromJson)
          .whereType<QuittanceManuelle>()
          .toList();
      notifyListeners();
      return QuittancesManuellesSuccess(_quittances);
    } on ApiException catch (e) {
      return QuittancesManuellesFailure(e.message, e.type);
    } on FormatException catch (e) {
      return QuittancesManuellesFailure(e.message, ApiExceptionType.unknown);
    }
  }
}
