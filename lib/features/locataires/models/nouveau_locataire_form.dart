/// Objet mutable accumulant les données du formulaire "Nouveau locataire"
/// à travers les 4 étapes.
class NouveauLocataireForm {
  // Étape 1 — Identité
  int? ownerId;

  /// Nom d'affichage du propriétaire sélectionné (étape 4) — résolu depuis
  /// la liste réelle chargée par l'écran, pas une valeur inventée.
  String ownerName = '';

  /// `true` quand l'utilisateur gère plusieurs propriétaires (donc
  /// `owner_id` obligatoire — voir `tenantGuard.ts`), fixé une fois par
  /// `NouveauLocataireScreen` après le chargement de `GET /owners`, avant
  /// toute validation de l'étape 1.
  bool ownerSelectionRequired = false;

  String nom = '';
  String prenom = '';
  String typeProfile = 'Locataire'; // Locataire / Acheteur / Prospect
  String nationalite = '';
  String telephone = '';
  String email = '';
  String adresse = '';

  // Étape 2 — Documents (facultatif)
  String typeId = 'Carte Nationale d\'Identité (CNI)';
  String numeroId = '';

  /// Stockée en `DateTime` (pas en `String` déjà formatée) pour ne fixer le
  /// format d'envoi (`AAAA-MM-JJ`, voir `NouveauLocataireScreen._submit`)
  /// qu'au moment de la requête — l'affichage (`JJ/MM/AAAA`) est un problème
  /// d'UI distinct, géré par `LocataireStep2Documents`.
  DateTime? dateExpiration;

  // Étape 3 — Finances (facultatif)
  String modePaiement = 'Mobile Money';
  bool paiementEchelonne = false;

  // Constantes
  static const List<String> typesProfile = [
    'Locataire',
    'Acheteur',
    'Prospect',
  ];

  static const List<String> typesId = [
    'Carte Nationale d\'Identité (CNI)',
    'Passeport',
    'Permis de conduire',
    'Titre de séjour',
  ];

  static const List<String> modesPaiement = [
    'Mobile Money',
    'Espèces',
    'Virement',
    'Chèque',
  ];

  /// Valide l'étape 1 (nom, prénom, téléphone — champs réellement exigés par
  /// `POST /api/locataires` ; propriétaire requis seulement si plusieurs
  /// sont gérés par l'utilisateur, voir [ownerSelectionRequired]).
  bool isStep1Valid() =>
      nom.trim().isNotEmpty &&
      prenom.trim().isNotEmpty &&
      telephone.trim().isNotEmpty &&
      (!ownerSelectionRequired || ownerId != null);

  /// Nom complet affiché sur l'écran de confirmation
  String get nomComplet => '${nom.toUpperCase()} $prenom';

  /// Initiales pour l'avatar
  String get initials {
    final n = nom.isNotEmpty ? nom[0] : '';
    final p = prenom.isNotEmpty ? prenom[0] : '';
    return '$n$p'.toUpperCase();
  }
}
