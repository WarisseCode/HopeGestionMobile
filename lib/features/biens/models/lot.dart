/// Lot réel, tel que renvoyé par `GET /api/biens/lots`
/// (`HopeGestionV2/backend/routes/bienRoutes.ts`). Toujours rattaché à un
/// [Immeuble] (`buildingId`) — la route `POST /api/biens/lots` refuse la
/// création si l'immeuble n'est pas résolu (400), pas de lot indépendant.
class Lot {
  const Lot({
    required this.id,
    required this.reference,
    this.type,
    this.buildingId,
    this.immeubleNom,
    this.ownerId,
    this.ownerName,
    this.etage,
    this.bloc,
    this.superficie,
    this.nbPieces,
    this.loyer,
    this.charges,
    this.periodicite,
    this.caution,
    this.avance = 1,
    this.prixVente,
    this.modaliteVente,
    this.dureeEchelonnement,
    this.photos = const [],
    this.statut = 'disponible',
    this.dateDisponibilite,
    this.description,
  });

  factory Lot.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final reference = json['reference'];
    if (id is! int || reference is! String) {
      throw const FormatException(
        'Lot au format inattendu (id ou reference manquant).',
      );
    }

    return Lot(
      id: id,
      reference: reference,
      type: json['type'] as String?,
      buildingId: _asIntOrNull(json['building_id']),
      immeubleNom: json['immeuble'] as String?,
      ownerId: _asIntOrNull(json['owner_id']),
      ownerName: json['owner_name'] as String?,
      // Type de colonne non confirmé en base ('RDC', '1er étage'... vus côté
      // web) : traité comme texte libre, jamais un entier.
      etage: _asStringOrNull(json['etage']),
      bloc: _asStringOrNull(json['bloc']),
      superficie: _asDoubleOrNull(json['superficie']),
      nbPieces: _asIntOrNull(json['nbPieces']),
      loyer: _asDoubleOrNull(json['loyer']),
      charges: _asDoubleOrNull(json['charges']),
      periodicite: json['periodicite'] as String?,
      caution: _asDoubleOrNull(json['caution']),
      avance: _asIntOrNull(json['avance']) ?? 1,
      prixVente: _asDoubleOrNull(json['prix_vente']),
      modaliteVente: json['modalite_vente'] as String?,
      dureeEchelonnement: _asIntOrNull(json['duree_echelonnement']),
      photos: _asStringList(json['photos']),
      statut: (json['statut'] as String?) ?? 'disponible',
      dateDisponibilite: json['date_disponibilite'] as String?,
      description: json['description'] as String?,
    );
  }

  final int id;
  final String reference;
  final String? type;
  final int? buildingId;
  final String? immeubleNom;
  final int? ownerId;
  final String? ownerName;
  final String? etage;
  final String? bloc;
  final double? superficie;
  final int? nbPieces;
  final double? loyer;
  final double? charges;
  final String? periodicite;
  final double? caution;
  final int avance;
  final double? prixVente;
  final String? modaliteVente;
  final int? dureeEchelonnement;
  final List<String> photos;

  /// Valeurs réelles observées côté backend : `'disponible'` / `'occupe'` /
  /// `'reserve'` / `'vendu'` — pas `'travaux'` comme évoqué en phase 1.
  final String statut;

  final String? dateDisponibilite;
  final String? description;
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

String? _asStringOrNull(dynamic value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value is num) return value.toString();
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is List) return value.whereType<String>().toList();
  return const [];
}
