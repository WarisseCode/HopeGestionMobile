import 'depense.dart';
import 'finance_format.dart';
import 'paiement.dart';

/// Ligne de la liste « mouvements du mois » : un paiement (entrée) ou une
/// dépense (sortie). Remplace le modèle mocké `FinanceTransaction` : aucune
/// route ne fusionne entrées et sorties côté serveur (journal T-041), la
/// liste est composée ici à partir de `GET /finances` et `GET /expenses`.
sealed class Mouvement {
  const Mouvement();

  int get id;

  /// Date calendaire du mouvement (`date_paiement` / `date_expense`).
  DateTime get date;

  /// Instant de saisie, pour départager deux mouvements du même jour.
  DateTime? get createdAt;

  /// Montant en valeur absolue.
  double get montant;
  bool get estEntree;

  /// Positif pour une entrée, négatif pour une sortie.
  double get montantSigne => estEntree ? montant : -montant;

  String get titre;
  String get sousTitre;

  /// Paiements et dépenses fusionnés, triés par date décroissante ; à date
  /// égale, par saisie décroissante (sans `created_at` en dernier), puis les
  /// paiements avant les dépenses, puis par identifiant décroissant — ordre
  /// total, donc stable d'un chargement à l'autre.
  static List<Mouvement> fusionner(
    Iterable<Paiement> paiements,
    Iterable<Depense> depenses,
  ) {
    final mouvements = <Mouvement>[
      ...paiements.map(MouvementPaiement.new),
      ...depenses.map(MouvementDepense.new),
    ];
    mouvements.sort(_comparer);
    return mouvements;
  }

  static int _comparer(Mouvement a, Mouvement b) {
    final parDate = b.date.compareTo(a.date);
    if (parDate != 0) return parDate;
    final ca = a.createdAt;
    final cb = b.createdAt;
    if (ca != null && cb != null) {
      final parSaisie = cb.compareTo(ca);
      if (parSaisie != 0) return parSaisie;
    } else if (ca != null || cb != null) {
      return ca != null ? -1 : 1;
    }
    if (a.estEntree != b.estEntree) return a.estEntree ? -1 : 1;
    return b.id.compareTo(a.id);
  }
}

class MouvementPaiement extends Mouvement {
  const MouvementPaiement(this.paiement);

  final Paiement paiement;

  @override
  int get id => paiement.id;
  @override
  DateTime get date => paiement.date;
  @override
  DateTime? get createdAt => paiement.createdAt;
  @override
  double get montant => paiement.montant;
  @override
  bool get estEntree => true;

  /// Le locataire (la réponse ne contient ni lot ni immeuble).
  @override
  String get titre => paiement.locataireNomComplet ?? 'Paiement';

  /// « Loyer · BAIL-2026-008 ».
  @override
  String get sousTitre => [
    libelleTypePaiement(paiement.type),
    paiement.referenceBail,
  ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
}

class MouvementDepense extends Mouvement {
  const MouvementDepense(this.depense);

  final Depense depense;

  @override
  int get id => depense.id;
  @override
  DateTime get date => depense.date;
  @override
  DateTime? get createdAt => depense.createdAt;
  @override
  double get montant => depense.montant;
  @override
  bool get estEntree => false;

  @override
  String get titre => depense.intitule;

  /// « Catégorie · Immeuble · Lot » (catégorie omise si elle sert déjà
  /// d'intitulé).
  @override
  String get sousTitre => [
    if (depense.intitule != depense.categorie) depense.categorie,
    depense.immeubleNom,
    depense.lotReference,
  ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
}
