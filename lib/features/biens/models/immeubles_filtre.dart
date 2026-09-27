import 'immeuble.dart';

/// Filtres locaux de la liste Biens, appliqués sur `etatOccupation`
/// (calculé serveur, voir `bienRoutes.ts` : 'Vide' / 'Disponible' /
/// 'En location' / 'Complet'). Aucun appel réseau : la liste complète est
/// déjà chargée par `BiensRepository.listImmeubles`.
enum ImmeublesFiltre {
  tous('Tous'),

  /// Au moins un lot libre : 'Disponible' (aucun lot occupé) **et**
  /// 'En location' (partiellement occupé) — un gestionnaire qui cherche où
  /// placer un locataire veut voir les deux.
  disponibles('Disponibles'),
  complets('Complets'),

  /// Aucun lot déclaré ni créé.
  vides('Vides');

  const ImmeublesFiltre(this.label);

  final String label;

  bool matches(Immeuble immeuble) => switch (this) {
    ImmeublesFiltre.tous => true,
    ImmeublesFiltre.disponibles =>
      immeuble.etatOccupation == 'Disponible' ||
          immeuble.etatOccupation == 'En location',
    ImmeublesFiltre.complets => immeuble.etatOccupation == 'Complet',
    ImmeublesFiltre.vides =>
      immeuble.etatOccupation == 'Vide' || immeuble.etatOccupation == null,
  };
}
