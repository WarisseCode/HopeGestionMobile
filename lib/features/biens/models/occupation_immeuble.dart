import 'lot.dart';
import 'occupation_regles.dart';

/// Occupation d'un immeuble recalculée côté mobile à partir des lots
/// **réellement créés** (`BiensRepository.lots` filtrés par immeuble). Les
/// règles elles-mêmes sont dans [OccupationRegles], partagées avec la carte
/// de liste et les filtres.
class OccupationImmeuble {
  const OccupationImmeuble._({
    required this.lotsCrees,
    required this.lotsOccupes,
    required this.capacitePrevue,
    required this.revenuMensuel,
  });

  factory OccupationImmeuble.fromLots(List<Lot> lots, {int? capacitePrevue}) {
    return OccupationImmeuble._(
      lotsCrees: lots.length,
      lotsOccupes: lots.where(estOccupe).length,
      capacitePrevue: (capacitePrevue ?? 0) > 0 ? capacitePrevue : null,
      revenuMensuel: lots
          .where((lot) => OccupationRegles.estLoue(lot.statut))
          .fold<double>(0, (sum, lot) => sum + loyerMensuel(lot)),
    );
  }

  static bool estOccupe(Lot lot) => OccupationRegles.estOccupe(lot.statut);

  /// Loyer ramené au mois selon `periodicite` (valeurs du formulaire lot :
  /// mensuel / trimestriel / semestriel / annuel ; absent → mensuel).
  static double loyerMensuel(Lot lot) {
    final loyer = lot.loyer ?? 0;
    return switch (lot.periodicite?.toLowerCase()) {
      'trimestriel' => loyer / 3,
      'semestriel' => loyer / 6,
      'annuel' => loyer / 12,
      _ => loyer,
    };
  }

  final int lotsCrees;
  final int lotsOccupes;

  /// Capacité déclarée (`total_lots`) si > 0, sinon `null`.
  final int? capacitePrevue;

  /// Somme des loyers mensualisés des lots loués ou occupés — **sans les
  /// réservés**, qui ne rapportent pas encore de loyer (alors qu'ils
  /// comptent dans le taux d'occupation).
  final double revenuMensuel;

  int get pourcentage => OccupationRegles.pourcentage(
    lotsCrees: lotsCrees,
    lotsOccupes: lotsOccupes,
  );

  double get ratio =>
      OccupationRegles.ratio(lotsCrees: lotsCrees, lotsOccupes: lotsOccupes);

  String get etat =>
      OccupationRegles.etat(lotsCrees: lotsCrees, lotsOccupes: lotsOccupes);

  String get libelleCapacite => OccupationRegles.libelleCapacite(
    lotsCrees: lotsCrees,
    capacitePrevue: capacitePrevue,
  );
}
