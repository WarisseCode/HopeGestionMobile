/// Objet mutable accumulant les données du formulaire "Nouvel immeuble" à
/// travers ses 3 étapes. Réduit aux champs réels de `buildings`
/// (`bienRoutes.ts`) — contrairement à l'ancien `NouveauBienForm`, ne mélange
/// plus des champs de lot (prix, statut occupé) avec l'immeuble.
class NouveauImmeubleForm {
  // Étape 1 — Identité
  String nom = '';
  String type = 'Immeuble';
  int nombreEtages = 0;

  /// Capacité **prévue** (colonne `total_lots`) — n'importe quel nombre de
  /// lots réellement créés (voir `BiensRepository.createLot`) reste
  /// indépendant de cette valeur informative. `null` = non renseignée.
  int? totalLots;
  String description = '';

  /// URLs déjà hébergées (retour de `POST /api/upload`, voir
  /// `PhotoUploadRepository`) — jamais des fichiers locaux : l'upload a
  /// lieu immédiatement à la sélection (voir `ImmeubleStep1Identite`), pas
  /// à la soumission finale du formulaire. La première photo de la liste
  /// devient `photo` (photo principale) à l'envoi de `createImmeuble()`.
  List<String> photoUrls = [];

  // Étape 2 — Localisation
  String adresse = '';
  String quartier = '';
  String ville = '';
  String pays = 'Bénin';
  double? latitude;
  double? longitude;

  // Étape 3 — Propriétaire
  int? ownerId;

  /// Nom d'affichage du propriétaire sélectionné, résolu depuis la liste
  /// réelle chargée par l'écran (même pattern que
  /// `NouveauLocataireForm.ownerName`).
  String ownerName = '';

  /// `true` quand l'utilisateur gère plusieurs propriétaires (`owner_id`
  /// alors obligatoire — voir `tenantGuard.ts`, même mécanisme que pour un
  /// locataire).
  bool ownerSelectionRequired = false;

  static const List<String> typesImmeuble = [
    'Immeuble',
    'Maison',
    'Résidence',
    'Commerce',
    'Villa',
  ];

  static const List<String> paysListe = [
    'Bénin',
    'Togo',
    "Côte d'Ivoire",
    'Sénégal',
    'Mali',
    'Burkina Faso',
    'Niger',
    'Ghana',
    'Nigéria',
    'Cameroun',
    'Gabon',
    'Congo',
    'France',
    'Autre',
  ];

  bool isStep1Valid() => nom.trim().isNotEmpty;

  /// `adresse` est bien `NOT NULL` sur `buildings` (`db/init.sql`), mais la
  /// contrainte n'exige qu'une valeur non NULL, pas une chaîne non vide —
  /// `BiensRepository.createImmeuble()` envoie toujours `adresse` (même
  /// vide `''`), qui satisfait la contrainte. Pas de blocage ici, aligné
  /// sur le web (`ImmeubleForm.tsx`), qui ne rend jamais ce champ
  /// obligatoire à l'écran non plus (correctif sur T-032, qui avait
  /// introduit ce blocage par erreur de conception).
  bool isStep2Valid() => ville.trim().isNotEmpty;

  bool isStep3Valid() => !ownerSelectionRequired || ownerId != null;
}
