/// Règles d'occupation d'un immeuble — **seul endroit** où elles sont
/// définies. Utilisées par la fiche (`OccupationImmeuble`, à partir des lots
/// chargés), la carte de liste et les filtres (`Immeuble`, à partir de
/// `lotsCrees`/`lotsOccupes` renvoyés par le serveur) : un même immeuble
/// affiche donc le même état partout.
///
/// Toutes les règles portent sur les lots **réellement créés**, jamais sur
/// la capacité déclarée (`total_lots`). Le serveur (`bienRoutes.ts`) calcule
/// encore `etatOccupation` Complet / En location / Disponible sur la
/// capacité : ce champ n'est plus utilisé côté mobile.
abstract final class OccupationRegles {
  /// Statuts comptés comme occupés pour le taux et l'état : même règle que
  /// le serveur (`lots_occupes`) et la fiche web (`ImmeubleDetailModal.tsx`).
  static const statutsOccupes = ['loue', 'occupe', 'reserve'];

  /// Statuts qui produisent un loyer : un lot réservé n'en rapporte pas
  /// encore, il est exclu du revenu mensuel.
  static const statutsLoues = ['loue', 'occupe'];

  static bool estOccupe(String statut) =>
      statutsOccupes.contains(statut.toLowerCase());

  static bool estLoue(String statut) =>
      statutsLoues.contains(statut.toLowerCase());

  /// 'Vide' / 'Disponible' / 'En location' / 'Complet' — mêmes libellés que
  /// `etatOccupation` serveur, pour réutiliser `EtatOccupationStyle`.
  static String etat({required int lotsCrees, required int lotsOccupes}) {
    if (lotsCrees <= 0) return 'Vide';
    if (lotsOccupes >= lotsCrees) return 'Complet';
    if (lotsOccupes > 0) return 'En location';
    return 'Disponible';
  }

  /// 0-1, borné (un comptage serveur incohérent ne dépasse jamais 100 %).
  static double ratio({required int lotsCrees, required int lotsOccupes}) =>
      lotsCrees <= 0 ? 0 : (lotsOccupes / lotsCrees).clamp(0.0, 1.0);

  /// 0-100, arrondi.
  static int pourcentage({required int lotsCrees, required int lotsOccupes}) =>
      (ratio(lotsCrees: lotsCrees, lotsOccupes: lotsOccupes) * 100).round();

  /// « 0 lot créé · 20 prévus », « 3 lots créés » (capacité égale, nulle ou
  /// absente), « 1 lot créé · 1 prévu »…
  static String libelleCapacite({required int lotsCrees, int? capacitePrevue}) {
    final crees =
        '$lotsCrees lot${lotsCrees > 1 ? 's' : ''} '
        'créé${lotsCrees > 1 ? 's' : ''}';
    if (capacitePrevue == null ||
        capacitePrevue <= 0 ||
        capacitePrevue == lotsCrees) {
      return crees;
    }
    return '$crees · $capacitePrevue prévu${capacitePrevue > 1 ? 's' : ''}';
  }
}
