/// Objet mutable accumulant les données du formulaire "Nouveau bien"
/// à travers les 4 étapes.
class NouveauBienForm {
  // Étape 1 — Identité
  String nom = '';
  String type = 'Immeuble collectif';
  int nbEtages = 0;
  int nbLots = 0;
  String description = '';

  // Étape 2 — Localisation
  String adresse = '';
  String quartier = '';
  String ville = '';
  String pays = 'Bénin';
  String latitude = '';
  String longitude = '';

  // Étape 3 — Gestion
  String proprietaire = '';
  String gestionnaire = 'Warisse OTCHADE';

  // Étape 4 — Médias
  String videoUrl = '';
  String planUrl = '';
  String etat = 'Actif — Bien opérationnel';

  // Constantes
  static const List<String> typesBien = [
    'Immeuble collectif',
    'Maison individuelle',
    'Villa',
    'Local commercial',
    'Terrain',
    'Appartement',
  ];

  static const List<String> pays_ = [
    'Bénin',
    'Sénégal',
    'Togo',
    'Côte d\'Ivoire',
    'Cameroun',
    'Mali',
    'Burkina Faso',
  ];

  static const List<String> proprietaires = [
    'Mamadou Camara',
    'Aïcha Sarr',
    'Jean-Pierre Kouassi',
    'Fatou Mbaye',
  ];

  static const List<String> gestionnaires = [
    'Warisse OTCHADE',
    'Géré directement par le propriétaire',
  ];

  static const List<String> etats = [
    'Actif — Bien opérationnel',
    'En travaux',
    'Suspendu',
    'Archivé',
  ];

  /// Valide l'étape 1 (champs requis : nom, nbLots)
  bool isStep1Valid() => nom.trim().isNotEmpty && nbLots > 0;

  /// Valide l'étape 2 (champs requis : ville)
  bool isStep2Valid() => ville.trim().isNotEmpty;

  /// Valide l'étape 3 (champs requis : propriétaire)
  bool isStep3Valid() => proprietaire.trim().isNotEmpty;
}
