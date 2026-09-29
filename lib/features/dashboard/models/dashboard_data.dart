/// Modèles de données du Dashboard, construits à partir des réponses réelles
/// de `GET /api/dashboard/kpi`, `/chart-data` (deux appels, période mensuelle
/// et 7 jours) et `/activity` — voir `DashboardRepository`. Aucune donnée
/// n'est inventée : tout champ sans équivalent backend a été retiré ou
/// remplacé par une valeur dérivée d'un champ réel (voir commentaires).
library;

class KpiItem {
  final String label;
  final String value;
  final String note;
  final bool isPositive;

  const KpiItem({
    required this.label,
    required this.value,
    required this.note,
    required this.isPositive,
  });
}

/// Un point du graphique « Flux ». [label] est le libellé réel renvoyé par
/// le backend (ex. "23 Sep" en bucket jour, "Jan" en bucket mois) — plus un
/// simple quantième : `/chart-data` peut grouper par jour, semaine ou mois
/// selon la période demandée. [inAmount]/[outAmount] sont les montants réels
/// (F CFA), pas des pourcentages : c'est au widget de les normaliser pour
/// l'affichage.
class FluxDayData {
  final String label;
  final double inAmount;
  final double outAmount;

  const FluxDayData({
    required this.label,
    required this.inAmount,
    required this.outAmount,
  });
}

class RecentRentPayment {
  final String id;
  final String property;
  final String type;
  final String tenant;
  final String amount;

  /// Montant brut (F CFA), pour tout code qui a besoin de la valeur
  /// numérique (ex. `TransactionDetailScreen`) — éviter de reparser [amount]
  /// (chaîne déjà formatée pour l'affichage, ex. "185 000 F").
  final int amountValue;
  final String status;
  final String? imageUrl;

  const RecentRentPayment({
    required this.id,
    required this.property,
    required this.type,
    required this.tenant,
    required this.amount,
    required this.amountValue,
    required this.status,
    this.imageUrl,
  });
}

class DashboardData {
  final KpiItem encaissements;
  final KpiItem depenses;
  final KpiItem impayes;
  final String netFlux;
  final List<FluxDayData> fluxDays;
  final List<RecentRentPayment> recentRents;

  const DashboardData({
    required this.encaissements,
    required this.depenses,
    required this.impayes,
    required this.netFlux,
    required this.fluxDays,
    required this.recentRents,
  });

  /// Construit les données réelles à partir des 4 réponses backend.
  /// Lève une [FormatException] si l'une d'elles n'a pas la forme attendue
  /// (même politique défensive que `AppUser.fromJson`).
  factory DashboardData.fromApi({
    required Map<String, dynamic> kpi,
    required Map<String, dynamic> chartMonthly,
    required Map<String, dynamic> chart7d,
    required Map<String, dynamic> activity,
  }) {
    final summary = kpi['summary'];
    if (summary is! Map<String, dynamic>) {
      throw const FormatException(
        'Réponse de /dashboard/kpi sans champ "summary" exploitable.',
      );
    }
    final loyersEncaisses = _asDouble(summary['loyersEncaisses']);
    final loyersImpayes = _asDouble(summary['loyersImpayes']);

    // "Dépenses" n'a pas d'équivalent dans /kpi : dérivé du dernier point
    // (mois courant) de /chart-data en granularité mensuelle par défaut —
    // même source que "% du CA" ci-dessous, donc cohérents entre eux.
    final monthlyPoints = _chartPointsFrom(chartMonthly);
    final currentMonth = monthlyPoints.isNotEmpty ? monthlyPoints.last : null;
    final depensesMois = currentMonth?.depenses ?? 0;
    final revenusMois = currentMonth?.revenus ?? 0;
    final pctDuCa = revenusMois > 0
        ? (depensesMois / revenusMois * 100).round()
        : 0;

    final weekPoints = _chartPointsFrom(chart7d);
    final fluxDays = weekPoints
        .map(
          (p) => FluxDayData(
            label: p.name,
            inAmount: p.revenus,
            outAmount: p.depenses,
          ),
        )
        .toList();
    final netFluxValue = weekPoints.fold<double>(
      0,
      (sum, p) => sum + p.revenus - p.depenses,
    );

    final rawActivities = activity['activities'];
    if (rawActivities is! List) {
      throw const FormatException(
        'Réponse de /dashboard/activity sans champ "activities" exploitable.',
      );
    }
    final recentRents = rawActivities
        .whereType<Map<String, dynamic>>()
        .where((a) => a['type'] == 'payment')
        .take(5)
        .map(_recentRentFromActivity)
        .toList();

    return DashboardData(
      // Note "Ce mois" plutôt qu'une tendance (%) : /kpi ne renvoie pas le
      // mois précédent, donc pas de variation calculable sans invention.
      encaissements: KpiItem(
        label: 'Encaiss.',
        value: _formatMontant(loyersEncaisses),
        note: 'Ce mois',
        isPositive: true,
      ),
      depenses: KpiItem(
        label: 'Dépenses',
        value: _formatMontant(depensesMois),
        note: '$pctDuCa% du CA',
        isPositive: false,
      ),
      impayes: KpiItem(
        label: 'Impayés',
        value: _formatMontant(loyersImpayes),
        note: 'À recouvrer',
        isPositive: false,
      ),
      netFlux:
          '${netFluxValue >= 0 ? '+' : ''}${_formatMontant(netFluxValue)}',
      fluxDays: fluxDays,
      recentRents: recentRents,
    );
  }
}

class _ChartPoint {
  const _ChartPoint(this.name, this.revenus, this.depenses);
  final String name;
  final double revenus;
  final double depenses;
}

List<_ChartPoint> _chartPointsFrom(Map<String, dynamic> chartResponse) {
  final rawPoints = chartResponse['chartData'];
  if (rawPoints is! List) {
    throw const FormatException(
      'Réponse de /dashboard/chart-data sans champ "chartData" exploitable.',
    );
  }
  return rawPoints.whereType<Map<String, dynamic>>().map((p) {
    return _ChartPoint(
      p['name'] as String? ?? '',
      _asDouble(p['revenus']),
      _asDouble(p['depenses']),
    );
  }).toList();
}

/// `/dashboard/activity` ne renvoie ni bien ni statut de paiement distinct
/// (voir `DashboardService.getActivity`) : contrairement à `property`/
/// `tenant`, on ne fabrique pas ces informations. `property` reçoit la
/// description réelle du paiement (nom du locataire + type), `tenant` la
/// date réelle du paiement, et `status` reste "Payé" — champ honnête, ces
/// entrées sont des paiements déjà enregistrés en base.
RecentRentPayment _recentRentFromActivity(Map<String, dynamic> activity) {
  final description = activity['description'] as String?;
  // `p.montant` (NUMERIC) : node-postgres le sérialise en chaîne
  // (`"185000.00"`), pas en nombre JSON — voir `finance_parsing.dart` pour le
  // même constat côté Finances. `_asDouble` ne distingue pas "manquant" de
  // "0" (renvoie 0 dans les deux cas) : reparse ici pour garder le "—"
  // honnête quand `montant` est réellement absent ou illisible.
  final montantRaw = activity['montant'];
  final montant = switch (montantRaw) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };
  final amountValue = montant?.round() ?? 0;
  final amount = montant != null ? _formatMontant(montant) : '—';
  final createdAt = DateTime.tryParse(activity['created_at'] as String? ?? '');

  return RecentRentPayment(
    id: '${activity['id']}',
    property: (description != null && description.isNotEmpty)
        ? description
        : 'Paiement',
    type: '',
    tenant: createdAt != null ? _formatDateShort(createdAt) : '',
    amount: amount,
    amountValue: amountValue,
    status: 'Payé',
    imageUrl: null,
  );
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

/// "1 560 000 F" — pas de dépendance `intl` pour un simple séparateur de
/// milliers (absente de `pubspec.yaml`, inutile d'ajouter une dépendance
/// pour ce seul besoin).
String _formatMontant(double value) {
  final rounded = value.round();
  final isNegative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${isNegative ? '-' : ''}$buffer F';
}

String _formatDateShort(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}
