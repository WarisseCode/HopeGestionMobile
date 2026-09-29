import '../../../core/network/api_exception.dart';
import '../models/depense.dart';
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
