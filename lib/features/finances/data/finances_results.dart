import '../../../core/network/api_exception.dart';
import '../models/depense.dart';
import '../models/echeance.dart';
import '../models/finance_stats.dart';
import '../models/paiement.dart';

sealed class PaiementsListResult {
  const PaiementsListResult();
}

class PaiementsListSuccess extends PaiementsListResult {
  const PaiementsListSuccess(this.items);
  final List<Paiement> items;
}

class PaiementsListFailure extends PaiementsListResult {
  const PaiementsListFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class PaiementResult {
  const PaiementResult();
}

class PaiementTrouve extends PaiementResult {
  const PaiementTrouve(this.paiement);
  final Paiement paiement;
}

class PaiementIntrouvable extends PaiementResult {
  const PaiementIntrouvable();
}

class PaiementFailure extends PaiementResult {
  const PaiementFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class DepensesListResult {
  const DepensesListResult();
}

class DepensesListSuccess extends DepensesListResult {
  const DepensesListSuccess(this.items);
  final List<Depense> items;
}

class DepensesListFailure extends DepensesListResult {
  const DepensesListFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class CategoriesDepenseResult {
  const CategoriesDepenseResult();
}

class CategoriesDepenseSuccess extends CategoriesDepenseResult {
  const CategoriesDepenseSuccess(this.items);
  final List<CategorieDepense> items;
}

class CategoriesDepenseFailure extends CategoriesDepenseResult {
  const CategoriesDepenseFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class FinanceStatsResult {
  const FinanceStatsResult();
}

class FinanceStatsSuccess extends FinanceStatsResult {
  const FinanceStatsSuccess(this.stats);
  final FinanceStats stats;
}

class FinanceStatsFailure extends FinanceStatsResult {
  const FinanceStatsFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class EcheancesListResult {
  const EcheancesListResult();
}

class EcheancesListSuccess extends EcheancesListResult {
  const EcheancesListSuccess(this.items);
  final List<Echeance> items;
}

class EcheancesListFailure extends EcheancesListResult {
  const EcheancesListFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

/// Résultats de `FinancesRepository.payerEcheance` — un cas par réaction
/// distincte attendue de l'écran (`PUT /api/finances/schedules/:id/pay`,
/// `FinanceService.paySchedule`, HopeGestionV2 T-006/T-007).
sealed class PayerEcheanceResult {
  const PayerEcheanceResult();
}

class PayerEcheanceSuccess extends PayerEcheanceResult {
  const PayerEcheanceSuccess({
    required this.message,
    required this.soldee,
    required this.resteDu,
    this.receiptUrl,
  });

  /// Message du serveur : « Échéance marquée comme payée » ou « Acompte
  /// enregistré » selon [soldee].
  final String message;
  final bool soldee;
  final double resteDu;

  /// Non `null` uniquement quand [soldee] est vrai (quittance générée au
  /// solde seulement, voir T-006).
  final String? receiptUrl;
}

/// 400 : montant invalide (nul, négatif, ou supérieur au reste dû), date
/// invalide... [message] est celui du serveur, prêt à afficher tel quel.
class PayerEcheanceValidationFailed extends PayerEcheanceResult {
  const PayerEcheanceValidationFailed(this.message);
  final String message;
}

/// 409 : l'échéance est déjà soldée (double envoi, mise à jour concurrente).
class PayerEcheanceDejaSoldee extends PayerEcheanceResult {
  const PayerEcheanceDejaSoldee(this.message);
  final String message;
}

class PayerEcheanceFailure extends PayerEcheanceResult {
  const PayerEcheanceFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}
