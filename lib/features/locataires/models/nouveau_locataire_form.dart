/// Objet mutable accumulant les données du formulaire "Nouveau locataire"
/// à travers les 4 étapes.
class NouveauLocataireForm {
  // Étape 1 — Identité
  String proprietaire = '';
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
  String dateExpiration = '';

  // Étape 3 — Finances (facultatif)
  String modePaiement = 'Mobile Money';
  bool paiementEchelonne = false;

  // Étape 4 — Statut final
  String statut = 'Actif — Profil opérationnel';

  // Constantes
  static const List<String> typesProfile = [
    'Locataire',
    'Acheteur',
    'Prospect',
  ];

  static const List<String> proprietaires = [
    'Mamadou Camara',
    'Aïcha Sarr',
    'Jean-Pierre Kouassi',
    'Fatou Mbaye',
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

  static const List<String> statuts = [
    'Actif — Profil opérationnel',
    'En attente de validation',
    'Suspendu',
    'Archivé',
  ];

  /// Valide l'étape 1 (champs requis : propriétaire, nom, prénom)
  bool isStep1Valid() =>
      proprietaire.isNotEmpty &&
      nom.trim().isNotEmpty &&
      prenom.trim().isNotEmpty;

  /// Nom complet affiché sur l'écran de confirmation
  String get nomComplet => '${nom.toUpperCase()} $prenom';

  /// Initiales pour l'avatar
  String get initials {
    final n = nom.isNotEmpty ? nom[0] : '';
    final p = prenom.isNotEmpty ? prenom[0] : '';
    return '$n$p'.toUpperCase();
  }
}
