import '../../finances/models/finance_parsing.dart';

/// Résumé d'un bail tel que renvoyé par la liste `GET /api/locations`
/// (HopeGestionV2 `backend/routes/leaseRoutes.ts`, réponse `{locations}`,
/// déjà jointe au locataire et au lot, filtrée par propriétaire côté
/// serveur).
///
/// Modèle léger distinct de `BailDetail` : la liste ne porte ni
/// l'échéancier ni toutes les colonnes de la fiche, et seuls les champs
/// utiles à la carte « Occupant actuel » d'un lot sont retenus.
class BailResume {
  const BailResume({
    required this.id,
    required this.statut,
    this.lotId,
    this.referenceBail,
    this.tenantId,
    this.locataireNom,
    this.locatairePrenoms,
    this.locataireTelephone,
    this.locatairePhoto,
    this.dateDebut,
    this.dateFin,
    this.loyerMensuel,
  });

  /// `null` si `id` est absent ou illisible : la ligne est alors ignorée
  /// plutôt que de faire échouer toute la liste.
  static BailResume? tryFromJson(Map<String, dynamic> json) {
    final id = asIntOrNull(json['id']);
    if (id == null) return null;
    return BailResume(
      id: id,
      statut: _texte(json['statut']) ?? '',
      lotId: asIntOrNull(json['lot_id']),
      referenceBail: _texte(json['reference_bail']),
      tenantId: asIntOrNull(json['tenant_id']),
      locataireNom: _texte(json['locataire_nom']),
      locatairePrenoms: _texte(json['locataire_prenoms']),
      locataireTelephone: _texte(json['locataire_telephone']),
      locatairePhoto: _texte(json['locataire_photo']),
      dateDebut: asDateOrNull(json['date_debut']),
      dateFin: asDateOrNull(json['date_fin']),
      // Même repli que `BailDetail` si l'alias venait à manquer.
      loyerMensuel:
          asDoubleOrNull(json['loyer_mensuel']) ??
          asDoubleOrNull(json['loyer_actuel']),
    );
  }

  final int id;
  final String statut;
  final int? lotId;
  final String? referenceBail;
  final int? tenantId;
  final String? locataireNom;
  final String? locatairePrenoms;
  final String? locataireTelephone;
  final String? locatairePhoto;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double? loyerMensuel;

  /// « Nom Prénoms », `null` si aucun des deux n'est renseigné.
  String? get locataireNomComplet {
    final nom = [
      locataireNom,
      locatairePrenoms,
    ].whereType<String>().join(' ').trim();
    return nom.isEmpty ? null : nom;
  }
}

String? _texte(dynamic value) {
  if (value is! String) return null;
  final t = value.trim();
  return t.isEmpty ? null : t;
}
