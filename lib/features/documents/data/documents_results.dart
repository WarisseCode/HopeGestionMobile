import '../../../core/network/api_exception.dart';
import '../models/document.dart';

sealed class DocumentsListResult {
  const DocumentsListResult();
}

class DocumentsListSuccess extends DocumentsListResult {
  const DocumentsListSuccess(this.items);
  final List<Document> items;
}

class DocumentsListFailure extends DocumentsListResult {
  const DocumentsListFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class QuittancesManuellesResult {
  const QuittancesManuellesResult();
}

class QuittancesManuellesSuccess extends QuittancesManuellesResult {
  const QuittancesManuellesSuccess(this.items);
  final List<QuittanceManuelle> items;
}

class QuittancesManuellesFailure extends QuittancesManuellesResult {
  const QuittancesManuellesFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

/// Résultats de `DocumentsRepository.creerQuittanceManuelle` — un cas par
/// réaction distincte attendue de `NouvelleQuittanceScreen`
/// (`POST /api/quittances`, `quittanceRoutes.ts`).
sealed class CreerQuittanceManuelleResult {
  const CreerQuittanceManuelleResult();
}

class CreerQuittanceManuelleSuccess extends CreerQuittanceManuelleResult {
  const CreerQuittanceManuelleSuccess(this.quittance);
  final QuittanceManuelle quittance;
}

/// 400 : `lease_id`/`montant`/`periode` invalides. [message] est celui du
/// serveur (`express-validator`), prêt à afficher tel quel.
class CreerQuittanceManuelleValidationFailed
    extends CreerQuittanceManuelleResult {
  const CreerQuittanceManuelleValidationFailed(this.message);
  final String message;
}

/// 403 (aucun propriétaire géré) ou 404 (bail introuvable ou n'appartenant
/// pas à un propriétaire géré) : le formulaire reste affiché, rien n'est
/// perdu.
class CreerQuittanceManuelleBailRefuse extends CreerQuittanceManuelleResult {
  const CreerQuittanceManuelleBailRefuse(this.message);
  final String message;
}

/// Réseau ou délai dépassé : jamais de nouvel envoi automatique côté écran
/// (la quittance a pu être créée malgré l'échec de la réponse).
class CreerQuittanceManuelleNetworkError
    extends CreerQuittanceManuelleResult {
  const CreerQuittanceManuelleNetworkError(this.message);
  final String message;
}

class CreerQuittanceManuelleFailure extends CreerQuittanceManuelleResult {
  const CreerQuittanceManuelleFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}
