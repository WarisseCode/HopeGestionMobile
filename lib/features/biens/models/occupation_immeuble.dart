import 'lot.dart';

/// Occupation d'un immeuble recalculée côté mobile à partir des lots
/// **réellement créés** (`BiensRepository.lots` filtrés par immeuble).
///
/// Le calcul serveur (`bienRoutes.ts`) divise par `total_lots` (capacité
/// déclarée) quand elle existe : un immeuble déclaré à 20 lots mais sans
/// aucun lot créé y ressort « Disponible » à 0 %, alors qu'il n'a rien à
/// louer. Ici, aucun lot créé → « Vide ».
class OccupationImmeuble {
  const OccupationImmeuble._({
    required this.lotsCrees,
    required this.lotsOccupes,
    required this.capacitePrevue,
    required this.revenuMensuel,
  });

  factory OccupationImmeuble.fromLots(List<Lot> lots, {int? capacitePrevue}) {
    final occupes = lots.where(estOccupe).toList();
    return OccupationImmeuble._(
      lotsCrees: lots.length,
      lotsOccupes: occupes.length,
      capacitePrevue: (capacitePrevue ?? 0) > 0 ? capacitePrevue : null,
      revenuMensuel: occupes.fold<double>(
        0,
        (sum, lot) => sum + loyerMensuel(lot),
      ),
    );
  }

  /// Même règle que le serveur (`bienRoutes.ts`, `lots_occupes`) et que la
  /// fiche web (`ImmeubleDetailModal.tsx`) : `loue`, `occupe` et `reserve`.
  static bool estOccupe(Lot lot) =>
      const ['loue', 'occupe', 'reserve'].contains(lot.statut.toLowerCase());

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

  /// Somme des loyers mensualisés des lots occupés.
  final double revenuMensuel;

  /// 0-100, sur les lots créés (0 si aucun lot).
  int get pourcentage =>
      lotsCrees == 0 ? 0 : (lotsOccupes * 100 / lotsCrees).round();

  double get ratio => lotsCrees == 0 ? 0 : lotsOccupes / lotsCrees;

  /// Mêmes libellés que `etatOccupation` serveur, pour réutiliser
  /// `EtatOccupationStyle` (T-036).
  String get etat {
    if (lotsCrees == 0) return 'Vide';
    if (lotsOccupes >= lotsCrees) return 'Complet';
    if (lotsOccupes > 0) return 'En location';
    return 'Disponible';
  }

  /// « 0 lot créé · 20 prévus », « 3 lots créés » (capacité égale ou
  /// absente), « 1 lot créé · 1 prévu »…
  String get libelleCapacite {
    final crees = '$lotsCrees lot${lotsCrees > 1 ? 's' : ''} '
        'créé${lotsCrees > 1 ? 's' : ''}';
    final prevue = capacitePrevue;
    if (prevue == null || prevue == lotsCrees) return crees;
    return '$crees · $prevue prévu${prevue > 1 ? 's' : ''}';
  }
}
