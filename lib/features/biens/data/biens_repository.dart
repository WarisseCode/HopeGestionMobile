import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/immeuble.dart';
import '../models/lot.dart';
import 'biens_results.dart';

/// Source de vérité unique pour les immeubles et lots réels, partagée par
/// tous les écrans — même pattern qu'`LocatairesRepository` (constructeur
/// public + `instance`/`initialize`) : les listes sont mutées par plusieurs
/// écrans (liste, détail, création) qui doivent tous voir les mêmes
/// données à jour.
///
/// Coexiste temporairement avec l'ancien `features/biens/models/
/// biens_repository.dart` (mock, `Bien` fusionnant immeuble+lot) : ce
/// dernier reste utilisé par les écrans actuels tant que le point 1
/// (approche du flux de création) n'a pas été validé et que les écrans
/// n'ont pas été réécrits — voir journal.
class BiensRepository extends ChangeNotifier {
  BiensRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  static BiensRepository? _instance;

  static BiensRepository get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'BiensRepository.instance accédée avant BiensRepository.initialize().',
      );
    }
    return current;
  }

  static void initialize(BiensRepository repository) {
    _instance = repository;
  }

  final ApiClient _apiClient;

  List<Immeuble> _immeubles = [];
  List<Lot> _lots = [];

  List<Immeuble> get immeubles => List.unmodifiable(_immeubles);
  List<Lot> get lots => List.unmodifiable(_lots);

  /// `GET /api/biens/immeubles` — pas de pagination côté backend (vérifié
  /// dans `bienRoutes.ts`).
  Future<ImmeublesListResult> listImmeubles() async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/biens/immeubles',
      );
      final raw = response.data?['immeubles'];
      if (raw is! List) {
        throw const FormatException(
          'Réponse de /biens/immeubles sans champ "immeubles" exploitable.',
        );
      }
      _immeubles = raw
          .whereType<Map<String, dynamic>>()
          .map(Immeuble.fromJson)
          .toList();
      notifyListeners();
      return ImmeublesListSuccess(_immeubles);
    } on ApiException catch (e) {
      return ImmeublesListFailure(e.message, e.type);
    } on FormatException catch (e) {
      return ImmeublesListFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `GET /api/biens/lots` — pas de pagination côté backend.
  Future<LotsListResult> listLots() async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/biens/lots',
      );
      final raw = response.data?['lots'];
      if (raw is! List) {
        throw const FormatException(
          'Réponse de /biens/lots sans champ "lots" exploitable.',
        );
      }
      _lots = raw.whereType<Map<String, dynamic>>().map(Lot.fromJson).toList();
      notifyListeners();
      return LotsListSuccess(_lots);
    } on ApiException catch (e) {
      return LotsListFailure(e.message, e.type);
    } on FormatException catch (e) {
      return LotsListFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `POST /api/biens/immeubles` (sans `id` dans le corps → création, voir
  /// `bienRoutes.ts`). Renvoie la ligne complète créée (contrairement à
  /// `LocatairesRepository.create`, qui ne renvoie que `{message, id}`) :
  /// pas besoin de relancer [listImmeubles] pour obtenir un objet à jour,
  /// mais on le fait quand même pour que les agrégats calculés
  /// (`nbLots`/`occupation`/`etatOccupation`) apparaissent dans [immeubles].
  ///
  /// [ownerId] n'est à fournir explicitement que lorsque l'utilisateur gère
  /// plusieurs propriétaires (résolu automatiquement sinon — `tenantGuard
  /// .ts`, même mécanisme que `LocatairesRepository.create`, confirmé lu
  /// génériquement sur `req.body.owner_id` avant même la déstructuration
  /// propre à cette route).
  Future<CreateImmeubleResult> createImmeuble({
    required String nom,
    String? type,
    String? adresse,
    String? ville,
    String? pays,
    String? quartier,
    String? description,
    double? latitude,
    double? longitude,
    int? gestionnaireId,
    String? statut,
    List<String>? photos,
    String? photo,
    String? videoUrl,
    String? planMasseUrl,
    int? nombreEtages,
    int? totalLots,
    int? ownerId,
  }) async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/biens/immeubles',
        method: 'POST',
        data: {
          'nom': nom,
          if (type != null && type.isNotEmpty) 'type': type,
          if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
          if (ville != null && ville.isNotEmpty) 'ville': ville,
          if (pays != null && pays.isNotEmpty) 'pays': pays,
          if (quartier != null && quartier.isNotEmpty) 'quartier': quartier,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (gestionnaireId != null) 'gestionnaire_id': gestionnaireId,
          if (statut != null && statut.isNotEmpty) 'statut': statut,
          if (photos != null && photos.isNotEmpty) 'photos': photos,
          if (photo != null && photo.isNotEmpty) 'photo': photo,
          if (videoUrl != null && videoUrl.isNotEmpty) 'video_url': videoUrl,
          if (planMasseUrl != null && planMasseUrl.isNotEmpty)
            'plan_masse_url': planMasseUrl,
          if (nombreEtages != null) 'nombre_etages': nombreEtages,
          if (totalLots != null) 'total_lots': totalLots,
          if (ownerId != null) 'owner_id': ownerId,
        },
      );
      final id = response.data?['id'];
      if (id is! int) {
        throw const FormatException(
          'Réponse de POST /biens/immeubles sans champ "id" exploitable.',
        );
      }
      await listImmeubles();
      return CreateImmeubleSuccess(id);
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.validation) {
        return CreateImmeubleValidationFailed(e.message, e.fieldErrors);
      }
      return CreateImmeubleFailure(e.message, e.type);
    } on FormatException catch (e) {
      return CreateImmeubleFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `POST /api/biens/lots` (sans `id` dans le corps → création). Un lot
  /// est toujours rattaché à un immeuble existant (400 si [buildingId] ne
  /// résout à rien côté serveur, voir `bienRoutes.ts`) : pas de lot
  /// indépendant possible.
  ///
  /// Peut échouer avec [ApiExceptionType.forbidden] (403) si la limite de
  /// biens du plan d'abonnement est atteinte (`checkPropertyLimit`,
  /// uniquement sur cette route — pas sur `createImmeuble`) : le message
  /// renvoyé par le serveur est déjà directement affichable, d'où l'absence
  /// de variante dédiée dans [CreateLotResult].
  Future<CreateLotResult> createLot({
    required int buildingId,
    required String reference,
    String? type,
    String? etage,
    String? bloc,
    double? superficie,
    int? nbPieces,
    double? loyer,
    double? charges,
    String? periodicite,
    double? caution,
    int? avance,
    double? prixVente,
    String? modaliteVente,
    int? dureeEchelonnement,
    List<String>? photos,
    String? statut,
    String? dateDisponibilite,
    String? description,
  }) async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/biens/lots',
        method: 'POST',
        data: {
          'building_id': buildingId,
          'reference': reference,
          if (type != null && type.isNotEmpty) 'type': type,
          if (etage != null && etage.isNotEmpty) 'etage': etage,
          if (bloc != null && bloc.isNotEmpty) 'bloc': bloc,
          if (superficie != null) 'superficie': superficie,
          if (nbPieces != null) 'nbPieces': nbPieces,
          if (loyer != null) 'loyer': loyer,
          if (charges != null) 'charges': charges,
          if (periodicite != null && periodicite.isNotEmpty)
            'periodicite': periodicite,
          if (caution != null) 'caution': caution,
          if (avance != null) 'avance': avance,
          if (prixVente != null) 'prix_vente': prixVente,
          if (modaliteVente != null && modaliteVente.isNotEmpty)
            'modalite_vente': modaliteVente,
          if (dureeEchelonnement != null)
            'duree_echelonnement': dureeEchelonnement,
          if (photos != null && photos.isNotEmpty) 'photos': photos,
          if (statut != null && statut.isNotEmpty) 'statut': statut,
          if (dateDisponibilite != null && dateDisponibilite.isNotEmpty)
            'date_disponibilite': dateDisponibilite,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      final id = response.data?['id'];
      if (id is! int) {
        throw const FormatException(
          'Réponse de POST /biens/lots sans champ "id" exploitable.',
        );
      }
      await listLots();
      return CreateLotSuccess(id);
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.validation) {
        return CreateLotValidationFailed(e.message, e.fieldErrors);
      }
      return CreateLotFailure(e.message, e.type);
    } on FormatException catch (e) {
      return CreateLotFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `DELETE /api/biens/immeubles/:id` — archivage doux. Refuse avec 409
  /// (`DeleteImmeubleHasLots`) si des lots sont encore rattachés (voir
  /// `bienRoutes.ts` : supprimer les lots d'abord).
  Future<DeleteImmeubleResult> deleteImmeuble(int id) async {
    try {
      await _apiClient.request<void>('/biens/immeubles/$id', method: 'DELETE');
      _immeubles = _immeubles.where((i) => i.id != id).toList();
      notifyListeners();
      return const DeleteImmeubleSuccess();
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return DeleteImmeubleHasLots(e.message);
      }
      return DeleteImmeubleFailure(e.message, e.type);
    }
  }

  /// `DELETE /api/biens/lots/:id` — archivage doux.
  Future<DeleteLotResult> deleteLot(int id) async {
    try {
      await _apiClient.request<void>('/biens/lots/$id', method: 'DELETE');
      _lots = _lots.where((l) => l.id != id).toList();
      notifyListeners();
      return const DeleteLotSuccess();
    } on ApiException catch (e) {
      return DeleteLotFailure(e.message, e.type);
    }
  }
}
