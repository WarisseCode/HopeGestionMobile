/// Locataire réel, tel que renvoyé par `GET /api/locataires` (liste, avec
/// agrégats de bail) et `GET /api/locataires/:id` (détail, sans agrégats —
/// voir [TenantLease]/[TenantPayment] pour les baux/paiements associés,
/// renvoyés séparément par cette dernière route).
///
/// `HopeGestionV2/backend/routes/locataireRoutes.ts`.
class Locataire {
  const Locataire({
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.telephonePrincipal,
    required this.type,
    required this.statut,
    this.email,
    this.telephoneSecondaire,
    this.nationalite,
    this.typePiece,
    this.numeroPiece,
    this.dateExpirationPiece,
    this.adresseActuelle,
    this.modePaiementPreferentiel,
    this.paiementEchelonne = false,
    this.photoProfilUrl,
    this.photoPieceUrl,
    this.ownerId,
    this.activeLeases,
    this.loyerTotal,
    this.lotNom,
    this.loyerActuel,
    this.paymentStatus,
  });

  /// Extraction défensive, même politique que `AppUser.fromJson` : les
  /// champs indispensables lèvent une [FormatException] plutôt qu'une
  /// `TypeError`, les champs optionnels sont simplement ignorés s'ils sont
  /// absents ou d'un type inattendu.
  factory Locataire.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nom = json['nom'];
    final telephonePrincipal = json['telephone_principal'];
    if (id is! int || nom is! String || telephonePrincipal is! String) {
      throw const FormatException(
        'Locataire au format inattendu (id, nom ou telephone_principal manquant).',
      );
    }

    return Locataire(
      id: id,
      nom: nom,
      prenoms: (json['prenoms'] as String?) ?? '',
      telephonePrincipal: telephonePrincipal,
      type: (json['type'] as String?) ?? 'Locataire',
      statut: (json['statut'] as String?) ?? 'Actif',
      email: json['email'] as String?,
      telephoneSecondaire: json['telephone_secondaire'] as String?,
      nationalite: json['nationalite'] as String?,
      typePiece: json['type_piece'] as String?,
      numeroPiece: json['numero_piece'] as String?,
      dateExpirationPiece: json['date_expiration_piece'] as String?,
      adresseActuelle: json['adresse_actuelle'] as String?,
      modePaiementPreferentiel: json['mode_paiement_preferentiel'] as String?,
      paiementEchelonne: json['paiement_echelonne'] as bool? ?? false,
      photoProfilUrl: json['photo_profil_url'] as String?,
      photoPieceUrl: json['photo_piece_url'] as String?,
      ownerId: _asIntOrNull(json['owner_id']),
      activeLeases: _asIntOrNull(json['active_leases']),
      loyerTotal: _asDoubleOrNull(json['loyer_total']),
      lotNom: json['lot_nom'] as String?,
      loyerActuel: _asDoubleOrNull(json['loyer_actuel']),
      paymentStatus: json['payment_status'] as String?,
    );
  }

  final int id;
  final String nom;
  final String prenoms;
  final String telephonePrincipal;

  /// "Locataire" / "Acheteur" / "Prospect" — texte libre côté backend.
  final String type;

  /// Valeurs réellement observées dans `locataireRoutes.ts` : "Actif"
  /// (défaut à la création, forcé côté serveur — voir `LocatairesRepository
  /// .create`), "Rejeté" (`POST /:id/reject`), "Archivé" (exclu de `GET /`),
  /// "Nouveau" (auto-inscription via code d'invitation, `AuthService
  /// .completeProfile`, hors périmètre de cette phase — voir journal).
  final String statut;

  final String? email;
  final String? telephoneSecondaire;
  final String? nationalite;
  final String? typePiece;
  final String? numeroPiece;
  final String? dateExpirationPiece;
  final String? adresseActuelle;
  final String? modePaiementPreferentiel;
  final bool paiementEchelonne;
  final String? photoProfilUrl;
  final String? photoPieceUrl;
  final int? ownerId;

  // Agrégats présents uniquement dans les lignes de `GET /` (liste) — `null`
  // dans le détail renvoyé par `GET /:id`.
  final int? activeLeases;
  final double? loyerTotal;
  final String? lotNom;
  final double? loyerActuel;

  /// "unknown" / "pending" / "late" / "paid" — calculé côté backend.
  final String? paymentStatus;

  String get displayName =>
      [prenoms, nom].where((part) => part.trim().isNotEmpty).join(' ');

  String get initials {
    final p = prenoms.trim().isNotEmpty ? prenoms.trim()[0] : '';
    final n = nom.trim().isNotEmpty ? nom.trim()[0] : '';
    final result = '$p$n'.toUpperCase();
    return result.isEmpty ? '?' : result;
  }
}

/// Bail associé à un locataire, tel que renvoyé dans `baux` par
/// `GET /api/locataires/:id`.
class TenantLease {
  const TenantLease({
    required this.id,
    required this.statut,
    this.buildingName,
    this.refLot,
    this.loyerActuel,
    this.dateDebut,
    this.dateFin,
    this.paymentStatus,
  });

  factory TenantLease.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Bail au format inattendu (id manquant).');
    }
    return TenantLease(
      id: id,
      statut: (json['statut'] as String?) ?? '',
      buildingName: json['building_name'] as String?,
      refLot: json['ref_lot'] as String?,
      loyerActuel: _asDoubleOrNull(json['loyer_actuel']),
      dateDebut: json['date_debut'] as String?,
      dateFin: json['date_fin'] as String?,
      paymentStatus: json['payment_status'] as String?,
    );
  }

  final int id;
  final String statut;
  final String? buildingName;
  final String? refLot;
  final double? loyerActuel;
  final String? dateDebut;
  final String? dateFin;
  final String? paymentStatus;
}

/// Paiement associé à un locataire, tel que renvoyé dans `paiements` par
/// `GET /api/locataires/:id`.
class TenantPayment {
  const TenantPayment({
    required this.id,
    required this.montant,
    this.type,
    this.modePaiement,
    this.datePaiement,
  });

  factory TenantPayment.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException(
        'Paiement au format inattendu (id manquant).',
      );
    }
    return TenantPayment(
      id: id,
      montant: _asDoubleOrNull(json['montant']) ?? 0,
      type: json['type'] as String?,
      modePaiement: json['mode_paiement'] as String?,
      datePaiement: json['date_paiement'] as String?,
    );
  }

  final int id;
  final double montant;
  final String? type;
  final String? modePaiement;
  final String? datePaiement;
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
