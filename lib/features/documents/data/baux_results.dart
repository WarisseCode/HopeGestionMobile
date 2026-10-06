import '../../../core/network/api_exception.dart';
import '../models/bail_detail.dart';
import '../models/bail_resume.dart';
import '../models/nouveau_bail.dart';

/// Résultats de `BauxRepository.creerBail` (`POST /api/locations`) — un cas
/// par réaction distincte attendue de `NouveauContratScreen`.
sealed class CreerBailResult {
  const CreerBailResult();
}

/// 201 : bail créé (statut `actif`, lot passé `occupe` côté serveur).
class CreerBailSuccess extends CreerBailResult {
  const CreerBailSuccess(this.bail);
  final BailCree bail;
}

/// 400 « Ce lot a déjà une affectation active » : un bail actif/signé existe
/// déjà sur ce lot. [message] est celui du serveur.
class CreerBailLotDejaAffecte extends CreerBailResult {
  const CreerBailLotDejaAffecte(this.message);
  final String message;
}

/// Autre 400 (express-validator ou contrôle manuel du handler, ex. loyer
/// manquant). [message] est celui du serveur, prêt à afficher.
class CreerBailValidationFailed extends CreerBailResult {
  const CreerBailValidationFailed(this.message, this.fieldErrors);
  final String message;
  final Map<String, String> fieldErrors;
}

/// 403 : permission `locataires:write` absente, ou `owner_id` envoyé hors
/// des propriétaires gérés (`tenantGuard`).
class CreerBailPermissionRefusee extends CreerBailResult {
  const CreerBailPermissionRefusee(this.message);
  final String message;
}

/// Réseau ou délai dépassé : le bail a pu être créé malgré l'absence de
/// réponse. Jamais de nouvel envoi automatique (backend non transactionnel :
/// un double envoi peut créer deux baux sur le même lot).
class CreerBailNetworkError extends CreerBailResult {
  const CreerBailNetworkError(this.message);
  final String message;
}

/// Tout autre échec (5xx, 401, réponse illisible…).
class CreerBailFailure extends CreerBailResult {
  const CreerBailFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

/// Résultats de `BauxRepository.getBail` (`GET /api/locations/:id`).
sealed class BailDetailResult {
  const BailDetailResult();
}

class BailDetailSuccess extends BailDetailResult {
  const BailDetailSuccess(this.bail);
  final BailDetail bail;
}

/// 404 « Contrat non trouvé ou accès refusé » : bail inexistant **ou** hors
/// périmètre (propriétaire non rattaché) — le serveur ne distingue pas les
/// deux. Relancer ne change rien.
class BailDetailIntrouvable extends BailDetailResult {
  const BailDetailIntrouvable(this.message);
  final String message;
}

/// 403 : permission de module absente. Relancer ne change rien.
class BailDetailAccesRefuse extends BailDetailResult {
  const BailDetailAccesRefuse(this.message);
  final String message;
}

/// Réseau ou délai dépassé : relance possible (lecture idempotente).
class BailDetailNetworkError extends BailDetailResult {
  const BailDetailNetworkError(this.message);
  final String message;
}

/// Tout autre échec (5xx, 401, réponse illisible…).
class BailDetailFailure extends BailDetailResult {
  const BailDetailFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

/// Résultats de `BauxRepository.getBailActifDuLot` (`GET /api/locations`,
/// filtré côté client sur le lot et les statuts `actif`/`signe`).
sealed class BailActifResult {
  const BailActifResult();
}

/// Bail en cours trouvé (le plus récent si plusieurs).
class BailActifTrouve extends BailActifResult {
  const BailActifTrouve(this.bail);
  final BailResume bail;
}

/// Succès : aucun bail `actif`/`signe` sur ce lot (lot vacant, ou bail hors
/// périmètre du compte). Ce n'est pas une erreur.
class LotSansBailActif extends BailActifResult {
  const LotSansBailActif();
}

/// 403 : permission de module absente. Relancer ne change rien.
class BailActifAccesRefuse extends BailActifResult {
  const BailActifAccesRefuse(this.message);
  final String message;
}

/// Réseau ou délai dépassé : relance possible (lecture idempotente).
class BailActifNetworkError extends BailActifResult {
  const BailActifNetworkError(this.message);
  final String message;
}

/// Tout autre échec (5xx, 401, réponse illisible…).
class BailActifFailure extends BailActifResult {
  const BailActifFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

/// Résultats communs aux trois actions sur un bail existant :
/// `BauxRepository.resilierBail` (`POST /locations/:id/resilier`),
/// `renouvelerBail` (`POST /locations/:id/renouveler`) et `signerBail`
/// (`POST /locations/:id/sign`).
///
/// Un seul type scellé plutôt qu'un par action : les trois routes ont
/// exactement les mêmes catégories d'issue et la même réaction attendue
/// côté écran (aucune donnée de réponse n'est exploitée, la fiche est
/// rechargée par `getBail` après succès).
sealed class ActionBailResult {
  const ActionBailResult();
}

/// 2xx : action appliquée côté serveur.
class ActionBailSuccess extends ActionBailResult {
  const ActionBailSuccess();
}

/// 400 (express-validator ou contrôle manuel du handler). [message] est
/// celui du serveur, prêt à afficher.
class ActionBailValidationFailed extends ActionBailResult {
  const ActionBailValidationFailed(this.message, this.fieldErrors);
  final String message;
  final Map<String, String> fieldErrors;
}

/// 403 : permission `locataires:write` absente.
class ActionBailPermissionRefusee extends ActionBailResult {
  const ActionBailPermissionRefusee(this.message);
  final String message;
}

/// Réseau ou délai dépassé : l'action a pu être appliquée malgré l'absence
/// de réponse. Jamais de nouvel envoi automatique (routes non
/// transactionnelles).
class ActionBailNetworkError extends ActionBailResult {
  const ActionBailNetworkError(this.message);
  final String message;
}

/// Tout autre échec (5xx, 404, 401…). Un 5xx peut survenir après un
/// premier UPDATE réussi (routes non transactionnelles).
class ActionBailFailure extends ActionBailResult {
  const ActionBailFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}
