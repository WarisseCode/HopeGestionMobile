import 'immeuble.dart';

/// Filtres locaux de la liste Biens, appliqués sur [Immeuble.etat] — l'état
/// calculé sur les lots créés (`OccupationRegles`), le même que celui de la
/// carte et de la fiche détail, et non `etatOccupation` serveur (calculé sur
/// la capacité déclarée). Aucun appel réseau : la liste complète est déjà
/// chargée par `BiensRepository.listImmeubles`.
enum ImmeublesFiltre {
  tous('Tous'),

  /// Au moins un lot libre : 'Disponible' (aucun lot occupé) **et**
  /// 'En location' (partiellement occupé) — un gestionnaire qui cherche où
  /// placer un locataire veut voir les deux.
  disponibles('Disponibles'),
  complets('Complets'),

  /// Aucun lot créé (même avec une capacité déclarée).
  vides('Vides');

  const ImmeublesFiltre(this.label);

  final String label;

  bool matches(Immeuble immeuble) => switch (this) {
    ImmeublesFiltre.tous => true,
    ImmeublesFiltre.disponibles =>
      immeuble.etat == 'Disponible' || immeuble.etat == 'En location',
    ImmeublesFiltre.complets => immeuble.etat == 'Complet',
    ImmeublesFiltre.vides => immeuble.etat == 'Vide',
  };
}
