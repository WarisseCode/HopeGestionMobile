import '../../finances/models/finance_parsing.dart';

/// Catégorie d'un document de la table `documents` (colonne `categorie`,
/// texte libre côté serveur, sans contrainte SQL).
///
/// Valeurs écrites par le code (journal T-047) : `autre` (défaut de
/// `POST /documents/upload`), `baux` (contrat généré), `generated` (document
/// généré depuis un modèle), et celles proposées par le web : `quittances`,
/// `identite`, `facture`, `proprietaire` (pièces d'un propriétaire). Toute
/// autre valeur — y compris une valeur ancienne en base — retombe sur
/// [autre], jamais d'exception.
enum CategorieDocument {
  bail('Baux', 'Bail'),
  quittance('Quittances', 'Quittance'),
  facture('Factures', 'Facture'),
  identite('Identité', "Pièce d'identité"),
  proprietaire('Propriétaires', 'Document propriétaire'),
  genere('Générés', 'Document généré'),
  autre('Autres', 'Autre');

  const CategorieDocument(this.libellePluriel, this.libelle);

  /// Libellé d'une puce de filtre (« Baux (3) »).
  final String libellePluriel;

  /// Libellé d'un document seul (fiche).
  final String libelle;

  static CategorieDocument depuisCode(String? code) {
    switch (code?.trim().toLowerCase()) {
      case 'baux':
      case 'bail':
        return CategorieDocument.bail;
      case 'quittances':
      case 'quittance':
        return CategorieDocument.quittance;
      case 'facture':
      case 'factures':
        return CategorieDocument.facture;
      case 'identite':
      case 'identité':
        return CategorieDocument.identite;
      case 'proprietaire':
      case 'propriétaire':
        return CategorieDocument.proprietaire;
      case 'generated':
        return CategorieDocument.genere;
    }
    return CategorieDocument.autre;
  }
}

/// Une ligne de `GET /api/documents` (`SELECT * FROM documents`) : fichier
/// déposé (`POST /documents/upload`) ou généré (`/documents/generate*`).
class Document {
  const Document({
    required this.id,
    required this.nom,
    required this.categorie,
    this.categorieBrute,
    this.typeMime,
    this.url,
    this.tailleOctets,
    this.entityType,
    this.entityId,
    this.description,
    this.createdAt,
  });

  final int id;
  final String nom;
  final CategorieDocument categorie;

  /// Valeur reçue telle quelle (utile quand [categorie] vaut [CategorieDocument.autre]).
  final String? categorieBrute;

  /// Colonne `type` : type MIME (`application/pdf`, `image/jpeg`…).
  final String? typeMime;

  /// Chemin relatif (`/uploads/...`) ou URL absolue (Spaces) ; à résoudre
  /// avec `AppConfig.resolveFileUrl`.
  final String? url;

  /// Colonne `taille` : nombre d'octets, stocké **en chaîne** par le serveur.
  final int? tailleOctets;

  final String? entityType;
  final int? entityId;
  final String? description;
  final DateTime? createdAt;

  /// `null` si la ligne n'a pas d'identifiant exploitable (ligne ignorée).
  static Document? tryFromJson(Map<String, dynamic> json) {
    final id = asIntOrNull(json['id']);
    if (id == null) return null;
    final categorieBrute = _texte(json['categorie']);
    final description = _texte(json['description']);
    return Document(
      id: id,
      nom: _texte(json['nom']) ?? description ?? 'Document n° $id',
      categorie: CategorieDocument.depuisCode(categorieBrute),
      categorieBrute: categorieBrute,
      typeMime: _texte(json['type']),
      url: _texte(json['url']),
      tailleOctets: asIntOrNull(json['taille']),
      entityType: _texte(json['entity_type']),
      entityId: asIntOrNull(json['entity_id']),
      description: description,
      createdAt: asDateTimeOrNull(json['created_at']),
    );
  }

  /// « Bail n° 42 », « Propriétaire n° 3 »… ; `null` sans entité liée.
  String? get entiteLiee {
    final type = entityType;
    if (type == null) return null;
    final libelle = switch (type.toLowerCase()) {
      'lease' => 'Bail',
      'owner' => 'Propriétaire',
      'tenant' || 'locataire' => 'Locataire',
      'lot' => 'Lot',
      'building' || 'immeuble' => 'Immeuble',
      _ => type,
    };
    return entityId == null ? libelle : '$libelle n° $entityId';
  }
}

/// Une ligne de `GET /api/quittances` (table `manual_quittances`).
///
/// **Pas de fichier serveur** : le web génère le PDF d'une quittance
/// manuelle côté navigateur (`generateQuittancePDF`, `pdfGenerator.ts`) à
/// partir de ces données ; aucune colonne d'URL n'existe. Le mobile affiche
/// donc ses données, sans bouton « Ouvrir ».
class QuittanceManuelle {
  const QuittanceManuelle({
    required this.id,
    this.numero,
    this.locataireNom,
    this.proprietaireNom,
    this.bien,
    this.periode,
    this.montant,
    this.dateEmission,
    this.createdAt,
  });

  final int id;
  final String? numero;
  final String? locataireNom;
  final String? proprietaireNom;
  final String? bien;
  final String? periode;
  final double? montant;
  final DateTime? dateEmission;
  final DateTime? createdAt;

  static QuittanceManuelle? tryFromJson(Map<String, dynamic> json) {
    final id = asIntOrNull(json['id']);
    if (id == null) return null;
    return QuittanceManuelle(
      id: id,
      numero: _texte(json['numero']),
      locataireNom: _texte(json['locataire_name']),
      proprietaireNom: _texte(json['proprietaire_name']),
      bien: _texte(json['bien']),
      periode: _texte(json['periode']),
      montant: asDoubleOrNull(json['montant']),
      dateEmission: asDateOrNull(json['date_emission']),
      createdAt: asDateTimeOrNull(json['created_at']),
    );
  }
}

String? _texte(dynamic value) {
  if (value is! String) return null;
  final t = value.trim();
  return t.isEmpty ? null : t;
}
