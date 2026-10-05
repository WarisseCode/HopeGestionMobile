import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../finances/models/finance_parsing.dart' show formatDateIso;
import '../models/nouveau_bail.dart';
import 'baux_results.dart';

/// Création de baux (`POST /api/locations`, HopeGestionV2
/// `backend/routes/leaseRoutes.ts`) — même pattern que `OwnersRepository`/
/// `LocatairesRepository` (constructeur public + `instance`/`initialize`).
///
/// Périmètre : location uniquement (`type_contrat: 'location'`), paiement
/// classique (`type_paiement: 'classique'`, jamais d'échéancier généré à la
/// création). Ni PDF ni échéancier ici.
class BauxRepository extends ChangeNotifier {
  BauxRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  static BauxRepository? _instance;

  static BauxRepository get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'BauxRepository.instance accédée avant BauxRepository.initialize().',
      );
    }
    return current;
  }

  static void initialize(BauxRepository repository) {
    _instance = repository;
  }

  final ApiClient _apiClient;

  /// Message exact renvoyé par le serveur quand un bail `actif`/`signe`
  /// existe déjà sur le lot (`leaseRoutes.ts`).
  static const _messageLotDejaAffecte = 'déjà une affectation active';

  /// `POST /api/locations`.
  ///
  /// - [ownerId] : **obligatoire** — le serveur ne le déduit pas du lot
  ///   (`tenantGuard` le lit dans `req.body.owner_id` ; omis pour un
  ///   gestionnaire multi-propriétaires, le bail serait créé avec
  ///   `owner_id` NULL, sans erreur).
  /// - `date_fin` calculée ici ([calculerDateFinBail]) : le serveur ne la
  ///   déduit pas de `duree_contrat`.
  /// - `avance` envoyée **en nombre de mois** ([avanceMois] brut, tel que
  ///   saisi), comme le web (`AssignmentForm.tsx` envoie `form.avance`
  ///   sans conversion). Aucune conversion FCFA n'est envoyée.
  /// - `jour_echeance` toujours envoyé (défaut serveur 1 sinon).
  Future<CreerBailResult> creerBail({
    required int tenantId,
    required int lotId,
    required int ownerId,
    required DateTime dateDebut,
    required int dureeMois,
    required double loyerMensuel,
    required double caution,
    required int avanceMois,
    required double chargesMensuelles,
    required int jourEcheance,
    String? conditionsParticulieres,
  }) async {
    final conditions = conditionsParticulieres?.trim() ?? '';
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/locations',
        method: 'POST',
        data: {
          'tenant_id': tenantId,
          'lot_id': lotId,
          'owner_id': ownerId,
          'type_contrat': 'location',
          'type_paiement': 'classique',
          'date_debut': formatDateIso(dateDebut),
          'duree_contrat': dureeMois,
          'date_fin': formatDateIso(calculerDateFinBail(dateDebut, dureeMois)),
          'loyer_mensuel': loyerMensuel,
          'caution': caution,
          'avance': avanceMois,
          'charges_mensuelles': chargesMensuelles,
          'jour_echeance': jourEcheance,
          if (conditions.isNotEmpty) 'conditions_particulieres': conditions,
        },
      );
      final data = response.data;
      final bail = data == null ? null : BailCree.tryFromJson(data);
      if (bail == null) {
        // 2xx reçu : le bail existe très probablement côté serveur.
        return const CreerBailFailure(
          'Le bail a probablement été créé, mais la réponse du serveur est '
          'illisible. Vérifiez avant de ressaisir.',
          ApiExceptionType.unknown,
        );
      }
      notifyListeners();
      return CreerBailSuccess(bail);
    } on ApiException catch (e) {
      if (e.statusCode == 400 && e.message.contains(_messageLotDejaAffecte)) {
        return CreerBailLotDejaAffecte(e.message);
      }
      if (e.type == ApiExceptionType.validation) {
        return CreerBailValidationFailed(e.message, e.fieldErrors);
      }
      if (e.type == ApiExceptionType.forbidden) {
        return CreerBailPermissionRefusee(e.message);
      }
      if (e.type == ApiExceptionType.network ||
          e.type == ApiExceptionType.timeout) {
        return CreerBailNetworkError(e.message);
      }
      return CreerBailFailure(e.message, e.type);
    }
  }
}
