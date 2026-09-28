import 'finance_parsing.dart';

/// Synthèse mensuelle `GET /api/finances/stats?month=&year=`
/// (`FinanceService.getStats`, `HopeGestionV2/backend`).
///
/// Attention aux définitions serveur :
/// - [encaisse] : somme des paiements de statut `'valide'` du mois
///   (`date_paiement`), toutes routes d'enregistrement confondues ;
/// - [depenses] : somme des dépenses du mois (`date_expense`) ;
/// - [soldeNet] : `encaisse - depenses` (pas un solde de trésorerie
///   cumulé) ;
/// - [resteAEncaisser] : reste dû des échéances du mois de statut
///   `pending`/`partial`/`overdue` — colonne `status` uniquement (une
///   échéance soldée via `POST /api/paiements`, qui écrit la colonne
///   `statut`, y figure donc encore).
class FinanceStats {
  const FinanceStats({
    required this.encaisse,
    required this.depenses,
    required this.soldeNet,
    required this.resteAEncaisser,
  });

  factory FinanceStats.fromJson(Map<String, dynamic> json) => FinanceStats(
    encaisse: asDoubleOrNull(json['encashed_month']) ?? 0,
    depenses: asDoubleOrNull(json['expenses_month']) ?? 0,
    soldeNet: asDoubleOrNull(json['net_balance']) ?? 0,
    resteAEncaisser: asDoubleOrNull(json['pending_total']) ?? 0,
  );

  static const FinanceStats zero = FinanceStats(
    encaisse: 0,
    depenses: 0,
    soldeNet: 0,
    resteAEncaisser: 0,
  );

  final double encaisse;
  final double depenses;
  final double soldeNet;
  final double resteAEncaisser;
}
