/// Immeuble réel, tel que renvoyé par `GET /api/biens/immeubles`
/// (`HopeGestionV2/backend/routes/bienRoutes.ts`). Entité distincte de
/// [Lot] côté backend (tables `buildings`/`lots` séparées, liées par
/// `building_id`) — contrairement à l'ancien `Bien` mocké qui fusionnait
/// les deux en un seul objet.
class Immeuble {
  const Immeuble({
    required this.id,
    required this.nom,
    this.type,
    this.adresse,
    this.ville,
    this.pays,
    this.quartier,
    this.description,
    this.photo,
    this.photos = const [],
    this.videoUrl,
    this.planMasseUrl,
    this.latitude,
    this.longitude,
    this.nombreEtages,
    this.statut = 'actif',
    this.ownerId,
    this.ownerName,
    this.gestionnaireId,
    this.gestionnaireName,
    this.nbLots = 0,
    this.lotsOccupes = 0,
    this.occupationPercent = 0,
    this.etatOccupation,
  });

  /// Extraction défensive, même politique que `Locataire.fromJson` : champs
  /// indispensables → `FormatException`, champs optionnels ignorés si
  /// absents/mal typés.
  factory Immeuble.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nom = json['nom'];
    if (id is! int || nom is! String) {
      throw const FormatException(
        'Immeuble au format inattendu (id ou nom manquant).',
      );
    }

    return Immeuble(
      id: id,
      nom: nom,
      type: json['type'] as String?,
      adresse: json['adresse'] as String?,
      ville: json['ville'] as String?,
      pays: json['pays'] as String?,
      quartier: json['quartier'] as String?,
      description: json['description'] as String?,
      photo: json['photo'] as String?,
      photos: _asStringList(json['photos']),
      videoUrl: json['video_url'] as String?,
      planMasseUrl: json['plan_masse_url'] as String?,
      latitude: _asDoubleOrNull(json['latitude']),
      longitude: _asDoubleOrNull(json['longitude']),
      nombreEtages: _asIntOrNull(json['nombre_etages']),
      statut: (json['statut'] as String?) ?? 'actif',
      ownerId: _asIntOrNull(json['owner_id']),
      // `proprietaire` : libellé déjà résolu côté serveur (nom + prénom si
      // particulier, raison sociale sinon) — voir `bienRoutes.ts`.
      ownerName: json['proprietaire'] as String?,
      gestionnaireId: _asIntOrNull(json['gestionnaire_id']),
      gestionnaireName: json['gestionnaire_name'] as String?,
      // `nbLots` (calculé serveur : `total_lots` déclaré si non nul, sinon
      // le nombre de lots réellement créés) plutôt que `total_lots` brut,
      // qui peut être 0 si l'utilisateur n'a jamais déclaré de capacité.
      nbLots: _asIntOrNull(json['nbLots']) ?? 0,
      lotsOccupes: _asIntOrNull(json['lotsOccupes']) ?? 0,
      occupationPercent: _asIntOrNull(json['occupation']) ?? 0,
      etatOccupation: json['etatOccupation'] as String?,
    );
  }

  final int id;
  final String nom;
  final String? type;
  final String? adresse;
  final String? ville;
  final String? pays;
  final String? quartier;
  final String? description;

  /// Photo principale (legacy, colonne `photo_url`) — `photos.first` en
  /// pratique côté web, mais renvoyée séparément par le backend.
  final String? photo;
  final List<String> photos;
  final String? videoUrl;
  final String? planMasseUrl;
  final double? latitude;
  final double? longitude;
  final int? nombreEtages;

  /// Valeurs réelles observées côté web (`ImmeubleForm.tsx`) : `'actif'` /
  /// `'inactif'` — pas `'En travaux'`/`'Suspendu'`/`'Archivé'` comme dans
  /// l'ancien formulaire mobile mocké.
  final String statut;

  final int? ownerId;
  final String? ownerName;

  /// `null` = géré directement par le propriétaire (aucun gestionnaire
  /// assigné) — distinct d'un gestionnaire non résolu.
  final int? gestionnaireId;
  final String? gestionnaireName;

  final int nbLots;
  final int lotsOccupes;

  /// 0-100, calculé côté serveur (`lotsOccupes / nbLots`).
  final int occupationPercent;

  /// 'Vide' / 'Disponible' / 'En location' / 'Complet' — calculé côté
  /// serveur à partir de `nbLots`/`lotsOccupes`, pas une colonne `statut`.
  final String? etatOccupation;

  /// `photo` (colonne `photo_url`, la « photo principale ») avec repli sur
  /// la première entrée de `photos` : le web ne renseigne `photo_url` que
  /// dans certains chemins de sauvegarde (`ImmeubleForm.tsx`,
  /// `handlePhotoAdd`) — de nombreux immeubles réels ont `photos` peuplé
  /// mais `photo_url` resté `NULL` en base. Sans ce repli, leur photo
  /// n'apparaît jamais malgré une URL valide et correctement résolue.
  String? get mainPhoto => photo ?? (photos.isNotEmpty ? photos.first : null);
}

int? _asIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is List) return value.whereType<String>().toList();
  return const [];
}
