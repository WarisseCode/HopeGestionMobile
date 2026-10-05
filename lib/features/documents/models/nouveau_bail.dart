/// Règles et calculs du parcours de création d'un bail
/// (`POST /api/locations`, HopeGestionV2 `backend/routes/leaseRoutes.ts`),
/// en fonctions pures partagées par `BauxRepository` (construction du corps
/// de requête) et `NouveauContratScreen` (affichage avant confirmation) :
/// l'utilisateur voit exactement les valeurs qui seront envoyées.
library;

/// Longueur maximale **côté client** de `conditions_particulieres`.
///
/// `leaseCreateRules` (express-validator) ne contient **aucune** règle sur ce
/// champ — ni type, ni longueur — et la colonne n'apparaît dans aucun
/// fichier SQL versionné du backend (absente de `db/init.sql` et des
/// migrations) : aucune limite serveur vérifiable. Cette borne est donc un
/// garde-fou d'ergonomie propre au mobile (texte libre court qui remplace
/// l'ancien sélecteur de type de bail), pas un contrat backend.
const int conditionsParticulieresMaxLength = 2000;

/// Jour d'échéance par défaut — celui qu'envoie le web
/// (`AssignmentForm.tsx`), et non le défaut serveur (1) appliqué quand le
/// champ est omis : d'où un envoi toujours explicite.
const int jourEcheanceParDefaut = 5;

/// Durée par défaut d'un bail, en mois (même valeur que le web).
const int dureeBailParDefautMois = 12;

/// [debut] + [mois] mois civils. Le jour est ramené au dernier jour du mois
/// cible s'il n'y existe pas (31 janvier + 1 mois → 28/29 février) — là où
/// `Date.setMonth` du web déborderait sur le mois suivant (3 mars).
DateTime ajouterMois(DateTime debut, int mois) {
  final cible = DateTime(debut.year, debut.month + mois);
  final dernierJour = DateTime(cible.year, cible.month + 1, 0).day;
  final jour = debut.day > dernierJour ? dernierJour : debut.day;
  return DateTime(cible.year, cible.month, jour);
}

/// `date_fin` envoyée au serveur : [dateDebut] + [dureeMois] mois. Le
/// serveur ne la déduit pas de `duree_contrat` (colonnes indépendantes).
DateTime calculerDateFinBail(DateTime dateDebut, int dureeMois) =>
    ajouterMois(dateDebut, dureeMois);

/// Équivalent FCFA d'une avance saisie en mois — **purement informatif,
/// pour l'affichage**. Le serveur reçoit `avance` en nombre de mois (comme
/// le web) ; ce montant n'est jamais envoyé.
double convertirAvanceEnFcfa({
  required int avanceMois,
  required double loyerMensuel,
}) => avanceMois * loyerMensuel;

/// « 370 000 FCFA ».
String formatFcfa(double value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${rounded < 0 ? '-' : ''}$buffer FCFA';
}

/// « 2 mois = 370 000 FCFA » — aide visuelle affichée à l'écran et au
/// récapitulatif, purement informative : ne décrit pas ce qui est envoyé au
/// serveur (qui reçoit le nombre de mois brut).
String libelleAvance({required int avanceMois, required double loyerMensuel}) =>
    '$avanceMois mois = '
    '${formatFcfa(convertirAvanceEnFcfa(avanceMois: avanceMois, loyerMensuel: loyerMensuel))}';

// ── Validation (messages affichés tels quels) ─────────────────────────────

/// `duree_contrat` : `isInt({ min: 1 })` côté serveur.
String? validerDureeBail(int? mois) {
  if (mois == null || mois < 1) return 'Indiquez une durée d’au moins 1 mois.';
  if (mois > 1200) return 'Durée trop longue.';
  return null;
}

/// Le serveur refuse une location sans loyer (`!loyer_mensuel` → 400, donc
/// 0 compris).
String? validerLoyerBail(double? montant) {
  if (montant == null || montant <= 0) {
    return 'Indiquez un loyer supérieur à 0.';
  }
  return null;
}

/// Caution, charges : `isFloat({ min: 0 })` côté serveur.
String? validerMontantPositifOuNul(double? montant) {
  if (montant == null || montant < 0) return 'Indiquez un montant (0 accepté).';
  return null;
}

String? validerAvanceMois(int? mois) {
  if (mois == null || mois < 0) return 'Indiquez un nombre de mois (0 accepté).';
  if (mois > 120) return 'Nombre de mois trop élevé.';
  return null;
}

/// `jour_echeance` : `isInt({ min: 1, max: 31 })` côté serveur.
String? validerJourEcheance(int? jour) {
  if (jour == null || jour < 1 || jour > 31) {
    return 'Indiquez un jour entre 1 et 31.';
  }
  return null;
}

String? validerConditionsParticulieres(String texte) {
  if (texte.length > conditionsParticulieresMaxLength) {
    return 'Maximum $conditionsParticulieresMaxLength caractères.';
  }
  return null;
}

/// Bail renvoyé par `POST /api/locations` (201) : la ligne `leases` brute,
/// loyer nommé `loyer_actuel`, `reference_bail` au format
/// `BAIL-AAAA-000id`.
class BailCree {
  const BailCree({
    required this.id,
    this.referenceBail,
    this.loyerActuel,
    this.dateDebut,
    this.dateFin,
    this.statut,
  });

  /// `null` si `id` est absent ou inexploitable.
  static BailCree? tryFromJson(Map<String, dynamic> json) {
    final id = _asIntOrNull(json['id']);
    if (id == null) return null;
    return BailCree(
      id: id,
      referenceBail: json['reference_bail'] is String
          ? json['reference_bail'] as String
          : null,
      loyerActuel: _asDoubleOrNull(json['loyer_actuel']),
      dateDebut: json['date_debut'] is String ? json['date_debut'] as String : null,
      dateFin: json['date_fin'] is String ? json['date_fin'] as String : null,
      statut: json['statut'] is String ? json['statut'] as String : null,
    );
  }

  final int id;
  final String? referenceBail;
  final double? loyerActuel;
  final String? dateDebut;
  final String? dateFin;
  final String? statut;
}

int? _asIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
