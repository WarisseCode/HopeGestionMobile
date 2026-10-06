import '../../finances/models/echeance.dart';
import '../../finances/models/finance_parsing.dart';

/// Fiche d'un bail en lecture seule — réponse de `GET /api/locations/:id`
/// (HopeGestionV2 `backend/routes/leaseRoutes.ts`) : `{location, echeancier}`.
///
/// Modèle dédié plutôt qu'une extension de `BailCree` : `BailCree` décrit la
/// ligne brute renvoyée à la création (6 champs, `tryFromJson` tolérant),
/// alors que la fiche agrège une vingtaine de champs dont les jointures
/// locataire/lot/immeuble/propriétaire. Les fusionner aurait imposé des
/// champs optionnels sans objet à la création.
///
/// `echeancier` est déjà filtré par propriétaire côté serveur
/// (`scopeByOwner`) et réutilise tel quel [Echeance.fromJson]. La route
/// `GET /:id/echeancier` (sans `scopeByOwner`) n'est jamais utilisée ici.
class BailDetail {
  const BailDetail({
    required this.id,
    required this.statut,
    this.referenceBail,
    this.typePaiement,
    this.loyerMensuel,
    this.chargesMensuelles,
    this.caution,
    this.avanceMois,
    this.jourEcheance,
    this.dateDebut,
    this.dateFin,
    this.locataireNom,
    this.locatairePrenoms,
    this.locataireTelephone,
    this.locataireEmail,
    this.refLot,
    this.lotType,
    this.immeubleNom,
    this.immeubleAdresse,
    this.proprietaireNom,
    this.echeancier = const [],
  });

  /// [location] = objet `location` de la réponse, [echeancier] = tableau
  /// `echeancier`. `id` indispensable → `FormatException` ; une échéance
  /// malformée aussi (même politique que `FinancesRepository.listEcheances`).
  factory BailDetail.fromJson(
    Map<String, dynamic> location,
    List<dynamic> echeancier,
  ) {
    final id = asIntOrNull(location['id']);
    if (id == null) {
      throw const FormatException('Bail au format inattendu (id manquant).');
    }
    final echeances =
        echeancier
            .whereType<Map<String, dynamic>>()
            .map(Echeance.fromJson)
            .toList()
          ..sort(_parDateEcheance);
    return BailDetail(
      id: id,
      statut: _texte(location['statut']) ?? '',
      referenceBail: _texte(location['reference_bail']),
      typePaiement: _texte(location['type_paiement']),
      // `loyer_actuel` aliasé `loyer_mensuel` par la route ; repli sur la
      // colonne brute si l'alias venait à manquer.
      loyerMensuel:
          asDoubleOrNull(location['loyer_mensuel']) ??
          asDoubleOrNull(location['loyer_actuel']),
      chargesMensuelles: asDoubleOrNull(location['charges_mensuelles']),
      caution: asDoubleOrNull(location['caution']),
      // `avance` stockée en nombre de mois (T-059) ; NUMERIC possible
      // (« 2.00 ») d'où le passage par un double.
      avanceMois: asDoubleOrNull(location['avance'])?.round(),
      jourEcheance: asIntOrNull(location['jour_echeance']),
      dateDebut: asDateOrNull(location['date_debut']),
      dateFin: asDateOrNull(location['date_fin']),
      locataireNom: _texte(location['locataire_nom']),
      locatairePrenoms: _texte(location['locataire_prenoms']),
      locataireTelephone: _texte(location['locataire_telephone']),
      locataireEmail: _texte(location['locataire_email']),
      refLot: _texte(location['ref_lot']),
      lotType: _texte(location['lot_type']),
      immeubleNom: _texte(location['immeuble_nom']),
      immeubleAdresse: _texte(location['immeuble_adresse']),
      proprietaireNom: _texte(location['proprietaire_nom']),
      echeancier: echeances,
    );
  }

  final int id;
  final String statut;
  final String? referenceBail;
  final String? typePaiement;
  final double? loyerMensuel;
  final double? chargesMensuelles;
  final double? caution;

  /// Nombre de mois d'avance (pas un montant FCFA).
  final int? avanceMois;
  final int? jourEcheance;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? locataireNom;
  final String? locatairePrenoms;
  final String? locataireTelephone;
  final String? locataireEmail;
  final String? refLot;
  final String? lotType;
  final String? immeubleNom;
  final String? immeubleAdresse;
  final String? proprietaireNom;

  /// Trié par date d'échéance croissante (sans date en dernier, puis id).
  final List<Echeance> echeancier;

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

int _parDateEcheance(Echeance a, Echeance b) {
  final da = a.dateEcheance;
  final db = b.dateEcheance;
  if (da == null && db == null) return a.id.compareTo(b.id);
  if (da == null) return 1;
  if (db == null) return -1;
  final parDate = da.compareTo(db);
  // `List.sort` n'est pas stable : départage déterministe par id.
  return parDate != 0 ? parDate : a.id.compareTo(b.id);
}
