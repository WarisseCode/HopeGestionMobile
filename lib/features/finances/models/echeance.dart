import 'finance_parsing.dart';

/// État d'une échéance, calculé côté client selon la **même règle qu'au
/// backend** (`FinanceService.paySchedule`, `FinanceSchedules.tsx` du web) :
/// soldée si `status = paid` OU `statut = paye` OU `amount_paid >= total_amount` ;
/// acompte si non soldée et (`status = partial` OU `statut = partiel` OU
/// `amount_paid > 0`) ; sinon à payer.
///
/// **Priorité retenue quand plusieurs conditions se recoupent** (non
/// spécifiée par le backend, choix fait ici) : `payee` > `enRetard` >
/// `acompte` > `aPayer`. Une échéance en acompte et en retard est donc
/// classée `enRetard` — juger le retard prioritaire sur l'acompte déjà
/// versé semble le signal le plus utile pour le gestionnaire. Le montant
/// déjà versé reste affichable indépendamment de cet état via
/// [Echeance.montantPaye]/[Echeance.resteDu], donc l'information n'est pas
/// perdue : seul le badge affiché en priorité change.
enum EtatEcheance { payee, enRetard, acompte, aPayer }

/// Échéance de loyer, telle que renvoyée par `GET /api/locations/:id/echeancier`
/// (`SELECT * FROM payment_schedules`, `HopeGestionV2/backend/routes/leaseRoutes.ts`).
///
/// NUMERIC (`total_amount`, `amount_paid`) en chaîne, `DATE` (`due_date`) en
/// instant ISO — voir `finance_parsing.dart`. `numero_echeance` est
/// systématiquement `NULL` en pratique : ni la génération à la création du
/// bail (`generatePaymentSchedule`) ni la génération mensuelle
/// (`FinanceService.generateMonthlySchedules`) ne le renseignent — le tri
/// se fait donc sur `due_date`, jamais sur ce champ.
class Echeance {
  const Echeance({
    required this.id,
    required this.total,
    this.leaseId,
    this.montantPaye = 0,
    this.dateEcheance,
    this.status,
    this.statut,
    this.description,
  });

  /// `id` et `total_amount` indispensables → `FormatException` ; le reste
  /// est optionnel (même politique que `Paiement.fromJson`).
  factory Echeance.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final total = asDoubleOrNull(json['total_amount']);
    if (id is! int || total == null) {
      throw const FormatException(
        'Échéance au format inattendu (id ou total_amount manquant).',
      );
    }
    return Echeance(
      id: id,
      total: total,
      leaseId: asIntOrNull(json['lease_id']),
      montantPaye: asDoubleOrNull(json['amount_paid']) ?? 0,
      dateEcheance: asDateOrNull(json['due_date']),
      status: json['status'] as String?,
      statut: json['statut'] as String?,
      description: json['description'] as String?,
    );
  }

  final int id;
  final int? leaseId;
  final double total;
  final double montantPaye;

  /// Date calendaire d'échéance (colonne `DATE`, sans heure) ; `null` si non
  /// renseignée en base.
  final DateTime? dateEcheance;
  final String? status;
  final String? statut;
  final String? description;

  /// Reste dû, jamais négatif (un trop-perçu donne 0, pas une valeur négative).
  double get resteDu {
    final reste = total - montantPaye;
    return reste <= 0 ? 0 : reste;
  }

  bool get estSoldee =>
      status == 'paid' || statut == 'paye' || (total > 0 && montantPaye >= total);

  bool get estAcompte =>
      !estSoldee && (status == 'partial' || statut == 'partiel' || montantPaye > 0);

  /// Non soldée et date d'échéance strictement avant aujourd'hui (comparaison
  /// calendaire, pas horaire : une échéance due aujourd'hui n'est pas
  /// encore « en retard »). [maintenant] injectable pour les tests.
  bool estEnRetard({DateTime? maintenant}) {
    final due = dateEcheance;
    if (estSoldee || due == null) return false;
    final now = maintenant ?? DateTime.now();
    final aujourdhui = DateTime(now.year, now.month, now.day);
    return due.isBefore(aujourdhui);
  }

  EtatEcheance etat({DateTime? maintenant}) {
    if (estSoldee) return EtatEcheance.payee;
    if (estEnRetard(maintenant: maintenant)) return EtatEcheance.enRetard;
    if (estAcompte) return EtatEcheance.acompte;
    return EtatEcheance.aPayer;
  }
}
