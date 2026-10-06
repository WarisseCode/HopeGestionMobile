import '../../../core/network/api_exception.dart';
import '../models/bail_detail.dart';
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
